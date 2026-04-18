import SwiftUI

/// Reusable component for displaying a vertical list of tracks with bottom sheet interaction
struct TrackListView: View {
    let tracks: [Track]
    let title: String
    var onTrackLongPress: ((Track) -> Void)? = nil
    @State private var selectedTrack: Track?

    init(tracks: [Track], title: String = "Tracks", onTrackLongPress: ((Track) -> Void)? = nil) {
        self.tracks = tracks
        self.title = title
        self.onTrackLongPress = onTrackLongPress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.Headline5)
                .foregroundColor(.fill1)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                ForEach(tracks) { track in
                    TrackRow(
                        track: track,
                        onTap: { selectedTrack = track },
                        onLongPress: onTrackLongPress.map { handler in { handler(track) } }
                    )
                }
            }
        }
        .sheet(item: $selectedTrack) { track in
            BlockerSheet(track: track)
        }
    }
}

#Preview {
    TrackListView(
        tracks: TrackDataManager.shared.getSampleTracks().prefix(5).map { $0 },
        title: "Sample Tracks"
    )
    .background(Color.black)
}

