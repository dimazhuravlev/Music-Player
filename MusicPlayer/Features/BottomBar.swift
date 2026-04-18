import SwiftUI
import VariableBlur

struct BottomBar: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var collectionState: CollectionState
    @State private var isCardsPressed = false
    @State private var isShowcasePressed = false
    @Binding var activeTab: AppTab
    @Binding var playerGridIndex: GridIndex
    
    private let tabContainerSize: CGFloat = 72
    
    init(
        activeTab: Binding<AppTab> = .constant(.showcase),
        playerGridIndex: Binding<GridIndex> = .constant(GridIndex(x: 0, y: 0))
    ) {
        _activeTab = activeTab
        _playerGridIndex = playerGridIndex
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                MiniPlayer(
                    isPlaying: Binding(
                        get: { nowPlayingState.isPlaying },
                        set: { nowPlayingState.isPlaying = $0 }
                    ),
                    track: nowPlayingState.track
                ) {
                    triggerTabHaptic()
                    if activeTab == .player {
                        if let targetIndex = nowPlayingState.trackIndex {
                            playerGridIndex = targetIndex
                        }
                    } else {
                        withAnimation(.smooth(duration: 0.3)) {
                            activeTab = .player
                        }
                    }
                }
                .frame(width: tabContainerSize, height: tabContainerSize, alignment: .center)
                Spacer()
                
                // Showcase icon in the middle
                Image("showcase")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.fill1)
                    .frame(width: 48, height: 48)
                    .scaleEffect(isShowcasePressed ? 0.92 : 1.0)
                    .animation(.smooth(duration: 0.15), value: isShowcasePressed)
                    .onTapGesture {
                        // Switch to Showcase tab
                        triggerTabHaptic()
                        withAnimation(.smooth(duration: 0.3)) {
                            activeTab = .showcase
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.smooth(duration: 0.15)) {
                                    isShowcasePressed = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.smooth(duration: 0.15)) {
                                    isShowcasePressed = false
                                }
                            }
                    )
                    .frame(width: tabContainerSize, height: tabContainerSize, alignment: .center)
                
                Spacer()
                
                CollectionTabCovers(
                    previousCover: collectionState.previousCover,
                    latestCover: collectionState.latestCover,
                    isPressed: isCardsPressed,
                    previousCoverURL: collectionState.previousCoverURL,
                    latestCoverURL: collectionState.latestCoverURL
                )
                .onTapGesture {
                    // Switch to Collection tab
                    triggerTabHaptic()
                    withAnimation(.smooth(duration: 0.3)) {
                        activeTab = .collection
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // Scale down when pressed
                            withAnimation(.smooth(duration: 0.2)) {
                                isCardsPressed = true
                            }
                        }
                        .onEnded { _ in
                            // Scale back up when released
                            withAnimation(.smooth(duration: 0.2)) {
                                isCardsPressed = false
                            }
                        }
                )
                .frame(width: tabContainerSize, height: tabContainerSize, alignment: .center)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 40)
        }
        .background(alignment: .bottom) {
            if activeTab != .player {
                ZStack {
                    VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop)
                        .frame(height: 100)
                        .ignoresSafeArea()
                    
                    // Dark gradient overlay for better contrast
                    LinearGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: .black.opacity(0), location: 0.00),
                            Gradient.Stop(color: .black.opacity(0.07), location: 0.11),
                            Gradient.Stop(color: .black.opacity(0.13), location: 0.21),
                            Gradient.Stop(color: .black.opacity(0.18), location: 0.28),
                            Gradient.Stop(color: .black.opacity(0.24), location: 0.34),
                            Gradient.Stop(color: .black.opacity(0.29), location: 0.39),
                            Gradient.Stop(color: .black.opacity(0.34), location: 0.44),
                            Gradient.Stop(color: .black.opacity(0.39), location: 0.48),
                            Gradient.Stop(color: .black.opacity(0.44), location: 0.51),
                            Gradient.Stop(color: .black.opacity(0.49), location: 0.55),
                            Gradient.Stop(color: .black.opacity(0.53), location: 0.59),
                            Gradient.Stop(color: .black.opacity(0.58), location: 0.65),
                            Gradient.Stop(color: .black.opacity(0.63), location: 0.71),
                            Gradient.Stop(color: .black.opacity(0.69), location: 0.79),
                            Gradient.Stop(color: .black.opacity(0.74), location: 0.88),
                            Gradient.Stop(color: .black.opacity(0.8), location: 1.00),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .ignoresSafeArea()
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func triggerTabHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred(intensity: 0.7)
    }
    

}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BottomBar()
            .environmentObject(NowPlayingState())
            .environmentObject(CollectionState())
    }
}

// MARK: - Collection tab covers

private struct CollectionTabCovers: View {
    let previousCover: String?
    let latestCover: String?
    let isPressed: Bool
    var previousCoverURL: URL? = nil
    var latestCoverURL: URL? = nil
    
    private let size: CGFloat = 48
    private let baseTransitionDuration: Double = 0.35
    private let basePressDuration: Double = 0.15
    private let baseFadeDuration: Double = 0.2
    private let baseIncomingDelay: Double = 0.05
    private let baseIncomingYOffset: CGFloat = 40
    private let baseIncomingRotationOffset: Double = 24
    private let animationSlowdown: Double = 1.4 // Slightly slower across transitions
    
