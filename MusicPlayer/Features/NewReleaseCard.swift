import SwiftUI
import VariableBlur

struct NewReleaseCard: View {
    let albumCover: String
    let artistName: String
    let albumDescription: String
    let trackThumbnail: String
    let trackTitle: String
    let trackSubtitle: String
    let releaseDate: String
    let artistPhoto: String // New parameter for artist background photo
    let onTap: () -> Void
    let onLike: () -> Void
    let onPlay: () -> Void
    
    @State private var suppressNavigation = false
    @State private var isLiked: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showHeartExplosion: Bool = false
    @State private var likeButtonPosition: CGPoint = CGPoint(x: 240, y: 360)
    
    var body: some View {
        Button {
            if suppressNavigation {
                suppressNavigation = false
                return
            }
            onTap()
        } label: {
            NewReleaseCardContent(
                albumDescription: albumDescription,
                artistName: artistName,
                artistPhoto: artistPhoto,
                trackThumbnail: trackThumbnail,
                trackTitle: trackTitle,
                releaseDate: releaseDate,
                isLiked: $isLiked,
                isPlaying: $isPlaying,
                showHeartExplosion: $showHeartExplosion,
                likeButtonPosition: $likeButtonPosition,
                onLike: onLike,
                onPlay: onPlay,
                suppressNavigation: $suppressNavigation
            )
        }
        .buttonStyle(NewReleaseCardButtonStyle())
    }
}

private struct NewReleaseCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
            .transaction { transaction in
                if configuration.isPressed {
                    transaction.animation = .none
                }
            }
    }
}

private struct NewReleaseCardContent: View {
    let albumDescription: String
    let artistName: String
    let artistPhoto: String
    let trackThumbnail: String
    let trackTitle: String
    let releaseDate: String
    @Binding var isLiked: Bool
    @Binding var isPlaying: Bool
    @Binding var showHeartExplosion: Bool
    @Binding var likeButtonPosition: CGPoint
    let onLike: () -> Void
    let onPlay: () -> Void
    @Binding var suppressNavigation: Bool
    
    var body: some View {
        ZStack {
            // Background images
            VStack(spacing: 0) {
                Image(artistPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 320)
                    .clipped()
                
                Image(artistPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 320)
                    .clipped()
                    .scaleEffect(x: -1, y: -1)
                    .frame(width: 320, height: 150, alignment: .top)
            }
            
            VariableBlurView(maxBlurRadius: 28, direction: .blurredBottomClearTop)
                .frame(width: 320, height: 250)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    Text("New Album")
                        .font(.Text1)
                        .foregroundColor(.subtitle)
                    
                    Text(artistName)
                        .font(.Headline3)
                        .foregroundColor(.fill1)
                        .lineLimit(1)
                    
                    Text(albumDescription)
                        .font(.Text1)
                        .lineSpacing(2)
                        .foregroundColor(.subtitle)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    Image(trackThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trackTitle)
                            .font(.Text1)
                            .foregroundColor(.fill1)
                            .lineLimit(2)
                        
                        Text(releaseDate)
                            .font(.Text1)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        AnimatedIconButton(
                            icon1: "like-default",
                            icon2: "like-active",
                            isActive: isLiked,
                            iconSize: 20
                        ) {
                            handleLikeTap()
                        }
                        .modifier(SuppressNavigationModifier(isActive: $suppressNavigation))
                        
                        PlayPauseButton(isPlaying: isPlaying, size: 40) {
                            handlePlayTap()
                        }
                        .modifier(SuppressNavigationModifier(isActive: $suppressNavigation))
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 430, alignment: .bottom)
        .clipped()
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
        )
        .overlay(
            Group {
                if showHeartExplosion {
                    HeartExplosionView(centerPosition: likeButtonPosition)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showHeartExplosion = false
                            }
                        }
                }
            }
        )
    }
    
    private func handleLikeTap() {
        // Reduce animation complexity for better performance
        withAnimation(.easeInOut(duration: 0.15)) {
            isLiked.toggle()
        }
        
        if isLiked {
            // Delay heart explosion to avoid animation conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showHeartExplosion = true
            }
            // Show global toast when liked
            ToastManager.shared.show(title: ToastCopy.randomLikeTitle(), cover: trackThumbnail)
        }
        
        onLike()
    }
    
    private func handlePlayTap() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isPlaying.toggle()
        }
        onPlay()
    }
}

private struct SuppressNavigationModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0)
                    .onChanged { _ in
                        isActive = true
                    }
                    .onEnded { _ in
                        DispatchQueue.main.async {
                            isActive = false
                        }
                    }
            )
    }
}

struct NewReleaseCarousel: View {
    let releases: [NewReleaseData]
    let onReleaseTap: (NewReleaseData) -> Void
    let onLike: (NewReleaseData) -> Void
    let onPlay: (NewReleaseData) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(releases.enumerated()), id: \.offset) { index, release in
                    NewReleaseCard(
                        albumCover: release.albumCover,
                        artistName: release.artistName,
                        albumDescription: release.albumDescription,
                        trackThumbnail: release.trackThumbnail,
                        trackTitle: release.trackTitle,
                        trackSubtitle: release.trackSubtitle,
                        releaseDate: release.releaseDate,
                        artistPhoto: release.artistPhoto,
                        onTap: {
                            onReleaseTap(release)
                        },
                        onLike: {
                            onLike(release)
                        },
                        onPlay: {
                            onPlay(release)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// Data model for new releases
struct NewReleaseData {
    let albumCover: String
    let artistName: String
    let albumDescription: String
    let trackThumbnail: String
    let trackTitle: String
    let trackSubtitle: String
    let releaseDate: String
    let artistPhoto: String
}


#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        NewReleaseCarousel(
            releases: [],
            onReleaseTap: { _ in },
            onLike: { _ in },
            onPlay: { _ in }
        )
    }
}
