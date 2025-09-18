import SwiftUI

struct ForYouShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var navigateToPlayer = false
    @State private var refreshOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Generator(
                        tracks: TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 },
                        onTrackTap: { track in
                            // Handle track tap
                        },
                        refreshOffset: refreshOffset,
                        blurRadius: min(refreshOffset / 4, 20) // Blur from 0 to 20 based on refresh offset
                    )
                    
                    PlaylistCarousel(
                        title: "Best Releases for You",
                        playlists: [
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Artists You Like",
                        playlists: [
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Daily Reminders",
                        playlists: [
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Spiritual Growth",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                }
                .padding(.bottom, 120)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                refreshOffset = min(value.translation.height * 0.3, 80)
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2)) {
                            refreshOffset = 0
                        }
                    }
            )
            .refreshable {
                await refreshContent()
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
    }
    
    private func refreshContent() async {
        isRefreshing = true
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isRefreshing = false
    }
}

#Preview {
    ForYouShowcase()
}
