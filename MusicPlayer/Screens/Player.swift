import SwiftUI

struct Player: View {
    @State private var isPlaying = false
    @State private var isPreviousActive = false
    @State private var isNextActive = false
    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var showHeartExplosion = false
    @State private var albumTapScale: CGFloat = 1.0
    @State private var albumLongTapScale: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            backgroundView
            mainContent
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                        isDragging = true
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = 200
                    if value.translation.height > threshold || value.velocity.height > 500 {
                        // Dismiss the player
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = 1000 // Large offset to dismiss
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            dismiss?()
                        }
                    } else {
                        // Snap back to original position
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
    }
    
    private var backgroundView: some View {
        Image("album")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .blur(radius: 80)
            .overlay(Color.black.opacity(0.3).ignoresSafeArea())
            .opacity(1.0 - (dragOffset / 1000) * 0.5)
    }
    
    private var mainContent: some View {
        VStack(spacing: 48) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.6))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
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
                ToastManager.shared.show(title: ToastCopy.randomLikeTitle(), cover: "album")
            }
        }
    }
    
    private var heartExplosionOverlay: some View {
        GeometryReader { geometry in
            Color.clear
                .overlay(
                    Group {
                        if showHeartExplosion {
                            HeartExplosionView(centerPosition: CGPoint(x: geometry.size.width * 0.68, y: geometry.size.height * 0.78))
                                .zIndex(1)
                        }
                    }
                )
        }
    }
}

#Preview {
    Player()
}
