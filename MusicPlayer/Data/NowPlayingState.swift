import Foundation
import Combine

/// Shared now playing state so components (e.g., mini player, swipe player)
/// stay in sync on the currently selected track.
/// Persists last played track so MiniPlayer shows a cover on cold start.
@MainActor
final class NowPlayingState: ObservableObject {
    @Published var track: Track {
        didSet {
            persistTrack()
            loadAndPlay()
        }
    }
    @Published var isPlaying: Bool {
        didSet {
            guard !isSyncing else { return }
            syncPlayback()
        }
    }
    @Published var trackIndex: GridIndex?

    let audioPlayer = AudioPlayerManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let title = "np_title"
        static let artist = "np_artist"
        static let coverURL = "np_coverURL"
        static let artistURL = "np_artistURL"
        static let albumId = "np_albumId"
    }

    init(track: Track? = nil, isPlaying: Bool = false, trackIndex: GridIndex? = nil) {
        if let provided = track {
            self.track = provided
        } else if let restored = Self.restoreTrack() {
            self.track = restored
        } else if let random = ContentCurationManager.shared.curatedTracks.randomElement() {
            self.track = random
        } else {
            self.track = Track(id: 0, title: "", artist: "", albumCover: "album", releaseYear: 2024)
        }
        self.isPlaying = isPlaying
        self.trackIndex = trackIndex

        audioPlayer.$isActuallyPlaying
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] playing in
                guard let self, self.isPlaying != playing else { return }
                self.isSyncing = true
                self.isPlaying = playing
                self.isSyncing = false
            }
            .store(in: &cancellables)
    }

    private func loadAndPlay() {
        guard isPlaying else { return }
        let trackName = track.trackTitle ?? track.title
        audioPlayer.playTrack(artist: track.artist, title: trackName)
    }

    private func syncPlayback() {
        if isPlaying {
            let trackName = track.trackTitle ?? track.title
            audioPlayer.playTrack(artist: track.artist, title: trackName)
        } else {
            audioPlayer.pause()
        }
    }

    private func persistTrack() {
        defaults.set(track.title, forKey: Keys.title)
        defaults.set(track.artist, forKey: Keys.artist)
        defaults.set(track.albumCoverURL?.absoluteString, forKey: Keys.coverURL)
        defaults.set(track.artistImageURL?.absoluteString, forKey: Keys.artistURL)
        if let id = track.deezerAlbumId { defaults.set(id, forKey: Keys.albumId) }
    }

    private static func restoreTrack() -> Track? {
        let d = UserDefaults.standard
        guard let title = d.string(forKey: Keys.title), !title.isEmpty else { return nil }
        return Track(
            id: 0,
            title: title,
            artist: d.string(forKey: Keys.artist) ?? "",
            albumCover: "album",
            releaseYear: 2024,
            albumCoverURL: d.string(forKey: Keys.coverURL).flatMap { URL(string: $0) },
            artistImageURL: d.string(forKey: Keys.artistURL).flatMap { URL(string: $0) },
            deezerAlbumId: d.object(forKey: Keys.albumId) as? Int
        )
    }
}
