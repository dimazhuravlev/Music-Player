import SwiftUI

struct Album: View {
    let albumName: String?
    
    @State private var isPlaying = false
    @State private var isLiked = false
    @State private var showShareAlert = false
    
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
                    contentImageName: albumImageName
                )
                Spacer()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .alert("Share Album", isPresented: $showShareAlert) {
            Button("Copy Link") { }
            Button("Share via Message") { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to share this album")
        }
    }
    
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                AlbumHeader(
                    albumName: albumName,
                    albumImageName: albumImageName,
                    isPlaying: $isPlaying,
                    isLiked: $isLiked,
                    onShare: { showShareAlert = true }
                )
                AlbumTrackList(tracks: sampleTracks, albumImageName: albumImageName)
                Spacer(minLength: 120)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    
    private var sampleTracks: [Track] {
        [
            Track(id: 1, title: "Beautiful Things", artist: "Benson Boone"),
            Track(id: 2, title: "Love Letters", artist: "Saint Levant"),
            Track(id: 3, title: "Song 2", artist: "Blur"),
            Track(id: 4, title: "Friday I'm in Love", artist: "The Cure"),
            Track(id: 5, title: "Equinox", artist: "Aquarium")
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
    let onShare: () -> Void
    
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
                ShareButton(onTap: onShare)
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
                .font(.Title2)
                .foregroundColor(.fill1)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            
            VStack(spacing: 0) {
                ForEach(tracks, id: \.id) { track in
                    AlbumTrackRow(track: track, albumImageName: albumImageName)
                }
            }
        }
    }
}

struct AlbumTrackRow: View {
    let track: Track
    let albumImageName: String
    @State private var isPlaying = false
    
    // track item
    var body: some View {
        HStack(spacing: 12) {
            Image(albumImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .cornerRadius(4)
                .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(track.title)
                    .font(.Text1)
                    .foregroundColor(.fill1)
                
                Text(track.artist)
                    .font(.Text1)
                    .foregroundColor(.subtitle)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.Text1)
                    .foregroundColor(.subtitle)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { isPlaying.toggle() }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 16),
            alignment: .bottom
        )
    }
}

#Preview {
    NavigationStack {
        Album(albumName: "Beautiful Things")
    }
}
