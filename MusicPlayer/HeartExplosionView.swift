import SwiftUI

struct HeartExplosionView: View {
    // MARK: - Configuration
    private let heartCount = Int.random(in: 20...30)  // Number of hearts
    private let appearanceRadius: ClosedRange<CGFloat> = 50...80  // Where hearts appear around button
    private let explosionRadius: ClosedRange<CGFloat> = 20...100   // How far hearts move outward
    private let heartSize: ClosedRange<CGFloat> = 24...24        // Size range of heart particles
    private let rotationAmount: ClosedRange<Double> = 45...90    // Rotation range for hearts
    
    // MARK: - Timing
    private let animationDuration: Double = 1                    // Total animation duration
    private let movementDuration: Double = 0.4                   // Duration of movement phase
    private let appearDelayRange: ClosedRange<Double> = 0...0.2  // Random delay before heart appears
    private let disappearDelayRange: ClosedRange<Double> = 0...0.3  // Random delay before heart disappears
    
    // MARK: - Properties
    let centerPosition: CGPoint  // Center position of the explosion (like button)
    @State private var hearts: [HeartParticle] = []  // Array of heart particles
    
    struct HeartParticle: Identifiable {
        let id = UUID()
        var startPosition: CGSize  // Where heart appears
        var endPosition: CGSize    // Where heart moves to
        var size: CGFloat
        var opacity: Double
        var blur: Double           // Blur amount for disappear animation
        var rotation: Double
        var appearDelay: Double
        var disappearDelay: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(hearts) { heart in
                Image("like-active")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: heart.size, height: heart.size)
                    .opacity(heart.opacity)
                    .rotationEffect(.degrees(heart.rotation))
                    .blur(radius: heart.blur)  // Add blur effect
                    .position(centerPosition)
                    .offset(heart.startPosition)
                    .animation(.smooth(duration: movementDuration), value: heart.startPosition)
                    .animation(.smooth(duration: animationDuration), value: heart.rotation)
                    .animation(.smooth(duration: animationDuration), value: heart.size)
                    .animation(.smooth(duration: animationDuration), value: heart.blur)  // Animate blur
            }
        }
        .zIndex(-1000)  // Force below album cover
        .onAppear {
            startExplosion()
        }
    }
    
    private func startExplosion() {
        createHearts()
        animateHearts()
    }
    
    private func createHearts() {
        hearts = (0..<heartCount).map { _ in
            // Create more chaotic final positions
            let endAngle = Double.random(in: 0...(2 * .pi))  // Random angle for final position
            let explodeRadius = CGFloat.random(in: explosionRadius)  // Random distance from center
            
            // Add some randomness to the final position
            let randomOffsetX = CGFloat.random(in: -30...30)  // Random X offset for chaos
            let randomOffsetY = CGFloat.random(in: -30...30)  // Random Y offset for chaos
            
            return HeartParticle(
                startPosition: CGSize.zero,  // Start from center (like button)
                endPosition: CGSize(
                    width: cos(endAngle) * explodeRadius + randomOffsetX,
                    height: sin(endAngle) * explodeRadius + randomOffsetY
                ),
                size: CGFloat.random(in: heartSize),
                opacity: 0.0,
                blur: 0.0,  // Start with no blur
                rotation: Double.random(in: -180...180),
                appearDelay: Double.random(in: appearDelayRange),
                disappearDelay: Double.random(in: disappearDelayRange)
            )
        }
    }
    
    private func animateHearts() {
        // Appear and start moving
        hearts.indices.forEach { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + hearts[index].appearDelay) {
                hearts[index].opacity = 0.3
                
                // Move from start position to end position
                hearts[index].startPosition = hearts[index].endPosition
                hearts[index].rotation += Double.random(in: rotationAmount)
            }
        }
        
        // Disappear after movement is complete with random timing
        hearts.indices.forEach { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + hearts[index].appearDelay + movementDuration + hearts[index].disappearDelay) {
                hearts[index].opacity = 0.0
                hearts[index].size = 8  // Scale down during disappear
                hearts[index].blur = 12  // Add blur during disappear
            }
        }
    }
}