import SwiftUI

/// Общая лента витрины (генератор + карусели), используется и в For You, и в Offline.
struct ShowcaseFeedView: View {
    /// Только For You: первый блок каруселей альбомов открывает скелетон экрана альбома без загрузки данных.
    var skeletonFirstAlbumCarousel: Bool = false
    /// Заменить заголовки трёх каруселей под генератором (например, на витрине Offline).
    var albumCarouselTitleOverrides: [String]? = nil

    @State private var selectedPlaylist: String?
    @State private var selectedAlbumItem: AlbumCardItem?
    @State private var navigateToPlayer = false
    @State private var navigateToAlbum = false
    @State private var navigateToAlbumSkeleton = false
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    @EnvironmentObject private var showcaseNavState: ShowcaseNavState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    @EnvironmentObject private var curationManager: ContentCurationManager

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Generator(
                        shaderPlayer: shaderPlayer,
                        tracks: curationManager.myVibeGeneratorTracks,
                        refreshOffset: 0,
                        blurRadius: 0,
                        hasTriggeredFinalHaptic: false,
                        isRefreshing: false,
                        refreshBlurRadius: 0
                    )

                    ForEach(Array(curationManager.albumGroups.prefix(3).enumerated()), id: \.offset) { index, group in
                        AlbumCarousel(
                            title: albumCarouselTitle(at: index, defaultTitle: group.title),
                            albums: group.albums,
                            onAlbumTap: { item in
                                selectedAlbumItem = item
                                navigateToAlbum = false
                                navigateToAlbumSkeleton = false
                                if skeletonFirstAlbumCarousel && index == 0 {
                                    navigateToAlbumSkeleton = true
                                } else {
                                    navigateToAlbum = true
                                }
                            },
                            onAlbumLongPress: { item in
                                overflowMenuState.present(.album(
                                    title: item.albumTitle,
                                    artistName: item.artistName,
                                    releaseYear: 2024,
                                    coverImageName: item.coverImageName,
                                    artistImageName: item.coverImageName,
                                    coverImageURL: item.coverImageURL
                                ))
                            }
                        )
                    }
                }
                .padding(.bottom, 120)
            }
            .background(Color.black)
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
        .navigationDestination(isPresented: $navigateToAlbum) {
            Album(albumName: selectedAlbumItem?.albumTitle, deezerAlbumId: selectedAlbumItem?.deezerAlbumId)
        }
        .navigationDestination(isPresented: $navigateToAlbumSkeleton) {
            AlbumSkeletonScreen()
        }
        .onChange(of: showcaseNavState.requestPopToRoot) { _, _ in
            navigateToAlbumSkeleton = false
            navigateToAlbum = false
            navigateToPlayer = false
        }
        .task {
            await curationManager.loadMyVibeGeneratorTracksIfNeeded()
        }
    }

    private func albumCarouselTitle(at index: Int, defaultTitle: String) -> String {
        guard let overrides = albumCarouselTitleOverrides, index < overrides.count else {
            return defaultTitle
        }
        return overrides[index]
    }
}

#Preview {
    ShowcaseFeedView(shaderPlayer: ShaderPlayerManager())
        .environmentObject(ShowcaseNavState())
        .environmentObject(OverflowMenuState())
        .environmentObject(ContentCurationManager.shared)
}
