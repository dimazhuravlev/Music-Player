import SwiftUI

struct FullscreenPlayer: View {
    @State private var isPlaying = false
    @State private var isPreviousActive = false
    @State private var isNextActive = false
    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var showHeartExplosion = false
    @State private var albumTapScale: CGFloat = 1.0
    @State private var albumLongTapScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            backgroundView
            mainContent
        }
    }
    
    private var backgroundView: some View {
        Image("album")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .blur(radius: 80)
            .overlay(Color.black.opacity(0.3).ignoresSafeArea())
    }
    
    private var mainContent: some View {
        VStack(spacing: 48) {
            Spacer()
            albumCover
            controlButtons
            Spacer()
        }
        .overlay(heartExplosionOverlay)
    }
    
    private var albumCover: some View {
        Image("album")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 340)
            .shadow(radius: 8)
            .border(Color.white.opacity(0.08), width: 0.66)
            .cornerRadius(12)
            .scaleEffect((isPlaying ? 1 : 0.9) * albumTapScale * albumLongTapScale)
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: isPlaying)
            .animation(.smooth(duration: 0.15), value: albumTapScale)
            .animation(.smooth(duration: 0.15), value: albumLongTapScale)
            .zIndex(1000)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Scale down when pressed
                        albumLongTapScale = 0.95
                    }
                    .onEnded { _ in
                        // Scale back up when released
                        albumLongTapScale = 1.0
                    }
            )
            .onTapGesture {
                // Tap animation with completion guarantee
                withAnimation(.smooth(duration: 0.15)) {
                    albumTapScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.smooth(duration: 0.15)) {
                        albumTapScale = 1.0
                    }
                }
            }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 32) {
            dislikeButton
            previousButton
            playPauseButton
            nextButton
            likeButton
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dislikeButton: some View {
        AnimatedIconButton(
            icon1: "dislike-default",
            icon2: "dislike-active",
            isActive: isDisliked,
            iconSize: 24
        ) {
            isDisliked.toggle()
        }
    }
    
    private var previousButton: some View {
        AnimatedIconButton(
            icon1: "backward",
            icon2: "backward",
            isActive: isPreviousActive,
            iconSize: 32
        ) {
            isPreviousActive.toggle()
        }
    }
    
    private var playPauseButton: some View {
        PlayPauseButton(isPlaying: isPlaying) {
            isPlaying.toggle()
        }
    }
    
    private var nextButton: some View {
        AnimatedIconButton(
            icon1: "forward",
            icon2: "forward",
            isActive: isNextActive,
            iconSize: 32
        ) {
            isNextActive.toggle()
        }
    }
    
    private var likeButton: some View {
        AnimatedIconButton(
            icon1: "like-default",
            icon2: "like-active",
            isActive: isLiked,
            iconSize: 24
        ) {
            isLiked.toggle()
            
            if isLiked {
                showHeartExplosion = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showHeartExplosion = false
                }
            }
        }
    }
    
    private var heartExplosionOverlay: some View {
        GeometryReader { geometry in
            Color.clear
                .overlay(
                    Group {
                        if showHeartExplosion {
                            HeartExplosionView(centerPosition: CGPoint(x: geometry.size.width * 0.68, y: geometry.size.height * 0.75))
                                .zIndex(1)
                        }
                    }
                )
        }
    }
}

#Preview {
    FullscreenPlayer()
}
