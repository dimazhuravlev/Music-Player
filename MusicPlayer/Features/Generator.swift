import SwiftUI
import AVKit

struct VideoBackgroundView: View {
    let refreshOffset: CGFloat
    @State private var player: AVPlayer?
    @State private var isVisible: Bool = true
    
    var body: some View {
        ZStack {
            // Fallback background
            Color.black
                .ignoresSafeArea()
            
            // Video player - only show when visible and reduce resource usage
            if let player = player, isVisible {
                VideoPlayer(player: player)
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 300, height: 300)
                    .clipped()
                    .offset(y: -120 - refreshOffset)
                    .ignoresSafeArea()
                    .onAppear {
                        // Delay video start to reduce initial load
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
        }
        .onAppear {
            setupVideo()
            isVisible = true
        }
        .onDisappear {
            isVisible = false
            player?.pause()
        }
    }
    
    private func setupVideo() {
        // Perform video setup on background queue to avoid blocking UI
        Task.detached(priority: .background) {
            guard let asset = NSDataAsset(name: "Shader") else { return }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Shader.mov")
            
            do {
                try asset.data.write(to: tempURL)
                
                await MainActor.run {
                    let newPlayer = AVPlayer(url: tempURL)
                    newPlayer.actionAtItemEnd = .none
                    
                    // Set up looping
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: newPlayer.currentItem,
                        queue: .main
                    ) { _ in
                        newPlayer.seek(to: .zero)
                        newPlayer.play()
                    }
                    
                    self.player = newPlayer
                }
            } catch {
                // Silently fail - fallback to black background
            }
        }
    }
}

struct Generator: View {
    let tracks: [Track]
    let onTrackTap: (Track) -> Void
    let refreshOffset: CGFloat
    let blurRadius: CGFloat
    
    @State private var currentIndex = 0
    @State private var selectedFilter: String? = nil
    @State private var isPlaying = false
    
    private let filters = ["Taylor Swift", "Energetic", "Assal", "Rock", "Pop", "Hip Hop", "Electronic", "Jazz", "Classical", "Indie", "R&B"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background video shader
            VideoBackgroundView(refreshOffset: refreshOffset)
            
            VStack(alignment: .leading, spacing: 8) {
            // Header with title and play button
            HStack {
                Text("My Vibe")
                    .font(.Headline1)
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    
                    AnimatedIconButton(
                        icon1: "play",
                        icon2: "pause",
                        isActive: isPlaying,
                        iconSize: 24,
                        iconColor: .black,
                        onTap: {
                            isPlaying.toggle()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Filter carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = selectedFilter == filter ? nil : filter
                        }) {
                            Text(filter)
                                .font(.Text1)
                                .foregroundColor(selectedFilter == filter ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 56)
                                        .fill(selectedFilter == filter ? Color.white : Color.white.opacity(0.01))
                                        .background(.thinMaterial.opacity(0.15), in: RoundedRectangle(cornerRadius: 56))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Track carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(tracks.chunked(into: 3).enumerated()), id: \.offset) { index, trackGroup in
                        VStack(spacing: 0) {
                            ForEach(trackGroup, id: \.id) { track in
                                TrackRow(track: track)
                                    .onTapGesture {
                                        onTrackTap(track)
                                    }
                            }
                        }
                        .frame(width: 320) // Leave space for partial view
                        .padding(.trailing, 20) // Add padding to show partial next track
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .blur(radius: blurRadius)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 220)
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
    Generator(
        tracks: TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 },
        onTrackTap: { _ in },
        refreshOffset: 0,
        blurRadius: 0
    )
    .background(Color.black)
}
