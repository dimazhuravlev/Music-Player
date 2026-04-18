import AVFoundation
import Combine

@MainActor
final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published private(set) var progress: Double = 0
    @Published private(set) var duration: Double = 30
    @Published private(set) var isActuallyPlaying: Bool = false

    private let trackFinishedSubject = PassthroughSubject<Void, Never>()
    /// Fires once when the current track plays to its natural end.
    var trackFinished: AnyPublisher<Void, Never> { trackFinishedSubject.eraseToAnyPublisher() }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var itemEndObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var currentTrackKey: String?
    private var loadTask: Task<Void, Never>?
    private var previewCache: [String: URL] = [:]

    private init() {
        configureAudioSession()
    }

    /// Resolves an Apple Music preview URL via iTunes Search API,
    /// then streams it directly with AVPlayer.
    func playTrack(artist: String, title: String) {
        let key = "\(artist) – \(title)"

        if key == currentTrackKey, let player {
            player.play()
            isActuallyPlaying = true
            return
        }

        cleanupPlayer()
        currentTrackKey = key
        progress = 0
        isActuallyPlaying = true

        loadTask = Task {
            if let cached = previewCache[key] {
                guard !Task.isCancelled else { return }
                startPlayer(with: AVPlayerItem(url: cached))
                return
            }

            guard let previewURL = await Self.fetchITunesPreview(artist: artist, title: title) else {
                // Only update state if this task is still the active one (not cancelled by a newer track).
                guard !Task.isCancelled else { return }
                isActuallyPlaying = false
                return
            }
            guard !Task.isCancelled else { return }

            previewCache[key] = previewURL
            startPlayer(with: AVPlayerItem(url: previewURL))
        }
    }

    func pause() {
        player?.pause()
        isActuallyPlaying = false
    }

    func resume() {
        guard let player, currentTrackKey != nil else { return }
        player.play()
        isActuallyPlaying = true
    }

    func stop() {
        cleanupPlayer()
        currentTrackKey = nil
        progress = 0
        isActuallyPlaying = false
    }

    // MARK: - iTunes Search

    private static func fetchITunesPreview(artist: String, title: String) async -> URL? {
        let queries = [
            "\(artist) \(title)",
            artist
        ]
        for query in queries {
            if let url = await searchITunes(query: query) { return url }
        }
        return nil
    }

    private static func searchITunes(query: String) async -> URL? {
        let cleaned = query
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
        guard let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&media=music&limit=5")
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else { return nil }

        for result in results {
            if let preview = result["previewUrl"] as? String,
               let previewURL = URL(string: preview) {
                return previewURL
            }
        }
        return nil
    }

    // MARK: - Player Lifecycle

    private func startPlayer(with item: AVPlayerItem) {
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        observeItemStatus(item)
        addObservers()
        newPlayer.play()
        isActuallyPlaying = true
    }

    private func configureAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func cleanupPlayer() {
        loadTask?.cancel()
        loadTask = nil
        removeObservers()
        player?.pause()
        player = nil
    }

    private func observeItemStatus(_ item: AVPlayerItem) {
        statusObservation?.invalidate()
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if item.status == .failed {
                    self.isActuallyPlaying = false
                }
            }
        }
    }

    private func addObservers() {
        guard let player else { return }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, let item = self.player?.currentItem else { return }
                let dur = CMTimeGetSeconds(item.duration)
                let cur = CMTimeGetSeconds(time)
                guard dur.isFinite, dur > 0 else { return }
                self.duration = dur
                self.progress = cur / dur
            }
        }

        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.player?.seek(to: .zero)
                self.progress = 0
                self.isActuallyPlaying = false
                self.trackFinishedSubject.send()
            }
        }
    }

    private func removeObservers() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let obs = timeObserver, let player {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil
        if let obs = itemEndObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        itemEndObserver = nil
    }
}
