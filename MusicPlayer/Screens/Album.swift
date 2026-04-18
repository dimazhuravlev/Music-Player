import SwiftUI

struct Album: View {
    /// When set (e.g. from New Releases carousel), UI uses this data instead of `AlbumDataManager`.
    let newReleaseContext: NewReleaseData?
    let albumName: String?
    var deezerAlbumId: Int? = nil

    @State private var isPlaying = false
    @State private var isLiked = false
    @State private var scrollOffset: CGFloat = 0
    @State private var loadedAlbumData: AlbumData?
    @State private var loadedTracks: [Track]?
    @EnvironmentObject private var collectionState: CollectionState
    @EnvironmentObject private var showcaseNavState: ShowcaseNavState
    @EnvironmentObject private var shareOverlayState: ShareOverlayState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    
    init(albumName: String? = nil, newReleaseContext: NewReleaseData? = nil, deezerAlbumId: Int? = nil) {
        self.newReleaseContext = newReleaseContext
        self.albumName = albumName ?? newReleaseContext?.trackTitle
        self.deezerAlbumId = deezerAlbumId ?? newReleaseContext?.deezerAlbumId
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
            
            // Fixed top navbar that stays in place during navigation
            VStack {
                NavBar(
                    showBackButton: true,
                    showSearchButton: true,
                    onSearchTap: {},
                    contentName: displayAlbumTitle,
                    contentImageName: albumImageName,
                    contentImageURL: albumImageURL,
                    scrollOffset: scrollOffset
                )
                Spacer()
            }
            
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear { showcaseNavState.isShowingDetail = true }
        .onDisappear { showcaseNavState.isShowingDetail = false }
    }
    
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Invisible tracking view at the top
                Color.clear
                    .frame(height: 1)
                    .trackScrollOffset(in: "scroll", offset: $scrollOffset)
                
                AlbumHeader(
                    albumName: displayAlbumTitle,
                    albumImageName: albumImageName,
                    artistImageName: artistImageName,
                    artistName: artistName,
                    releaseYear: releaseYear,
                    artistBio: artistBio,
                    albumImageURL: albumImageURL,
                    artistImageURL: artistImageURL,
                    onShare: {
                    shareOverlayState.present(.album(
                        title: displayAlbumTitle ?? "Album",
                        artistName: artistName,
                        releaseYear: releaseYear,
                        coverImageName: albumImageName,
                        artistImageName: artistImageName,
                        coverImageURL: albumImageURL,
                        artistImageURL: artistThumbnailURL
                    ))
                },
                    isPlaying: $isPlaying,
                    isLiked: $isLiked
                )
                
                TrackListView(
                    tracks: albumTracks,
                    title: "Album Tracks",
                    onTrackLongPress: { track in
                        overflowMenuState.present(ShareableEntity(
                            title: track.title,
                            subtitle: track.artist,
                            year: track.releaseYear,
                            coverImageName: track.albumCover,
                            artistImageName: nil,
                            coverImageURL: track.albumCoverURL,
                            artistImageURL: track.artistThumbnailURL
                        ))
                    }
                )
                Spacer(minLength: 120)
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(.container, edges: .top)
        .task {
            await loadDeezerAlbumData()
        }
    }

    private func loadDeezerAlbumData() async {
        let albumId = deezerAlbumId ?? newReleaseContext?.deezerAlbumId
        guard let albumId = albumId else { return }
        do {
            let deezerAlbum = try await DeezerService.shared.getAlbum(id: albumId)
            let artist = deezerAlbum.artist
            let genreNames = deezerAlbum.genres?.data.map(\.name).joined(separator: ", ") ?? ""
            let bio = [
                artist?.name ?? "",
                genreNames.isEmpty ? "" : "Genre: \(genreNames)",
                deezerAlbum.label.map { "Label: \($0)" } ?? "",
                deezerAlbum.releaseDate.map { "Released: \($0)" } ?? ""
            ].filter { !$0.isEmpty }.joined(separator: " · ")

            self.loadedAlbumData = AlbumData(
                albumImageName: "album",
                artistImageName: "userpic",
                artistName: artist?.name ?? albumData.artistName,
                releaseYear: deezerAlbum.releaseYear ?? albumData.releaseYear,
                artistBio: bio.isEmpty ? albumData.artistBio : bio,
                albumImageURL: URL(string: deezerAlbum.coverXl ?? deezerAlbum.coverBig ?? ""),
                artistImageURL: URL(string: artist?.pictureXl ?? artist?.pictureBig ?? ""),
                artistThumbnailURL: URL(string: artist?.pictureMedium ?? artist?.pictureSmall ?? ""),
                deezerAlbumId: albumId
            )

            let deezerTracks = try await DeezerService.shared.getAlbumTracks(id: albumId)
            self.loadedTracks = deezerTracks.enumerated().map { idx, dt in
                Track(
                    id: idx + 1,
                    title: dt.titleShort ?? dt.title,
                    artist: dt.artist?.name ?? artist?.name ?? "",
                    albumCover: "album",
                    releaseYear: deezerAlbum.releaseYear ?? 2024,
                    albumCoverURL: URL(string: deezerAlbum.coverBig ?? ""),
                    artistImageURL: URL(string: dt.artist?.pictureXl ?? dt.artist?.pictureBig ?? ""),
                    artistThumbnailURL: URL(string: dt.artist?.pictureMedium ?? dt.artist?.pictureSmall ?? ""),
                    deezerAlbumId: albumId,
                    previewURL: URL(string: dt.preview ?? "")
                )
            }
        } catch {
            // Silently fall back to existing data
        }
    }
    
    
    private var albumTracks: [Track] {
        if let loaded = loadedTracks, !loaded.isEmpty { return loaded }
        return ContentCurationManager.shared.curatedTracks
    }
    
    private var displayAlbumTitle: String? {
        if let r = newReleaseContext {
            return r.trackTitle
        }
        return albumName
    }

    private var albumData: AlbumData {
        loadedAlbumData ?? AlbumDataManager.shared.getAlbumData(for: albumName)
    }

    private var albumImageName: String {
        newReleaseContext?.albumCover ?? albumData.albumImageName
    }
    private var albumImageURL: URL? {
        newReleaseContext?.albumCoverURL ?? albumData.albumImageURL
    }
    private var artistImageName: String {
        newReleaseContext?.artistPhoto ?? albumData.artistImageName
    }
    private var artistImageURL: URL? {
        newReleaseContext?.artistPhotoURL ?? albumData.artistImageURL
    }
    private var artistThumbnailURL: URL? {
        albumData.artistThumbnailURL ?? artistImageURL
    }
    private var artistName: String {
        newReleaseContext?.artistName ?? albumData.artistName
    }
    private var releaseYear: Int {
        if let r = newReleaseContext, let y = r.parsedReleaseYear {
            return y
        }
        return albumData.releaseYear
    }
    private var artistBio: String {
        newReleaseContext?.albumDescription ?? albumData.artistBio
    }
}

