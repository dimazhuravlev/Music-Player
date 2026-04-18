import SwiftUI

struct TrendsShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var selectedAlbumItem: AlbumCardItem?
    @State private var navigateToPlayer = false
    @State private var navigateToAlbum = false
    @State private var selectedNewRelease: NewReleaseData?
    @EnvironmentObject private var collectionState: CollectionState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    @EnvironmentObject private var curationManager: ContentCurationManager

    private var newReleases: [NewReleaseData] {
        curationManager.newReleases
    }
    
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
                            selectedNewRelease = release
                        },
                        onLike: { release in
                            collectionState.registerLike(coverName: release.albumCover, coverURL: release.albumCoverURL)
                        },
                        onPlay: { release in
                            // Handle play action - could start playing the track
                            print("Playing release: \(release.artistName)")
                        },
                        onLongPress: { release in
                            overflowMenuState.present(.album(
                                title: release.trackTitle,
                                artistName: release.artistName,
                                releaseYear: release.parsedReleaseYear ?? 2025,
                                coverImageName: release.albumCover,
                                artistImageName: release.artistPhoto,
                                coverImageURL: release.albumCoverURL,
                                artistImageURL: release.artistThumbnailURL ?? release.artistPhotoURL
                            ))
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
                        onPlaylistTap: { name in
                            selectedPlaylist = name
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
                        onPlaylistTap: { name in
                            selectedPlaylist = name
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
                        onPlaylistTap: { name in
                            selectedPlaylist = name
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
                        onPlaylistTap: { name in
                            selectedPlaylist = name
                            navigateToPlayer = true
                        }
                    )
                }
                .padding(.top, 72)
                .padding(.bottom, 120)
            }
            .background(Color.black)
        }
        .task {
            await curationManager.loadNewReleasesIfNeeded()
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
        .navigationDestination(isPresented: $navigateToAlbum) {
            Album(albumName: selectedAlbumItem?.albumTitle, deezerAlbumId: selectedAlbumItem?.deezerAlbumId)
        }
        .navigationDestination(item: $selectedNewRelease) { release in
            Album(newReleaseContext: release)
        }
    }
}

#Preview {
    TrendsShowcase()
        .environmentObject(CollectionState())
        .environmentObject(OverflowMenuState())
}
