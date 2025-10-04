import SwiftUI

struct PlayPauseButton: View {
    let isPlaying: Bool
    let onTap: () -> Void
    let size: CGFloat
    
    @State private var backgroundScale: CGFloat = 1.0
    
    // Convenience initializer with default size for backward compatibility
    init(isPlaying: Bool, onTap: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.onTap = onTap
        self.size = 64 // Default size for player
    }
    
    // Full initializer with custom size
    init(isPlaying: Bool, size: CGFloat, onTap: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.onTap = onTap
        self.size = size
    }
    
    private var iconSize: CGFloat {
        size * 0.5 // Icon is half the button size
    }
    
    var body: some View {
        ZStack {
            // Round background
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size, height: size)
                .scaleEffect(backgroundScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: backgroundScale)
            
            // Central icon
            AnimatedIconButton(
                icon1: "play",
                icon2: "pause",
                isActive: isPlaying,
                iconSize: iconSize
            ) {
                // Scale down background
                backgroundScale = 0.8
                
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred(intensity: 1.0)
                
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