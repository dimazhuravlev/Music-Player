import SwiftUI
import UIKit
import AVFoundation

/// Renders video via `AVPlayerLayer` only — no `VideoPlayer` transport controls on tap.
private struct ShaderVideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PlayerLayerContainerView else { return }
        view.playerLayer.player = player
        view.playerLayer.frame = view.bounds
    }
}

private final class PlayerLayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// Manages a shared shader player so it isn't recreated on every tab visit
final class ShaderPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    
    private var looper: AVPlayerLooper?
    private var isPrepared = false
    private(set) var hasStartedPlayback = false
    
    func prepareIfNeeded() {
        guard !isPrepared else { return }
        isPrepared = true
        
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            guard let asset = NSDataAsset(name: "Shader") else {
                await MainActor.run { self.isPrepared = false }
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Shader.mov")
            
            do {
                try asset.data.write(to: tempURL)
                let item = AVPlayerItem(url: tempURL)
                
                await MainActor.run {
                    let queuePlayer = AVQueuePlayer(items: [item])
                    queuePlayer.actionAtItemEnd = .none
                    
                    self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
                    self.player = queuePlayer
                }
            } catch {
                await MainActor.run { self.isPrepared = false }
            }
        }
    }
    
    func play() {
        prepareIfNeeded()
        // Deferred so it runs after any synchronous pause() from the previous view's onDisappear
        // in the same run loop (e.g. For You → Offline swap); otherwise pause can win after play.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.player?.play()
            self.hasStartedPlayback = true
        }
    }
    
    func pause() {
        if Thread.isMainThread {
            player?.pause()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player?.pause()
            }
        }
    }
}

struct VideoBackgroundView: View {
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    @EnvironmentObject private var offlineModeState: OfflineModeState
    let refreshOffset: CGFloat
    let isDragging: Bool
    @State private var isVisible: Bool = true
    @State private var shaderOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Fallback background
            Color.black
                .ignoresSafeArea()

            // Video player - only show when visible and reduce resource usage
            if let player = shaderPlayer.player, isVisible {
                // AVPlayerLayer uses a separate render path on device; tint must composite in the
                // same SwiftUI group as the video (not full-screen), or blendMode sees the wrong
                // backdrop and reads as a flat purple layer. Screenshots use a different composite.
                ZStack {
                    ShaderVideoLayerView(player: player)
                        .aspectRatio(1, contentMode: .fill)

                    if offlineModeState.isEnabled {
                        Color(red: 163 / 255, green: 50 / 255, blue: 1)
                            .blendMode(.color)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: 300, height: 300)
                .clipped()
                .compositingGroup()
                .allowsHitTesting(false)
                .offset(
                    x: 0,
                    y: -120 - shaderOffset
                )
                .onChange(of: refreshOffset) { newValue in
                    // Only update shader offset during active drag
                    if isDragging {
                        shaderOffset = newValue
                    }
                }
                .onChange(of: isDragging) { newValue in
                    if !newValue {
                        // When drag ends, smoothly return shader to base position
                        withAnimation(.easeOut(duration: 0.3)) {
                            shaderOffset = 0
                        }
                    }
                }
                .ignoresSafeArea()
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
            }
        }
        .onAppear {
            shaderPlayer.prepareIfNeeded()
            isVisible = true
            // If player is already prepared, start immediately
            if shaderPlayer.player != nil {
                shaderPlayer.play()
            }
        }
        .onDisappear {
            isVisible = false
            shaderPlayer.pause()
        }
        .onChange(of: shaderPlayer.player) { newPlayer in
            // Auto-start once player becomes available and view is visible
            guard newPlayer != nil, isVisible else { return }
            shaderPlayer.play()
        }
    }
}

struct Generator: View {
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    let tracks: [Track]
    let refreshOffset: CGFloat
    let blurRadius: CGFloat
    let hasTriggeredFinalHaptic: Bool
    let isRefreshing: Bool
    let refreshBlurRadius: CGFloat
    
    @State private var currentIndex = 0
    @State private var selectedFilter: String? = nil
    @State private var isPlaying = false
    @State private var statusScale: CGFloat = 1.0
    
    private let filters = ["Post-Punk", "Shoegaze", "Noise Rock", "Post-Rock", "Hardcore", "Krautrock", "Art Rock", "Grunge", "IDM", "Dream Pop", "No Wave"]
    
