import SwiftUI

struct Playlist: View {
    let playlistName: String?
    
    @State private var isPlaying = false
    @State private var isLiked = false
    @State private var showShareAlert = false
    @State private var selectedFilter = "Top"
    
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
                    contentImageName: playlistImageName
                )
                Spacer()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .alert("Share Playlist", isPresented: $showShareAlert) {
            Button("Copy Link") { }
            Button("Share via Message") { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to share this playlist")
        }
    }
    
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ArtistHeader(
                    playlistName: playlistName,
                    playlistImageName: playlistImageName,
                    isPlaying: $isPlaying,
                    isLiked: $isLiked,
                    selectedFilter: $selectedFilter,
                    onShare: { showShareAlert = true }
                )
                TrackList(tracks: sampleTracks, playlistImageName: playlistImageName)
                Spacer(minLength: 120)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    
    private var sampleTracks: [Track] {
        [
            Track(id: 1, title: "Ramsis Paris", artist: "Wegz"),
            Track(id: 2, title: "Gada3 W Zeen", artist: "Kan, double Zuksh"),
            Track(id: 3, title: "Ramsis Paris", artist: "Sharmoofers, Perrie")
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
        ZStack(alignment: .bottomLeading) {
            artistImage
            artistInfo
        }
    }
    
    private var artistImage: some View {
        Image(playlistImageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipped()
            .overlay(gradientOverlay)
    }
    
    private var gradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                .black.opacity(0.3),
                .black.opacity(1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var artistInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(playlistName ?? "Playlist")
                .font(.Headline1)
                .foregroundColor(.fill1)
            
            HStack(spacing: 12) {
                ListenButton(isPlaying: $isPlaying)
                Spacer()
                LikeButton(isLiked: $isLiked)
                ShareButton(onTap: onShare)
            }
            
            FilterCarousel(selectedFilter: $selectedFilter)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

struct ListenButton: View {
    @Binding var isPlaying: Bool
    
    var body: some View {
        Button(action: { isPlaying.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Listen")
                    .font(.system(size: 16, weight: .semibold))
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
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundColor(isLiked ? .red : .fill1)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct ShareButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
                .foregroundColor(.fill1)
                .frame(width: 44, height: 44)
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
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
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
                .font(.Text3)
                .foregroundColor(.fill1)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            
            VStack(spacing: 0) {
                ForEach(tracks, id: \.id) { track in
                    TrackRow(track: track, playlistImageName: playlistImageName)
                }
            }
        }
    }
}

struct TrackRow: View {
    let track: Track
    let playlistImageName: String
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(playlistImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.fill1)
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { isPlaying.toggle() }
    }
}

// MARK: - Models

struct Track {
    let id: Int
    let title: String
    let artist: String
}

#Preview {
    NavigationStack {
        Playlist(playlistName: "Anasheed")
    }
}
