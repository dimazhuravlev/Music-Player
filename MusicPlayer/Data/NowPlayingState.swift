import Foundation

/// Shared now playing state so components (e.g., mini player, swipe player)
/// stay in sync on the currently selected track.
final class NowPlayingState: ObservableObject {
    @Published var track: Track
    
    init(track: Track? = nil) {
        if let provided = track {
            self.track = provided
        } else if let first = TrackDataManager.shared.getSampleTracks().first {
            self.track = first
        } else {
            // Fallback track to keep UI stable if the sample list is empty.
            self.track = Track(id: 0, title: "Track", artist: "Artist", albumCover: "album", releaseYear: 2024)
        }
    }
}

