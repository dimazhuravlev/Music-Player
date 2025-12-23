import SwiftUI

/// Reusable component for displaying tracks in a horizontal carousel with groups of 3
struct TrackCarouselView: View {
    let tracks: [Track]
    let blurRadius: CGFloat
    @State private var selectedTrack: Track?
    
    init(tracks: [Track], blurRadius: CGFloat = 0) {
        self.tracks = tracks
        self.blurRadius = blurRadius
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tracks.chunked(into: 3).enumerated()), id: \.offset) { index, trackGroup in
                    VStack(spacing: 0) {
                        ForEach(trackGroup, id: \.id) { track in
                            TrackRow(track: track, onTap: {
                                selectedTrack = track
                            })
                        }
                    }
                    .frame(width: 360)
                    .padding(.trailing, 0)
                }
            }
        }
        .scrollTargetBehavior(.paging)
        .blur(radius: blurRadius)
        .sheet(item: $selectedTrack) { track in
            BlockerSheet(track: track)
        }
    }
}

// Extension to chunk array into groups of specified size
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    TrackCarouselView(
        tracks: TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 },
        blurRadius: 0
    )
    .background(Color.black)
}

