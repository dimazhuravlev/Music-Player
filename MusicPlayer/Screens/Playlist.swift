import SwiftUI
import VariableBlur

struct Playlist: View {
    let playlistName: String?
    
    @State private var isPlaying = false
    @State private var isLiked = false
    @State private var selectedFilter = "Top"
    @State private var scrollOffset: CGFloat = 0
    
    init(playlistName: String? = nil) {
        self.playlistName = playlistName
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
            
            // Fixed top navbar that stays in place during navigation
            VStack {
                NavBar(
                    showBackButton: true,
                    showSearchButton: true,
                    onSearchTap: {},
                    contentName: playlistName,
                    contentImageName: playlistImageName,
                    scrollOffset: scrollOffset
                )
                Spacer()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }
    
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Invisible tracking view at the top
                Color.clear
                    .frame(height: 1)
                    .trackScrollOffset(in: "scroll", offset: $scrollOffset)
                
                // ZStack with image and content overlaid
                ZStack(alignment: .bottomLeading) {
                    // Image layer (always square shape)
                    Image(playlistImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                        .clipped()
                        .overlay(
                            VStack {
                                Spacer()
                                ZStack(alignment: .bottom) {
                                    VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop)
                                        .frame(height: 80)
                                        .frame(maxWidth: .infinity)                        
                                    LinearGradient(
                                        stops: [
                                        Gradient.Stop(color: .black.opacity(0), location: 0.00),
                                        Gradient.Stop(color: .black.opacity(0.01), location: 0.12),
                                        Gradient.Stop(color: .black.opacity(0.03), location: 0.21),
                                        Gradient.Stop(color: .black.opacity(0.07), location: 0.29),
                                        Gradient.Stop(color: .black.opacity(0.12), location: 0.35),
                                        Gradient.Stop(color: .black.opacity(0.18), location: 0.40),
                                        Gradient.Stop(color: .black.opacity(0.25), location: 0.45),
                                        Gradient.Stop(color: .black.opacity(0.33), location: 0.48),
                                        Gradient.Stop(color: .black.opacity(0.41), location: 0.52),
                                        Gradient.Stop(color: .black.opacity(0.5), location: 0.55),
                                        Gradient.Stop(color: .black.opacity(0.59), location: 0.60),
                                        Gradient.Stop(color: .black.opacity(0.67), location: 0.65),
                                        Gradient.Stop(color: .black.opacity(0.76), location: 0.71),
                                        Gradient.Stop(color: .black.opacity(0.85), location: 0.79),
                                        Gradient.Stop(color: .black.opacity(0.93), location: 0.88),
                                        Gradient.Stop(color: .black, location: 1.00),
                                        ],
                                        startPoint: UnitPoint(x: 0.5, y: 0),
                                        endPoint: UnitPoint(x: 0.5, y: 1)
                                    )
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        )
                    
                    // Content VStack overlaid on image
                    VStack(alignment: .leading, spacing: 16) {
                        Text(playlistName ?? "Playlist")
                            .font(.Headline1)
                            .foregroundColor(.fill1)
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 6) {
                            ListenButton(isPlaying: $isPlaying)
                            Spacer()
                            LikeButton(isLiked: $isLiked)
                        }
                        .padding(.horizontal, 16)
                        
                        FilterCarousel(selectedFilter: $selectedFilter)
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                    .offset(y: 100)
                }
                
                // TrackList below the image
                TrackList(tracks: sampleTracks, playlistImageName: playlistImageName)
                    .offset(y: 100)
                
                Spacer(minLength: 120)
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(.container, edges: .top)
    }
    
    
    private var sampleTracks: [Track] {
        [
            Track(id: 1, title: "Ramsis Paris", artist: "Wegz", albumCover: "benson"),
            Track(id: 2, title: "Gada3 W Zeen", artist: "Kan, double Zuksh", albumCover: "love letters"),
            Track(id: 3, title: "Ramsis Paris", artist: "Sharmoofers, Perrie", albumCover: "blur"),
            Track(id: 4, title: "El Bint El Helwa", artist: "Amr Diab", albumCover: "cure"),
            Track(id: 5, title: "Habibi Ya Nour El Ein", artist: "Amr Diab", albumCover: "aquarium"),
            Track(id: 6, title: "Tamally Maak", artist: "Amr Diab", albumCover: "sonic"),
            Track(id: 7, title: "Ana Baashaak", artist: "Tamer Hosny", albumCover: "uglymoss"),
            Track(id: 8, title: "El Donia Helwa", artist: "Tamer Hosny", albumCover: "benson"),
            Track(id: 9, title: "Ya Ghali", artist: "Mohamed Mounir", albumCover: "love letters"),
            Track(id: 10, title: "El Bahr Byedhak", artist: "Mohamed Mounir", albumCover: "blur"),
            Track(id: 11, title: "Salam Aleik", artist: "Fairuz", albumCover: "cure"),
            Track(id: 12, title: "Kifak Inta", artist: "Fairuz", albumCover: "aquarium"),
            Track(id: 13, title: "Ya Rayt", artist: "Fairuz", albumCover: "sonic"),
            Track(id: 14, title: "Nassam Alayna El Hawa", artist: "Fairuz", albumCover: "uglymoss"),
            Track(id: 15, title: "Aatini El Nay", artist: "Fairuz", albumCover: "benson")
        ]
    }
    
    private var playlistImageName: String {
        guard let playlistName = playlistName else { return "album" }
        
        switch playlistName {
        case "Anasheed":
            return "Anasheed"
        case "MorningAzkar":
            return "MorningAzkar"
        case "EveningAzkar":
            return "EveningAzkar"
        case "Ruqya":
            return "Ruqya"
        default:
            return "album"
        }
    }
}

// MARK: - Components

struct ArtistHeader: View {
    let playlistName: String?
    let playlistImageName: String
    @Binding var isPlaying: Bool
    @Binding var isLiked: Bool
    @Binding var selectedFilter: String
    let onShare: () -> Void
    
    var body: some View {
        ZStack {
            artistImage
            artistInfo
        }
    }
    
    private var artistImage: some View {
        ZStack(alignment: .bottom) {
            Image(playlistImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1/1, contentMode: .fill)
                .clipped()
            
            VariableBlurView(maxBlurRadius: 20, direction: .blurredBottomClearTop)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var artistInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(playlistName ?? "Playlist")
                .font(.Headline1)
                .foregroundColor(.fill1)
            
            HStack(spacing: 6) {
                ListenButton(isPlaying: $isPlaying)
                Spacer()
                LikeButton(isLiked: $isLiked)
            }
            
            FilterCarousel(selectedFilter: $selectedFilter)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct ListenButton: View {
    @Binding var isPlaying: Bool
    
    var body: some View {
        Button(action: { isPlaying.toggle() }) {
            HStack(spacing: 8) {
                AnimatedIconButton(
                    icon1: "play",
                    icon2: "pause",
                    isActive: isPlaying,
                    iconSize: 20
                ) {
                    isPlaying.toggle()
                }
                Text("Listen")
                    .font(.Text1)
            }
            .foregroundColor(.fill1)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.accent)
            .cornerRadius(25)
        }
    }
}

struct LikeButton: View {
    @Binding var isLiked: Bool
    
    var body: some View {
        Button(action: { isLiked.toggle() }) {
            AnimatedIconButton(
                icon1: "like-default",
                icon2: "like-active",
                isActive: isLiked,
                iconSize: 20
            ) {
                isLiked.toggle()
            }
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.1))
            .clipShape(Circle())
        }
    }
}


struct FilterCarousel: View {
    @Binding var selectedFilter: String
    @State private var animateFilters = false
    
    private let filters = ["Top", "Albums", "Playlists", "Artists", "Tracks", "Video", "Podcasts"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(filters.enumerated()), id: \.element) { index, filter in
                    FilterButton(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                    .offset(x: animateFilters ? 0 : 400)
                    .animation(
                        .smooth(duration: 0.3)
                        .delay(Double(index) * 0.05),
                        value: animateFilters
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
        .onAppear {
            animateFilters = true
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .black : .fill1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.fill1 : Color.white.opacity(0.15))
                )
                .background(
                    Capsule()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .opacity(isSelected ? 0 : 0.15)
                )
        }
    }
}


struct TrackList: View {
    let tracks: [Track]
    let playlistImageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Top Tracks")
                .font(.Headline5)
                .foregroundColor(.fill1)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                ForEach(tracks, id: \.id) { track in
                    TrackRow(track: track)
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        Playlist(playlistName: "Anasheed")
    }
}
