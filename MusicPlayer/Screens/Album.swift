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
                    isPlaying: $isPlaying,
                    isLiked: $isLiked
                )
                
                AlbumTrackList(tracks: sampleTracks, albumImageName: albumImageName)
                Spacer(minLength: 120)
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(.container, edges: .top)
    }
    
    
    private var sampleTracks: [Track] {
        [
            Track(id: 1, title: "Beautiful Things", artist: "Benson Boone", albumCover: albumImageName),
            Track(id: 2, title: "Love Letters", artist: "Saint Levant", albumCover: albumImageName),
            Track(id: 3, title: "Song 2", artist: "Blur", albumCover: albumImageName),
            Track(id: 4, title: "Friday I'm in Love", artist: "The Cure", albumCover: albumImageName),
            Track(id: 5, title: "Equinox", artist: "Aquarium", albumCover: albumImageName),
            Track(id: 6, title: "Bohemian Rhapsody", artist: "Queen", albumCover: albumImageName),
            Track(id: 7, title: "Hotel California", artist: "Eagles", albumCover: albumImageName),
            Track(id: 8, title: "Imagine", artist: "John Lennon", albumCover: albumImageName),
            Track(id: 9, title: "Billie Jean", artist: "Michael Jackson", albumCover: albumImageName),
            Track(id: 10, title: "Sweet Child O' Mine", artist: "Guns N' Roses", albumCover: albumImageName),
            Track(id: 11, title: "Stairway to Heaven", artist: "Led Zeppelin", albumCover: albumImageName),
            Track(id: 12, title: "Smells Like Teen Spirit", artist: "Nirvana", albumCover: albumImageName),
            Track(id: 13, title: "Like a Rolling Stone", artist: "Bob Dylan", albumCover: albumImageName),
            Track(id: 14, title: "What's Going On", artist: "Marvin Gaye", albumCover: albumImageName),
            Track(id: 15, title: "Good Vibrations", artist: "The Beach Boys", albumCover: albumImageName),
            Track(id: 16, title: "Johnny B. Goode", artist: "Chuck Berry", albumCover: albumImageName),
            Track(id: 17, title: "Hey Jude", artist: "The Beatles", albumCover: albumImageName),
            Track(id: 18, title: "Purple Rain", artist: "Prince", albumCover: albumImageName),
            Track(id: 19, title: "Born to Run", artist: "Bruce Springsteen", albumCover: albumImageName),
            Track(id: 20, title: "Respect", artist: "Aretha Franklin", albumCover: albumImageName)
        ]
    }
    
    private var albumImageName: String {
        guard let albumName = albumName else { return "album" }
        
        switch albumName {
        case "Beautiful Things":
            return "benson"
        case "Love Letters / رسائل حب":
            return "love letters"
        case "Song 2":
            return "blur"
        case "Friday I'm in Love":
            return "cure"
        case "Equinox":
            return "aquarium"
        case "Bohemian Rhapsody":
            return "queen"
        case "Hotel California":
            return "eagles"
        case "Imagine":
            return "john lennon"
        case "Billie Jean":
            return "michael jackson"
        case "Sweet Child O' Mine":
            return "guns n roses"
        case "Stairway to Heaven":
            return "led zeppelin"
        case "Smells Like Teen Spirit":
            return "nirvana"
        case "Like a Rolling Stone":
            return "bob dylan"
        case "What's Going On":
            return "marvin gaye"
        case "Good Vibrations":
            return "beach boys"
        case "Johnny B. Goode":
            return "chuck berry"
        case "Hey Jude":
            return "beatles"
        case "Purple Rain":
            return "prince"
        case "Born to Run":
            return "bruce springsteen"
        case "Respect":
            return "aretha franklin"
        default:
            return "album"
        }
    }
}

// MARK: - Components

struct AlbumHeader: View {
    let albumName: String?
    let albumImageName: String
    @Binding var isPlaying: Bool
    @Binding var isLiked: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Album cover and title
            VStack(spacing: 24) {
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
                
                // Album title
                Text(albumName ?? "Album")
                    .font(.Headline1)
                    .foregroundColor(.fill1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.top, 120)
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
