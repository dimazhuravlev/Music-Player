import SwiftUI

struct PlayPauseButton: View {
    let isPlaying: Bool
    let onTap: () -> Void
    
    @State private var backgroundScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Round background
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 64, height: 64)
                .scaleEffect(backgroundScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: backgroundScale)
            
            // Central icon
            AnimatedIconButton(
                icon1: "play",
                icon2: "pause",
                isActive: isPlaying,
                iconSize: 32
            ) {
                // Scale down background
                backgroundScale = 0.8
                
                // Trigger the main action
                onTap()
                
                // Scale back up after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    backgroundScale = 1.0
                }
            }
        }
    }
}