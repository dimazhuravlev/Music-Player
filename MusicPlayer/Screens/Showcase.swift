import SwiftUI

struct Showcase: View {
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
                        title: "Ramadan Mubarak",
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
                        title: "Faith Journey",
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
                        title: "The Holy Quran",
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
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
    }
}

#Preview {
    Showcase()
}
