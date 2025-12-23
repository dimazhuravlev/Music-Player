import SwiftUI
import CoreHaptics

struct MiniPlayer: View {
    @Binding var isPlaying: Bool
    let track: Track
    var onTap: (() -> Void)?
    @State private var rotation: Double = 0
    @State private var lastUpdateTime: Date = Date()
    @State private var currentSpeed: Double = 0
    @State private var hapticEngine: CHHapticEngine?
    @State private var previousIsPlaying: Bool = false
    @State private var displayedCover: String = "album"
    @State private var coverOpacity: Double = 1
    @State private var isPressed: Bool = false
    private let targetSpeed: Double = 60 // degrees per second
    
    var body: some View {
        HStack(spacing: 20) {
            // Album art
            TimelineView(.animation) { timeline in
                Image(displayedCover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
                    .rotationEffect(.degrees(rotation))
                    .opacity(coverOpacity)
                    .onChange(of: timeline.date) { _, newTime in
                        let delta = newTime.timeIntervalSince(lastUpdateTime)
                        
                        // Manual interpolation for smooth acceleration/deceleration
                        let target = isPlaying ? targetSpeed : 0
                        currentSpeed += (target - currentSpeed) * 0.04
                        
                        rotation += currentSpeed * delta
                        rotation = rotation.truncatingRemainder(dividingBy: 360)
                        lastUpdateTime = newTime
                        
                        // Check for playback start to trigger haptic
                        if isPlaying && !previousIsPlaying {
                            playStartHaptic()
                        }
                        previousIsPlaying = isPlaying
                    }
                    .onChange(of: track.id) { _, _ in
                        withAnimation(.smooth(duration: 0.3)) {
                            coverOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            displayedCover = track.albumCover
                            withAnimation(.smooth(duration: 0.3)) {
                                coverOpacity = 1
                            }
                        }
                    }
            }
            
            // Animated play/pause icon
            AnimatedIconButton(
                icon1: "play",
                icon2: "pause",
                isActive: isPlaying,
                iconSize: 24
            ) {
                isPlaying.toggle()
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 20)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.01).blendMode(.overlay))
        .cornerRadius(72)
        .overlay(
            RoundedRectangle(cornerRadius: 72)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
        )
        .contentShape(RoundedRectangle(cornerRadius: 72))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.smooth(duration: 0.15), value: isPressed)
        .onTapGesture {
            onTap?()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.smooth(duration: 0.12)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.smooth(duration: 0.12)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            setupHapticEngine()
            displayedCover = track.albumCover
        }
    }
    
    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine stopping
            hapticEngine?.stoppedHandler = { [weak hapticEngine] reason in
                if reason == .audioSessionInterrupt || reason == .applicationSuspended {
                    do {
                        try hapticEngine?.start()
                    } catch {
                        print("Failed to restart haptic engine: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    private func playStartHaptic() {
        guard let engine = hapticEngine else { return }
        
        do {
            let parameters = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.40),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.30),
                CHHapticEventParameter(parameterID: .attackTime, value: 0.50),
                CHHapticEventParameter(parameterID: .decayTime, value: 0.30),
                CHHapticEventParameter(parameterID: .releaseTime, value: 0.60),
                CHHapticEventParameter(parameterID: .sustained, value: 1)
            ]
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: parameters,
                relativeTime: 0,
                duration: 0.50
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MiniPlayer(
            isPlaying: .constant(false),
            track: TrackDataManager.shared.getSampleTracks().first ?? Track(id: 0, title: "Track", artist: "Artist", albumCover: "album", releaseYear: 2024)
        ) {
            print("MiniPlayer tapped!")
        }
    }
}
