import SwiftUI

struct ForYouShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var navigateToPlayer = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 32) {
                    PlaylistCarousel(
                        title: "",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
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
                .padding(.top, 48)
                .padding(.bottom, 120)
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
    }
}

#Preview {
    ForYouShowcase()
}
