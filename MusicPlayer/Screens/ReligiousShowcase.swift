import SwiftUI

struct ReligiousShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var navigateToPlaylist = false
    @EnvironmentObject private var overflowMenuState: OverflowMenuState

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    PlaylistCarousel(
                        title: "",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlaylist = true
                        }
                    )

                    PlaylistCarousel(
                        title: "Prayer & Meditation",
                        playlists: [
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {})
                        ],
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlaylist = true
                        }
                    )

                    PlaylistCarousel(
                        title: "Quranic Verses",
                        playlists: [
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlaylist = true
                        }
                    )

                    PlaylistCarousel(
                        title: "Spiritual Healing",
                        playlists: [
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlaylist = true
                        }
                    )

                    PlaylistCarousel(
                        title: "Divine Wisdom",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {})
                        ],
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlaylist = true
                        }
                    )
                }
                .padding(.top, 48)
                .padding(.bottom, 120)
            }
            .background(Color.black)
        }
        .navigationDestination(isPresented: $navigateToPlaylist) {
            Playlist(playlistName: selectedPlaylist)
        }
    }
}

#Preview {
    ReligiousShowcase()
        .environmentObject(OverflowMenuState())
}
