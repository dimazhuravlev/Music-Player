import SwiftUI

/// Reusable component for displaying a vertical list of tracks with bottom sheet interaction
struct TrackListView: View {
    let tracks: [Track]
    let title: String
    @State private var selectedTrack: Track?
    
    init(tracks: [Track], title: String = "Tracks") {
        self.tracks = tracks
        self.title = title
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
                    TrackRow(track: track) {
                        selectedTrack = track
                    }
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

