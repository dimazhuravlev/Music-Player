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
    
    @State private var cardTapScale: CGFloat = 1.0
    @State private var cardLongTapScale: CGFloat = 1.0
    @State private var isLiked: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showHeartExplosion: Bool = false
    @State private var likeButtonPosition: CGPoint = CGPoint(x: 240, y: 360)
    
    var body: some View {
        ZStack {
            // Background images
            VStack(spacing: 0) {
                // Original artist photo
                Image(artistPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 320)
                    .clipped()
                
                // Mirrored artist photo
                Image(artistPhoto)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 320)
                    .clipped()
                    .scaleEffect(x: -1, y: -1) // Mirror horizontally and invert vertically
                    .frame(width: 320, height: 150, alignment: .top)
            }
            
            // Variable blur overlay
            VariableBlurView(maxBlurRadius: 28, direction: .blurredBottomClearTop)
                .frame(width: 320, height: 250)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // Content
            VStack(spacing: 0) {
                    // label, artist name and bio
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
                        
                        // Horizontal divider
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 0.5)
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 16)
                    // .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // Album section
                HStack(spacing: 12) {
                    // Album cover
                    Image(trackThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(6)
                    
                    // Album info
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
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Like button
                        AnimatedIconButton(
                            icon1: "like-default",
                            icon2: "like-active",
                            isActive: isLiked,
                            iconSize: 20
                        ) {
                            withAnimation(.smooth(duration: 0.2)) {
                                isLiked.toggle()
                            }
                            
                            // Trigger heart explosion when liking
                            if isLiked {
                                showHeartExplosion = true
                            }
                            
                            onLike()
                        }
                        
                        // Play button
                        PlayPauseButton(isPlaying: isPlaying, size: 40) {
                            withAnimation(.smooth(duration: 0.2)) {
                                isPlaying.toggle()
                            }
                            onPlay()
                        }
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
        .scaleEffect(cardTapScale * cardLongTapScale)
        .animation(.smooth(duration: 0.1), value: cardTapScale)
        .animation(.smooth(duration: 0.2), value: cardLongTapScale)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    cardLongTapScale = 0.98
                }
                .onEnded { _ in
                    cardLongTapScale = 1.0
                }
        )
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.1)) {
                        cardTapScale = 0.98
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.smooth(duration: 0.1)) {
                            cardTapScale = 1.0
                        }
                    }

                    onTap()
                }
                .overlay(
                    // Heart explosion overlay
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
