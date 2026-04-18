import Foundation
import SwiftUI

@MainActor
final class ContentCurationManager: ObservableObject {
    static let shared = ContentCurationManager()

    // MARK: - Published State

    @Published private(set) var curatedTracks: [Track] = []
    @Published private(set) var featuredAlbums: [AlbumCardItem] = []
    @Published private(set) var newReleases: [NewReleaseData] = []
    @Published private(set) var genreArtists: [String: [DeezerArtistBrief]] = [:]
    @Published private(set) var albumGroups: [(title: String, albums: [AlbumCardItem])] = []
    /// Карусель «Downloaded Playlists» (Downloads): метаданные Deezer-плейлистов, не из `featuredAlbums`.
    @Published private(set) var downloadedPlaylistShowcase: [AlbumCardItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    /// Треки карусели «My Vibe» в генераторе; загружаются один раз за сессию приложения.
    @Published private(set) var myVibeGeneratorTracks: [Track] = []

    // MARK: - Loading State

    private var hasLoadedInitial = false
    private var hasLoadedNewReleases = false
    private var hasLoadedRemaining = false
    private var seenAlbumIds = Set<Int>()
    private var myVibeGeneratorLoadTask: Task<Void, Never>?
    private var hasCompletedMyVibeGeneratorLoad = false

    /// Артисты из международных плейлистов Deezer (`DeezerMusicScope.internationalSeedPlaylistIds`), не из локального `genre/.../artists`.
    private var curatedArtistPool: [DeezerArtistBrief] = []
    /// Очередь релизов `(альбом, исполнитель)` до разборки в карточки.
    private var pendingAlbumRefs: [CuratedAlbumRef] = []
    /// Смещение по `curatedArtistPool` при догрузке альбомов.
    private var artistPoolCursor = 0

    /// После первой непустой сборки `albumGroups` для For You не пересобираем — иначе фоновая догрузка дергала бы карусели.
    private var forYouCarouselGroupsFrozenForSession = false

    private struct CuratedAlbumRef {
        let album: DeezerAlbumBrief
        let artist: DeezerArtistBrief
    }

    private let deezer = DeezerService.shared

    private init() {}

    // MARK: - Lazy Loading API

    /// Called on app launch — первый срез альбомов из пула жанров Deezer.
    func loadInitial() async {
        guard !hasLoadedInitial else { return }
        hasLoadedInitial = true
        isLoading = true

        curatedArtistPool = await discoverArtists()
        await refillAlbumQueue(artistsToProcess: 40)
        await loadCuratedAlbumBatch(albumCount: 10)
        await loadDownloadsPlaylistShowcaseIfNeeded()
        isLoading = false
    }

    /// Загружает треки для генератора For You один раз за сессию (повторные заходы на витрину не дергают сеть).
    /// Те же правила, что и карусели: международные плейлисты + фильтр `genre_id` / жанров альбома (`DeezerMusicScope`).
    func loadMyVibeGeneratorTracksIfNeeded() async {
        if hasCompletedMyVibeGeneratorLoad { return }
        if let existing = myVibeGeneratorLoadTask {
            await existing.value
            return
        }
        let task = Task { @MainActor in
            defer { hasCompletedMyVibeGeneratorLoad = true }
            var list: [Track] = []
            list.append(contentsOf: Array(curatedTracks.shuffled().prefix(9)))
            if list.count < 9 {
                let excludedAlbums = Set(curatedTracks.compactMap(\.deezerAlbumId))
                let dz = await collectPlaylistTracksForMyVibe(
                    targetCount: 9 - list.count,
                    excludedAlbumIds: excludedAlbums
                )
                for dt in dz {
                    list.append(trackFromDeezerPlaylistResult(dt))
                }
            }
            guard !list.isEmpty else { return }
            myVibeGeneratorTracks = list.prefix(9).enumerated().map { idx, t in
                renumberTrack(t, id: idx + 1)
            }
        }
        myVibeGeneratorLoadTask = task
        await task.value
        myVibeGeneratorLoadTask = nil
    }

    /// Called when Trends screen appears — loads new releases if not yet loaded.
    func loadNewReleasesIfNeeded() async {
        guard !hasLoadedNewReleases else { return }
        hasLoadedNewReleases = true

        let albumIds = featuredAlbums.shuffled().prefix(12).compactMap(\.deezerAlbumId)
        guard !albumIds.isEmpty else { return }

        let detailedAlbums = await withTaskGroup(of: DeezerAlbum?.self) { group in
            for albumId in albumIds {
                group.addTask { [deezer] in try? await deezer.getAlbum(id: albumId) }
            }
            var results: [DeezerAlbum] = []
            for await album in group {
                if let album { results.append(album) }
            }
            return results
        }

        let withPhoto = detailedAlbums.filter { album in
            guard let pic = album.artist?.pictureXl ?? album.artist?.pictureBig else { return false }
            return !pic.isEmpty
        }
        let sortedByDate = withPhoto.sorted { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }

        self.newReleases = sortedByDate.prefix(6).map { album in
            NewReleaseData(
                albumCover: "album",
                artistName: album.artist?.name ?? "Unknown",
                albumDescription: album.title,
                trackThumbnail: "album",
                trackTitle: album.title,
                trackSubtitle: album.artist?.name ?? "",
                releaseDate: formatDeezerDate(album.releaseDate),
                artistPhoto: "userpic",
                albumCoverURL: url(album.coverXl ?? album.coverBig),
                artistPhotoURL: xlURL(album.artist?.pictureXl ?? album.artist?.pictureBig),
                artistThumbnailURL: url(album.artist?.pictureMedium ?? album.artist?.pictureSmall),
                trackThumbnailURL: url(album.coverBig ?? album.coverMedium),
                deezerAlbumId: album.id
            )
        }

    }

    /// Метаданные плейлистов для вкладки Downloads (параллельные запросы, порядок как в `downloadsShowcasePlaylistIds`).
    private func loadDownloadsPlaylistShowcaseIfNeeded() async {
        guard downloadedPlaylistShowcase.isEmpty else { return }
        let ids = DeezerMusicScope.downloadsShowcasePlaylistIds
        var byId: [Int: DeezerPlaylist] = [:]
        await withTaskGroup(of: (Int, DeezerPlaylist?).self) { group in
            for id in ids {
                group.addTask { [deezer] in
                    let pl = try? await deezer.getPlaylist(id: id)
                    return (id, pl)
                }
            }
            for await (id, pl) in group {
                if let pl { byId[id] = pl }
            }
        }
        let ordered = ids.compactMap { byId[$0] }
        downloadedPlaylistShowcase = ordered.map { pl in
            AlbumCardItem(
                id: "pl-\(pl.id)",
                coverImageName: "album",
                albumTitle: pl.title,
                artistName: pl.creator?.name ?? "Playlist",
                coverImageURL: url(pl.pictureXl ?? pl.pictureBig),
                deezerAlbumId: nil
            )
        }
    }

    /// После первого чанка — догружаем релизы следующих артистов из пула курации.
    func loadRemainingInBackground() async {
        guard !hasLoadedRemaining else { return }
        hasLoadedRemaining = true

        for _ in 0..<25 {
            await refillAlbumQueue(artistsToProcess: 15)
            await loadCuratedAlbumBatch(albumCount: 10)
        }
    }

    // MARK: - Private

    /// Пул артистов из глобальных/US плейлистов (без `search`, без локального `genre/.../artists` по IP).
    private func discoverArtists() async -> [DeezerArtistBrief] {
        var byId: [Int: DeezerArtistBrief] = [:]
        let limit = DeezerMusicScope.playlistTracksPageLimit
        for plId in DeezerMusicScope.internationalSeedPlaylistIds {
            for page in 0..<DeezerMusicScope.playlistTrackPages {
                let index = page * limit
                let tracks = (try? await deezer.getPlaylistTracks(playlistId: plId, limit: limit, index: index)) ?? []
                if tracks.isEmpty { break }
                for t in tracks {
                    if let a = t.artist { byId[a.id] = a }
                }
            }
        }
        return Array(byId.values).shuffled()
    }

    /// Только релизы, у которых в метаданных Deezer `genre_id` входит в наш список родительских жанров.
    private func albumsMatchingScope(_ albums: [DeezerAlbumBrief]) -> [DeezerAlbumBrief] {
        albums.filter { album in
            guard let gid = album.genreId else { return false }
            return DeezerMusicScope.allowedAlbumGenreIds.contains(gid)
        }
    }

    /// Добавляет в очередь релизы выбранных артистов (первая страница дискографии на артиста).
    private func refillAlbumQueue(artistsToProcess: Int) async {
        guard artistPoolCursor < curatedArtistPool.count else { return }
        let end = min(artistPoolCursor + artistsToProcess, curatedArtistPool.count)
        let slice = Array(curatedArtistPool[artistPoolCursor..<end])
        artistPoolCursor = end

        var newRefs: [CuratedAlbumRef] = []
        await withTaskGroup(of: (DeezerArtistBrief, [DeezerAlbumBrief]).self) { group in
            for artist in slice {
                group.addTask { [deezer] in
                    let albums = (try? await deezer.getArtistAlbums(id: artist.id, limit: 25, index: 0)) ?? []
                    return (artist, albums)
                }
            }
            for await (artist, albums) in group {
                let scoped = albumsMatchingScope(albums)
                for al in scoped where !seenAlbumIds.contains(al.id) {
                    newRefs.append(CuratedAlbumRef(album: al, artist: artist))
                }
            }
        }
        pendingAlbumRefs.append(contentsOf: newRefs.shuffled())
    }

    private func loadCuratedAlbumBatch(albumCount: Int) async {
        if pendingAlbumRefs.isEmpty, artistPoolCursor < curatedArtistPool.count {
            await refillAlbumQueue(artistsToProcess: 20)
        }
        guard !pendingAlbumRefs.isEmpty else { return }

        let take = min(albumCount, pendingAlbumRefs.count)
        let chunk = Array(pendingAlbumRefs.prefix(take))
        pendingAlbumRefs.removeFirst(take)

        let albums = chunk.filter { !seenAlbumIds.contains($0.album.id) }
        guard !albums.isEmpty else { return }

        let albumIds = albums.map(\.album.id)

        let trackInfoMap: [Int: (title: String, previewURL: URL?)] = await withTaskGroup(
            of: (Int, (title: String, previewURL: URL?)?).self
        ) { group in
            for albumId in albumIds {
                group.addTask { [deezer] in
                    let tracks = (try? await deezer.getAlbumTracks(id: albumId)) ?? []
                    let withPreview = tracks.filter { $0.preview != nil && !($0.preview ?? "").isEmpty }
                    let picked = withPreview.randomElement() ?? tracks.randomElement()
                    guard let picked else { return (albumId, nil) }
                    let previewURL = picked.preview.flatMap { URL(string: $0) }
                    return (albumId, (title: picked.title, previewURL: previewURL))
                }
            }
            var map: [Int: (title: String, previewURL: URL?)] = [:]
            for await (albumId, info) in group {
                if let info { map[albumId] = info }
            }
            return map
        }

        var newCards: [AlbumCardItem] = []
        var newTracks: [Track] = []
        var trackId = (curatedTracks.last?.id ?? 0) + 1

        for ref in albums {
            let ab = ref.album
            seenAlbumIds.insert(ab.id)
            let artistDisplay = ref.artist.name
            let card = AlbumCardItem(
                id: "\(ab.id)",
                coverImageName: "album",
                albumTitle: ab.title,
                artistName: artistDisplay,
                coverImageURL: url(ab.coverBig ?? ab.coverMedium),
                deezerAlbumId: ab.id
            )
            newCards.append(card)

            let info = trackInfoMap[ab.id]
            newTracks.append(Track(
                id: trackId,
                title: ab.title,
                artist: artistDisplay,
                albumCover: "album",
                releaseYear: 2024,
                albumCoverURL: url(ab.coverBig),
                artistImageURL: xlURL(ref.artist.pictureXl ?? ref.artist.pictureBig),
                artistThumbnailURL: url(ref.artist.pictureMedium ?? ref.artist.pictureSmall),
                deezerAlbumId: ab.id,
                previewURL: info?.previewURL,
                albumTitle: ab.title,
                trackTitle: info?.title
            ))
            trackId += 1
        }

        self.featuredAlbums.append(contentsOf: newCards)
        self.curatedTracks.append(contentsOf: newTracks)

        if !forYouCarouselGroupsFrozenForSession {
            self.albumGroups = Self.albumGroupsThreeCarousels(from: featuredAlbums)
            if !self.featuredAlbums.isEmpty {
                forYouCarouselGroupsFrozenForSession = true
            }
        }
    }

    /// Три карусели For You: список перемешивается на каждой новой сборке, затем делится поровну.
    private static func albumGroupsThreeCarousels(from albums: [AlbumCardItem]) -> [(title: String, albums: [AlbumCardItem])] {
        let titles = ["Top charts", "Trending now", "More music"]
        guard !albums.isEmpty else {
            return titles.map { ($0, []) }
        }
        let pool = albums.shuffled()
        let n = pool.count
        let base = n / 3
        let rem = n % 3
        var result: [(title: String, albums: [AlbumCardItem])] = []
        var offset = 0
        for i in 0..<3 {
            let chunk = base + (i < rem ? 1 : 0)
            let end = min(offset + chunk, pool.count)
            result.append((titles[i], Array(pool[offset..<end])))
            offset = end
        }
        return result
    }

    private func url(_ string: String?) -> URL? {
        guard let s = string else { return nil }
        return URL(string: s)
    }

    /// Returns a URL with the Deezer CDN size segment upgraded to 1000×1000.
    /// Deezer image URLs follow the pattern: .../NxN-params.jpg — any resolution
    /// can be requested by substituting a different NxN segment.
    private func xlURL(_ string: String?) -> URL? {
        guard let s = string, !s.isEmpty else { return nil }
        let upgraded = s.replacingOccurrences(
            of: #"/\d+x\d+-"#,
            with: "/1000x1000-",
            options: .regularExpression
        )
        return URL(string: upgraded)
    }

    private func formatDeezerDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr else { return "" }
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dateStr) else { return dateStr }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        return outputFormatter.string(from: date)
    }

    // MARK: - My Vibe (same scope as album carousels)

    private func renumberTrack(_ t: Track, id: Int) -> Track {
        Track(
            id: id,
            title: t.title,
            artist: t.artist,
            albumCover: t.albumCover,
            releaseYear: t.releaseYear,
            albumCoverURL: t.albumCoverURL,
            artistImageURL: t.artistImageURL,
            artistThumbnailURL: t.artistThumbnailURL,
            deezerAlbumId: t.deezerAlbumId,
            previewURL: t.previewURL,
            albumTitle: t.albumTitle,
            trackTitle: t.trackTitle
        )
    }

    private func trackFromDeezerPlaylistResult(_ dt: DeezerTrackResult) -> Track {
        Track(
            id: 0,
            title: dt.titleShort ?? dt.title,
            artist: dt.artist?.name ?? "Unknown",
            albumCover: "album",
            releaseYear: 2024,
            albumCoverURL: url(dt.album?.coverBig ?? ""),
            artistImageURL: xlURL(dt.artist?.pictureXl ?? dt.artist?.pictureBig ?? ""),
            artistThumbnailURL: url(dt.artist?.pictureMedium ?? dt.artist?.pictureSmall ?? ""),
            deezerAlbumId: dt.album?.id,
            previewURL: url(dt.preview ?? "")
        )
    }

    /// Полный объект альбома: основной `genre_id` и/или список `genres` из каталога.
    private func deezerAlbumMatchesScope(_ album: DeezerAlbum) -> Bool {
        if let gid = album.genreId, DeezerMusicScope.allowedAlbumGenreIds.contains(gid) { return true }
        if let data = album.genres?.data {
            return data.contains { DeezerMusicScope.allowedAlbumGenreIds.contains($0.id) }
        }
        return false
    }

    /// Треки из международных плейлистов, прошедшие тот же жанровый фильтр, что и альбомы в каруселях (`getAlbum` + `allowedAlbumGenreIds`).
    private func collectPlaylistTracksForMyVibe(targetCount: Int, excludedAlbumIds: Set<Int>) async -> [DeezerTrackResult] {
        guard targetCount > 0 else { return [] }
        var results: [DeezerTrackResult] = []
        var albumPassCache: [Int: Bool] = [:]
        let limit = DeezerMusicScope.playlistTracksPageLimit
        outer: for plId in DeezerMusicScope.internationalSeedPlaylistIds.shuffled() {
            for page in 0..<10 {
                let index = page * limit
                let tracks = (try? await deezer.getPlaylistTracks(playlistId: plId, limit: limit, index: index)) ?? []
                if tracks.isEmpty { break }
                for t in tracks {
                    guard let albumId = t.album?.id else { continue }
                    if excludedAlbumIds.contains(albumId) { continue }
                    let passes: Bool
                    if let cached = albumPassCache[albumId] {
                        passes = cached
                    } else {
                        let album = try? await deezer.getAlbum(id: albumId)
                        let ok = album.map { deezerAlbumMatchesScope($0) } ?? false
                        albumPassCache[albumId] = ok
                        passes = ok
                    }
                    if passes {
                        results.append(t)
                        if results.count >= targetCount { break outer }
                    }
                }
            }
        }
        return results
    }
}
