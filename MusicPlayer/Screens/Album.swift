import SwiftUI

struct Album: View {
    let albumName: String?
    
    @State private var isPlaying = false
    @State private var isLiked = false
    @State private var scrollOffset: CGFloat = 0
    
    init(albumName: String? = nil) {
        self.albumName = albumName
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
                    contentName: albumName,
                    contentImageName: albumImageName,
                    scrollOffset: scrollOffset
                )
                Spacer()
            }
            
            // Fixed bottom bar that stays in place during navigation
            VStack {
                Spacer()
                BottomBar()
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
                
                AlbumHeader(
                    albumName: albumName,
                    albumImageName: albumImageName,
                    artistImageName: artistImageName,
                    artistName: artistName,
                    releaseYear: releaseYear,
                    artistBio: artistBio,
                    isPlaying: $isPlaying,
                    isLiked: $isLiked
                )
                
                AlbumTrackList(tracks: albumTracks, albumImageName: albumImageName)
                Spacer(minLength: 120)
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(.container, edges: .top)
    }
    
    
    private var albumTracks: [Track] {
        return TrackDataManager.shared.getSampleTracks()
    }
    
    private var albumData: AlbumData {
        return AlbumDataManager.shared.getAlbumData(for: albumName)
    }
    
    private var albumImageName: String { albumData.albumImageName }
    private var artistImageName: String { albumData.artistImageName }
    private var artistName: String { albumData.artistName }
    private var releaseYear: Int { albumData.releaseYear }
    private var artistBio: String { albumData.artistBio }
}

// MARK: - Components

struct AlbumHeader: View {
    let albumName: String?
    let albumImageName: String
    let artistImageName: String
    let artistName: String
    let releaseYear: Int
    let artistBio: String
    @Binding var isPlaying: Bool
    @Binding var isLiked: Bool
    @State private var showFullBio = false
    
    private var truncatedBio: String {
        let words = artistBio.components(separatedBy: " ")
        let maxWordsPerLine = 8 // Approximate words per line
        let maxWordsForTwoLines = maxWordsPerLine * 2
        
        if words.count <= maxWordsForTwoLines {
            return artistBio
        }
        
        let wordsForTwoLines = Array(words.prefix(maxWordsForTwoLines))
        return wordsForTwoLines.joined(separator: " ") + "..."
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Album cover and title
            VStack(spacing: 0) {
                // Square album cover
                Image(albumImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .cornerRadius(16)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.bottom, 16)
                
                // Album title
                Text(albumName ?? "Album")
                    .font(.Headline1)
                    .foregroundColor(.fill1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // Artist info
                HStack(spacing: 8) {
                    // Round artist picture
                    Image(artistImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    // Artist name and release year
                    VStack(alignment: .leading) {
                        Text(artistName)
                            .font(.Text1)
                            .foregroundColor(.fill1)
                        
                        Text(String(releaseYear))
                            .font(.Text1)
                            .foregroundColor(.subtitle)
                            .kerning(0)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // Bio and action buttons container with synchronized animation
            VStack(spacing: 0) {
                // Artist bio
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(showFullBio ? artistBio : truncatedBio)
                            .font(.Text1)
                            .foregroundColor(.subtitle)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showFullBio.toggle()
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
                // Action buttons
                HStack(spacing: 6) {
                    ListenButton(isPlaying: $isPlaying)
                    Spacer()
                    LikeButton(isLiked: $isLiked)
                }
                .padding(.horizontal, 16)
            }
            .animation(.easeInOut(duration: 0.5), value: showFullBio)
        }
        .padding(.top, 110)
        .padding(.bottom, 24)
    }
}

struct AlbumTrackList: View {
    let tracks: [Track]
    let albumImageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Album Tracks")
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
        Album(albumName: "Beautiful Things")
    }
}
