import SwiftUI
import CoreHaptics

struct MiniPlayer: View {
    @Binding var isPlaying: Bool
    let track: Track
    var onTap: (() -> Void)?
    @ObservedObject private var audioPlayer = AudioPlayerManager.shared
    @State private var rotation: Double = 0
    @State private var lastUpdateTime: Date = Date()
    @State private var currentSpeed: Double = 0
    @State private var hapticEngine: CHHapticEngine?
    @State private var previousIsPlaying: Bool = false
    @State private var displayedCover: String = "album"
    @State private var displayedCoverURL: URL? = nil
    @State private var coverOpacity: Double = 1
    @State private var isPressed: Bool = false
    private let targetSpeed: Double = 40 // degrees per second
    
    var body: some View {
        TimelineView(.animation) { timeline in
            CachedAsyncImage(url: displayedCoverURL, assetName: displayedCover)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
                .opacity(coverOpacity)
                .overlay {
                    ZStack {
                        // Background timeline ring (behind progress but above cover)
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: audioPlayer.progress)
                            .stroke(
                                Color.white,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .opacity(1)
                    }
                    .frame(width: 58, height: 58)
                }
                .frame(width: 68, height: 68)
            .onChange(of: timeline.date) { _, newTime in
                let delta = newTime.timeIntervalSince(lastUpdateTime)
                
                // Manual interpolation for smooth acceleration/deceleration
                let target = isPlaying ? targetSpeed : 0
                currentSpeed += (target - currentSpeed) * 0.04
                
                rotation += currentSpeed * delta
                rotation = rotation.truncatingRemainder(dividingBy: 360)
                lastUpdateTime = newTime

                // On play start: jump to full speed immediately so rotation is visible right away.
                // Smooth lerp is kept for deceleration (spin-down) when pausing.
                if isPlaying && !previousIsPlaying {
                    currentSpeed = targetSpeed
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
                    displayedCoverURL = track.albumCoverURL
                    withAnimation(.smooth(duration: 0.3)) {
                        coverOpacity = 1
                    }
                }
            }
            .contentShape(Circle())
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
        }
        .onAppear {
            setupHapticEngine()
            displayedCover = track.albumCover
            displayedCoverURL = track.albumCoverURL
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