    // Calculate opacity for refresh status based on pull distance
    private var refreshStatusOpacity: Double {
        // If refreshing, keep status fully visible
        if isRefreshing {
            return 1.0
        }
        
        // Start appearing when refreshOffset > 10, fully visible at refreshOffset = 40
        let minOffset: CGFloat = 10
        let maxOffset: CGFloat = 40
        
        if refreshOffset < minOffset {
            return 0
        } else if refreshOffset >= maxOffset {
            return 1
        } else {
            // Smooth interpolation between min and max
            let progress = (refreshOffset - minOffset) / (maxOffset - minOffset)
            return Double(progress)
        }
    }
    
    // Calculate blur radius for refresh status (inverse of opacity: 12 → 0)
    private var refreshStatusBlur: CGFloat {
        // If refreshing, no blur
        if isRefreshing {
            return 0
        }
        // When opacity is 0, blur is 12; when opacity is 1, blur is 0
        return CGFloat(12 * (1 - refreshStatusOpacity))
    }
    
    // Calculate vertical offset for refresh status (starts at 32px down, moves to 0)
    private var refreshStatusVerticalOffset: CGFloat {
        // If refreshing, keep status at center position
        if isRefreshing {
            return 0
        }
        
        // Start appearing when refreshOffset > 10, fully visible at refreshOffset = 40
        let minOffset: CGFloat = 10
        let maxOffset: CGFloat = 40
        
        if refreshOffset < minOffset {
            return 32 // Start 32px down
        } else if refreshOffset >= maxOffset {
            return 0 // End at center position
        } else {
            // Smooth interpolation: 32 → 0
            let progress = (refreshOffset - minOffset) / (maxOffset - minOffset)
            return 32 * (1 - progress)
        }
    }
    
    // Calculate opacity for track carousel (fades out when refreshing)
    private var carouselOpacity: Double {
        // If refreshing or blur is active, fade out completely
        if isRefreshing || refreshBlurRadius > 0 {
            return 0
        }
        // Otherwise fully visible
        return 1.0
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background video shader
            VideoBackgroundView(
                shaderPlayer: shaderPlayer,
                refreshOffset: refreshOffset,
                isDragging: !isRefreshing && refreshOffset > 0
            )

            VStack(alignment: .leading, spacing: 8) {
            // Header with title and play button
            HStack {
                Text("My Vibe")
                    .font(.Headline1)
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    
                    AnimatedIconButton(
                        icon1: "play",
                        icon2: "pause",
                        isActive: isPlaying,
                        iconSize: 24,
                        iconColor: .black,
                        onTap: {
                            isPlaying.toggle()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Filter carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = selectedFilter == filter ? nil : filter
                        }) {
                            Text(filter)
                                .font(.Text1)
                                .foregroundColor(selectedFilter == filter ? .black : .white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 56)
                                        .fill(selectedFilter == filter ? Color.white : Color.white.opacity(0.1))
                                        .background(.thinMaterial.opacity(0.15), in: RoundedRectangle(cornerRadius: 56))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Track carousel with overlay status
            ZStack {
                TrackCarouselView(tracks: tracks, blurRadius: blurRadius, onTrackLongPress: { track in
                                    overflowMenuState.present(ShareableEntity(
                                        title: track.title,
                                        subtitle: track.artist,
                                        year: track.releaseYear,
                                        coverImageName: track.albumCover,
                                        artistImageName: nil,
                                        coverImageURL: track.albumCoverURL,
                                        artistImageURL: track.artistThumbnailURL
                                    ))
                                })
                    .opacity(carouselOpacity)
                    .animation(.easeOut(duration: 0.3), value: isRefreshing)
                
                // Refresh status text (appears during pull-to-refresh, overlays the carousel)
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 2) {
                        Text("Refreshing")
                            .font(.Text1)
                            .foregroundColor(.white)
                        
                        Text("My Vibe AI-playlist")
                            .font(.Text1)
                            .foregroundColor(.white)
                    }
                }
                .opacity(refreshStatusOpacity)
                .blur(radius: refreshStatusBlur)
                .offset(y: refreshStatusVerticalOffset) // Starts 16px down, moves to center (0)
                .scaleEffect(statusScale)
                .animation(.easeOut(duration: 0.3), value: refreshOffset)
            }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 220)
        }
        .onChange(of: hasTriggeredFinalHaptic) { newValue in
            if newValue {
                // Trigger blink animation: 1 → 1.2 → 1 in 300ms
                withAnimation(.easeInOut(duration: 0.1)) {
                    statusScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        statusScale = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    Generator(
        shaderPlayer: ShaderPlayerManager(),
        tracks: TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 },
        refreshOffset: 0,
        blurRadius: 0,
        hasTriggeredFinalHaptic: false,
        isRefreshing: false,
        refreshBlurRadius: 0
    )
    .environmentObject(OverflowMenuState())
    .background(Color.black)
}
