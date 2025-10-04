import SwiftUI

struct AnimatedIconButton: View {
    let icon1: String
    let icon2: String
    let isActive: Bool
    let iconSize: CGFloat
    let iconColor: Color
    let onTap: () -> Void
    
    @State private var iconOpacity: Double = 1.0
    @State private var iconScale: Double = 1.0
    
    // Convenience initializer with default size and color
    init(icon1: String, icon2: String, isActive: Bool, iconSize: CGFloat = 24, iconColor: Color = .fill1, onTap: @escaping () -> Void) {
        self.icon1 = icon1
        self.icon2 = icon2
        self.isActive = isActive
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.onTap = onTap
    }
    
    var body: some View {
        ZStack {
            // First icon (shows when isActive is false)
            Image(icon1)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(iconColor)
                .frame(width: iconSize, height: iconSize)
                .opacity(isActive ? 0 : iconOpacity)
                .scaleEffect(isActive ? 0.4 : iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: isActive)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: iconOpacity)
            
            // Second icon (shows when isActive is true)
            Image(icon2)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(iconColor)
                .frame(width: iconSize, height: iconSize)
                .opacity(isActive ? iconOpacity : 0)
                .scaleEffect(isActive ? iconScale : 0.4)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: isActive)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.5), value: iconOpacity)
        }
        .onTapGesture {
            // Add haptic feedback for play/pause and like buttons
            if (icon1 == "play" && icon2 == "pause") || (icon1 == "pause" && icon2 == "play") ||
               (icon1 == "like-default" && icon2 == "like-active") {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred(intensity: 1.0)
            }
            
            // Step 1: Fade out and scale down current icon
            iconOpacity = 0
            iconScale = 0.4
            
            // Step 2: Toggle state and animate new icon in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onTap()
                iconOpacity = 1.0
                iconScale = 1.0
            }
        }
    }
}