    private var transitionDuration: Double { baseTransitionDuration * animationSlowdown }
    private var pressDuration: Double { basePressDuration * animationSlowdown }
    private var fadeDuration: Double { baseFadeDuration * animationSlowdown }
    private var incomingDelay: Double { baseIncomingDelay * animationSlowdown }
    private var shiftSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }
    @State private var leftVisible: String = "album"
    @State private var leftVisibleURL: URL? = nil
    @State private var rightVisible: String = "album"
    @State private var rightVisibleURL: URL? = nil
    @State private var incomingCover: String?
    @State private var incomingCoverURL: URL? = nil
    @State private var incomingOpacity: Double = 0
    @State private var incomingYOffset: CGFloat = -32
    @State private var incomingRotation: Double = 0
    @State private var leftOpacity: Double = 1
    @State private var rightMovesToLeft = false
    @State private var isTransitioning = false
    
    var body: some View {
        let leftTransform = transform(for: .left)
        let rightTransform = transform(for: rightMovesToLeft ? .left : .right)
        
        return ZStack {
            angledCover(
                name: leftVisible,
                rotation: leftTransform.rotation,
                xOffset: leftTransform.x,
                yOffset: leftTransform.y,
                opacity: leftOpacity,
                z: 0,
                imageURL: leftVisibleURL
            )

            angledCover(
                name: rightVisible,
                rotation: rightTransform.rotation,
                xOffset: rightTransform.x,
                yOffset: rightTransform.y,
                z: 1,
                imageURL: rightVisibleURL
            )
            
            if let incomingCover {
                let incomingTransform = transform(for: .right)
                angledCover(
                    name: incomingCover,
                    rotation: incomingRotation,
                    xOffset: incomingTransform.x,
                    yOffset: incomingTransform.y + incomingYOffset,
                    opacity: incomingOpacity,
                    z: 2,
                    imageURL: incomingCoverURL
                )
            }
        }
        .animation(.smooth(duration: pressDuration), value: isPressed)
        .onChange(of: latestCoverURL) { newURL in
            guard newURL != nil else { return }
            startCoverTransition(newLatest: latestCover ?? "album", newLatestURL: newURL)
        }
        .onChange(of: previousCoverURL) { _ in
            guard !isTransitioning else { return }
            if previousCoverURL != leftVisibleURL {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    leftVisible = previousCover ?? "album"
                    leftVisibleURL = previousCoverURL
                }
            }
        }
        .onAppear {
            leftVisible = previousCover ?? "album"
            leftVisibleURL = previousCoverURL
            rightVisible = latestCover ?? "album"
            rightVisibleURL = latestCoverURL
        }
    }
    
    @ViewBuilder
    private func angledCover(
        name: String,
        rotation: Double,
        xOffset: CGFloat,
        yOffset: CGFloat,
        opacity: Double = 1,
        z: Double = 0,
        imageURL: URL? = nil
    ) -> some View {
        CachedAsyncImage(url: imageURL, assetName: name)
            .frame(width: size, height: size)
            .cornerRadius(8)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.fill1, lineWidth: 2)
            )
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .zIndex(z)
    }
    
    private enum CoverSlot {
        case left
        case right
    }
    
    private func transform(for slot: CoverSlot) -> (rotation: Double, x: CGFloat, y: CGFloat) {
        switch slot {
        case .left:
            return isPressed
            ? (-14, -14, 4)
            : (-10, -10, 4)
        case .right:
            return isPressed
            ? (14, 16, -2)
            : (10, 12, -2)
        }
    }
    
    private func startCoverTransition(newLatest: String, newLatestURL: URL? = nil) {
        guard !isTransitioning else { return }
        isTransitioning = true

        let outgoingRight = rightVisible
        let outgoingRightURL = rightVisibleURL
        incomingCover = newLatest
        incomingCoverURL = newLatestURL ?? latestCoverURL
        incomingOpacity = 0
        incomingYOffset = -baseIncomingYOffset
        incomingRotation = transform(for: .right).rotation + baseIncomingRotationOffset
        leftOpacity = 1
        rightMovesToLeft = false
        
        DispatchQueue.main.async {
            withAnimation(shiftSpring) {
                rightMovesToLeft = true
                leftOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + incomingDelay) {
                withAnimation(shiftSpring) {
                    incomingOpacity = 1
                    incomingYOffset = 0
                    incomingRotation = transform(for: .right).rotation
                }
            }
            
            let completionDelay = incomingDelay + transitionDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                // Swap state without animation to avoid flash/flicker
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    leftVisible = outgoingRight
                    leftVisibleURL = outgoingRightURL
                    rightVisible = newLatest
                    rightVisibleURL = newLatestURL ?? latestCoverURL
                    leftOpacity = 1
                    rightMovesToLeft = false
                    incomingCover = nil
                    incomingOpacity = 0
                    incomingYOffset = -baseIncomingYOffset
                    incomingRotation = transform(for: .right).rotation
                    isTransitioning = false
                }
            }
        }
    }
}