// MARK: - Components

struct AlbumHeader: View {
    let albumName: String?
    let albumImageName: String
    let artistImageName: String
    let artistName: String
    let releaseYear: Int
    let artistBio: String
    var albumImageURL: URL? = nil
    var artistImageURL: URL? = nil
    var onShare: (() -> Void)? = nil
    @Binding var isPlaying: Bool
    @Binding var isLiked: Bool
    @State private var showFullBio = false
    @EnvironmentObject private var gyroManager: GyroManager
    @EnvironmentObject private var collectionState: CollectionState
    
    private var truncatedBio: String {
        let words = artistBio.components(separatedBy: " ")
        let maxWordsPerLine = 8 // Approximate words per line
        let maxWordsForTwoLines = maxWordsPerLine * 2
        
        if words.count <= maxWordsForTwoLines {
            return artistBio
        }
        
        let wordsForTwoLines = Array(words.prefix(maxWordsForTwoLines))
        return wordsForTwoLines.joined(separator: " ") + "..."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Album cover and title
            VStack(spacing: 0) {
                // Square album cover — 3D наклон по гироскопу
                CachedAsyncImage(url: albumImageURL, assetName: albumImageName)
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 16)
                    .gyroscope3DTilt(gyroManager, intensity: 13, perspective: 0.82)
                    .padding(.bottom, 16)
                
                // Album title
                Text(albumName ?? "Album")
                    .font(.Headline1)
                    .foregroundColor(.fill1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // Artist info
                HStack(spacing: 8) {
                    // Round artist picture
                    CachedAsyncImage(url: artistImageURL, assetName: artistImageName)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    // Artist name and release year
                    VStack(alignment: .leading) {
                        Text(artistName)
                            .font(.Text1)
                            .foregroundColor(.fill1)
                        
                        Text(String(releaseYear))
                            .font(.Text1)
                            .foregroundColor(.subtitle)
                            .kerning(0)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // Bio and action buttons container with synchronized animation
            VStack(spacing: 0) {
                // Artist bio
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(showFullBio ? artistBio : truncatedBio)
                            .font(.Text1)
                            .foregroundColor(.subtitle)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showFullBio.toggle()
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
                // Action buttons
                HStack(spacing: 6) {
                    ListenButton(isPlaying: $isPlaying)
                    Spacer()
                    ShareButton(onShare: onShare ?? {})
                    LikeButton(isLiked: $isLiked) {
                        ToastManager.shared.show(title: ToastCopy.randomLikeTitle(), cover: albumImageName, coverURL: albumImageURL)
                        collectionState.registerLike(coverName: albumImageName, coverURL: albumImageURL)
                    }
                }
                .padding(.horizontal, 16)
            }
            .animation(.easeInOut(duration: 0.5), value: showFullBio)
        }
        .padding(.top, 120)
        .padding(.bottom, 24)
    }
}



#Preview {
    NavigationStack {
        Album(albumName: "Beautiful Things")
            .environmentObject(GyroManager.shared)
            .environmentObject(ShowcaseNavState())
            .environmentObject(ShareOverlayState())
            .environmentObject(OverflowMenuState())
            .environmentObject(NowPlayingState())
            .environmentObject(CollectionState())
    }
}
