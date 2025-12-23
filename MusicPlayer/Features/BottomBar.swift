import SwiftUI
import VariableBlur

struct BottomBar: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var collectionState: CollectionState
    @State private var isPlaying = false
    @State private var isCardsPressed = false
    @State private var isShowcasePressed = false
    @Binding var activeTab: AppTab
    
    init(activeTab: Binding<AppTab> = .constant(.showcase)) {
        _activeTab = activeTab
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                MiniPlayer(
                    isPlaying: $isPlaying,
                    track: nowPlayingState.track
                ) {
                    // Switch to player tab
                    triggerTabHaptic()
                    withAnimation(.smooth(duration: 0.3)) {
                        activeTab = .player
                    }
                }
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
                
                Spacer()
                
                CollectionTabCovers(
                    previousCover: collectionState.previousCover,
                    latestCover: collectionState.latestCover,
                    isPressed: isCardsPressed
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
            }
            .padding(.leading, 16)
            .padding(.trailing, 32)
            .padding(.bottom, 40)
        }
        .background (alignment: .bottom) {
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
    
    private let size: CGFloat = 44
    @State private var leftVisible: String = "Ruqya"
    @State private var rightVisible: String = "blur"
    @State private var leftOverlay: String?
    @State private var rightOverlay: String?
    @State private var leftOverlayOpacity: Double = 0
    @State private var rightOverlayOpacity: Double = 0
    
    var body: some View {
        ZStack {
            angledCover(
                visibleName: leftVisible,
                overlayName: leftOverlay,
                overlayOpacity: leftOverlayOpacity,
                rotation: isPressed ? -14 : -10,
                xOffset: isPressed ? -14 : -10,
                yOffset: isPressed ? 4 : 4
            )
            
            angledCover(
                visibleName: rightVisible,
                overlayName: rightOverlay,
                overlayOpacity: rightOverlayOpacity,
                rotation: isPressed ? 14 : 10,
                xOffset: isPressed ? 16 : 12,
                yOffset: isPressed ? -2 : -2
            )
        }
        .animation(.smooth(duration: 0.15), value: isPressed)
        .onChange(of: previousCover) { newValue in
            startOverlay(isLeft: true, target: newValue ?? "Ruqya")
        }
        .onChange(of: latestCover) { newValue in
            startOverlay(isLeft: false, target: newValue ?? "blur")
        }
        .onAppear {
            leftVisible = previousCover ?? "Ruqya"
            rightVisible = latestCover ?? "blur"
        }
    }
    
    @ViewBuilder
    private func angledCover(
        visibleName: String,
        overlayName: String?,
        overlayOpacity: Double,
        rotation: Double,
        xOffset: CGFloat,
        yOffset: CGFloat
    ) -> some View {
        ZStack {
            Image(visibleName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .cornerRadius(8)
            
            if let overlayName {
                Image(overlayName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .cornerRadius(8)
                    .opacity(overlayOpacity)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.fill1, lineWidth: 2)
        )
        .rotationEffect(.degrees(rotation))
        .offset(x: xOffset, y: yOffset)
    }
    
    private func startOverlay(isLeft: Bool, target: String) {
        if isLeft {
            leftOverlay = target
            leftOverlayOpacity = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                leftOverlayOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                leftVisible = target
                leftOverlay = nil
                leftOverlayOpacity = 0
            }
        } else {
            rightOverlay = target
            rightOverlayOpacity = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                rightOverlayOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                rightVisible = target
                rightOverlay = nil
                rightOverlayOpacity = 0
            }
        }
    }
}
