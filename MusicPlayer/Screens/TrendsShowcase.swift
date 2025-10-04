import SwiftUI

struct TrendsShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var navigateToPlayer = false
    @State private var selectedAlbum: String?
    @State private var navigateToAlbum = false
    
    // New releases data
    private let newReleases: [NewReleaseData] = [
        NewReleaseData(
            albumCover: "benson boone",
            artistName: "Benson Boone",
            albumDescription: "A soulful journey through modern pop with heartfelt lyrics and captivating melodies that resonate with listeners across all generations and musical preferences",
            trackThumbnail: "benson boone",
            trackTitle: "Beautiful Things",
            trackSubtitle: "Beautiful Things",
            releaseDate: "15 Jul 2025",
            artistPhoto: "teddy swims"
        ),
        NewReleaseData(
            albumCover: "saint levant",
            artistName: "Saint Levant",
            albumDescription: "He knows love isn't just emotion — it's politics, heritage, and resistance; this bilingual confessional blends spoken-word poetry with contemporary beats to create a powerful narrative of cultural identity and personal growth",
            trackThumbnail: "saint levant",
            trackTitle: "Love Letters / رسائل حب",
            trackSubtitle: "Love Letters",
            releaseDate: "29 Jun 2025",
            artistPhoto: "benson boone"
        ),
        NewReleaseData(
            albumCover: "blur",
            artistName: "Blur",
            albumDescription: "Classic British rock with innovative soundscapes and timeless hits that defined a generation of music lovers and continue to influence contemporary artists worldwide",
            trackThumbnail: "blur",
            trackTitle: "Song 2",
            trackSubtitle: "Song 2",
            releaseDate: "22 Jul 2025",
            artistPhoto: "pixies"
        ),
        NewReleaseData(
            albumCover: "cure",
            artistName: "The Cure",
            albumDescription: "Gothic rock masterpiece with haunting melodies and introspective lyrics that continue to inspire artists today and remain a cornerstone of alternative music culture",
            trackThumbnail: "cure",
            trackTitle: "Friday I'm in Love",
            trackSubtitle: "Friday I'm in Love",
            releaseDate: "30 Jul 2025",
            artistPhoto: "my bloody valentine"
        ),
        NewReleaseData(
            albumCover: "aquarium",
            artistName: "Aquarium",
            albumDescription: "Experimental electronic sounds with ambient textures",
            trackThumbnail: "aquarium",
            trackTitle: "Equinox",
            trackSubtitle: "Equinox",
            releaseDate: "05 Aug 2025",
            artistPhoto: "Wegz 3"
        )
    ]
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // New Releases Carousel
                    NewReleaseCarousel(
                        releases: newReleases,
                        onReleaseTap: { release in
                            // Navigate to album screen
                            selectedAlbum = release.trackTitle
                            navigateToAlbum = true
                        },
                        onLike: { release in
                            // Handle like action
                            print("Liked release: \(release.artistName)")
                        },
                        onPlay: { release in
                            // Handle play action - could start playing the track
                            print("Playing release: \(release.artistName)")
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Popular This Week",
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
                        title: "Rising Stars",
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
                        title: "Viral Hits",
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
                        title: "Chart Toppers",
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
                .padding(.top, 72)
                .padding(.bottom, 120)
            }
            .background(Color.black)
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
        .navigationDestination(isPresented: $navigateToAlbum) {
            Album(albumName: selectedAlbum)
        }
    }
}

#Preview {
    TrendsShowcase()
}
