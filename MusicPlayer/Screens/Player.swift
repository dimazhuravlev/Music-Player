#if os(iOS)
import UIKit
#endif
import SwiftUI

/// Minimal 2D pager that mirrors TikTok/Reels mechanics using only position offsets.
/// - Renders exactly two slides at any time: the current slide and the neighbor
///   in the active swipe direction.
/// - Uses a single DragGesture with early axis lock, 1:1 finger tracking, and
///   predicted end translation to decide commits.
struct Player: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var collectionState: CollectionState
    @Binding var activeTab: AppTab
    
    @State private var current = GridIndex(x: 0, y: 0)
    @State private var dragOffset: CGSize = .zero
    @State private var lockedAxis: SwipeAxis?
    @State private var likedIndices: Set<GridIndex> = []
    
    private static var trackCache: [GridIndex: Track] = [:]
    
    private let commitDuration: TimeInterval = 0.3
    private let lockThreshold: CGFloat = 8
    private let likeButtonSize: CGFloat = 40
    
    init(activeTab: Binding<AppTab> = .constant(.player)) {
        _activeTab = activeTab
    }
    
    var body: some View {
        GeometryReader { proxy in
            let screenSize = proxy.size
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Two-slide stack: current and optional neighbor in the drag direction.
                ZStack {
                    slideView(for: current)
                        .offset(alignedOffset(for: dragOffset, axis: lockedAxis))
                    
                    if let neighbor = neighborInfo(for: screenSize) {
                        slideView(for: neighbor.index)
                            .offset(neighbor.offset)
                    }
                }
                .contentShape(Rectangle()) // Needed so the gesture covers the full screen.
                .gesture(dragGesture(screenSize: screenSize))
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    // MARK: - Views
    
    private func slideView(for index: GridIndex) -> some View {
        let track = track(for: index)
        
        return ZStack {
            blurredCoverBackground(for: track)
            
            VStack(spacing: 12) {
                Spacer()
                
                Image(track.albumCover)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        nowPlayingState.track = track
                    }
                
                trackHeader(for: index, track: track)
                
                Spacer()
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
    
    // MARK: - Gesture
    
    private func dragGesture(screenSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Lock the axis once movement is meaningful and keep it fixed.
                if lockedAxis == nil {
                    let absX = abs(value.translation.width)
                    let absY = abs(value.translation.height)
                    let largest = max(absX, absY)
                    if largest > lockThreshold {
                        lockedAxis = absX > absY ? .horizontal : .vertical
                    } else {
                        dragOffset = .zero
                        return
                    }
                }
                
                guard let axis = lockedAxis else { return }
                
                let primary = primaryValue(from: value.translation, axis: axis)
                let direction = directionFor(primary: primary, axis: axis)
                let neighborExists = direction.flatMap { neighborIndex(for: $0) } != nil
                let adjustedPrimary = neighborExists ? primary : primary * 0.25 // Resistance at edges.
                
                dragOffset = axis == .horizontal
                    ? CGSize(width: adjustedPrimary, height: 0)
                    : CGSize(width: 0, height: adjustedPrimary)
            }
            .onEnded { value in
                guard let axis = lockedAxis else {
                    dragOffset = .zero
                    return
                }
                
                let primary = primaryValue(from: value.translation, axis: axis)
                let predicted = primaryValue(from: value.predictedEndTranslation, axis: axis)
                let direction = directionFor(primary: primary, axis: axis)
                let neighbor = direction.flatMap { neighborIndex(for: $0) }
                let span = axis == .horizontal ? screenSize.width : screenSize.height
                let threshold = span * 0.2
                let shouldCommit = neighbor != nil && (abs(primary) > threshold || abs(predicted) > threshold)
                
                let targetPrimary: CGFloat
                if shouldCommit, let dir = direction {
                    targetPrimary = (dir == .left || dir == .up) ? -span : span
                } else {
                    targetPrimary = 0
                }
                
                let targetOffset = axis == .horizontal
                    ? CGSize(width: targetPrimary, height: 0)
                    : CGSize(width: 0, height: targetPrimary)
                
                if shouldCommit {
                    triggerSwipeHaptic(for: axis)
                }
                
                withAnimation(.easeInOut(duration: commitDuration)) {
                    dragOffset = targetOffset
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + commitDuration) {
                    if shouldCommit, let next = neighbor {
                        current = next
                    }
                    dragOffset = .zero
                    lockedAxis = nil
                }
            }
    }
    
    // MARK: - Neighboring logic
    
    private func neighborInfo(for screenSize: CGSize) -> (index: GridIndex, offset: CGSize)? {
        guard let axis = lockedAxis else { return nil }
        let direction = directionFor(primary: primaryValue(from: dragOffset, axis: axis), axis: axis)
        guard let dir = direction, let neighborIndex = neighborIndex(for: dir) else { return nil }
        
        let base = alignedOffset(for: dragOffset, axis: axis)
        let offset: CGSize
        switch dir {
        case .left:
            offset = CGSize(width: base.width + screenSize.width, height: 0)
        case .right:
            offset = CGSize(width: base.width - screenSize.width, height: 0)
        case .up:
            offset = CGSize(width: 0, height: base.height + screenSize.height)
        case .down:
            offset = CGSize(width: 0, height: base.height - screenSize.height)
        }
        return (neighborIndex, offset)
    }
    
    private func neighborIndex(for direction: SwipeDirection) -> GridIndex? {
        var candidate = current
        switch direction {
        case .left:
            candidate.x -= 1
        case .right:
            candidate.x += 1
        case .up:
            candidate.y -= 1
        case .down:
            candidate.y += 1
        }
        return candidate // Unbounded grid in all directions.
    }
    
    // MARK: - Helpers
    
    private func alignedOffset(for offset: CGSize, axis: SwipeAxis?) -> CGSize {
        guard let axis else { return .zero }
        return axis == .horizontal ? CGSize(width: offset.width, height: 0) : CGSize(width: 0, height: offset.height)
    }
    
    private func blurredCoverBackground(for track: Track) -> some View {
        GeometryReader { proxy in
            Image(track.albumCover)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(1.3)
                .blur(radius: 80)
                .overlay(Color.black.opacity(0.4))
                .clipped()
                .allowsHitTesting(false)
        }
    }
    
    private func trackHeader(for index: GridIndex, track: Track) -> some View {
        HStack(spacing: 12) {
            Text(track.title)
                .font(.Headline3)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            likeButton(for: index, track: track)
        }
        .frame(width: 260, alignment: .leading)
    }
    
    private func likeButton(for index: GridIndex, track: Track) -> some View {
        let isLiked = likedIndices.contains(index)
        
        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: likeButtonSize, height: likeButtonSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
                )
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            
            AnimatedIconButton(
                icon1: "like-default",
                icon2: "like-active",
                isActive: isLiked,
                iconSize: 20
            ) {
                handleLikeTap(for: index, track: track)
            }
        }
        .frame(width: likeButtonSize, height: likeButtonSize)
        .contentShape(Circle())
    }
    
    private func handleLikeTap(for index: GridIndex, track: Track) {
        if likedIndices.contains(index) {
            likedIndices.remove(index)
            return
        }
        
        likedIndices.insert(index)
        
        ToastManager.shared.show(title: ToastCopy.randomLikeTitle(), cover: track.albumCover)
        collectionState.registerLike(coverName: track.albumCover)
    }
    
    private func primaryValue(from translation: CGSize, axis: SwipeAxis) -> CGFloat {
        axis == .horizontal ? translation.width : translation.height
    }
    
    private func directionFor(primary: CGFloat, axis: SwipeAxis) -> SwipeDirection? {
        guard primary != 0 else { return nil }
        if axis == .horizontal {
            return primary < 0 ? .left : .right
        } else {
            return primary < 0 ? .up : .down
        }
    }
    
    private func triggerSwipeHaptic(for axis: SwipeAxis) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.7)
        #endif
    }
    
    private func track(for index: GridIndex) -> Track {
        let tracks = TrackDataManager.shared.getSampleTracks()
        guard !tracks.isEmpty else {
            return Track(id: 0, title: "Track", artist: "Artist", albumCover: "album", releaseYear: 2024)
        }
        
        if let cached = Self.trackCache[index] {
            return cached
        }
        
        // Deterministic random track per grid position so each slide stays stable.
        let seed = UInt64(bitPattern: Int64(index.x &* 73856093 ^ index.y &* 19349663))
        var generator = SeededGenerator(seed: seed)
        let pickedIndex = Int.random(in: 0..<tracks.count, using: &generator)
        let track = tracks[pickedIndex]
        Self.trackCache[index] = track
        return track
    }
    
}

// MARK: - Models

private struct GridIndex: Hashable {
    var x: Int
    var y: Int
}

private enum SwipeAxis {
    case horizontal
    case vertical
}

private enum SwipeDirection {
    case left, right, up, down
}

#Preview {
    Player(activeTab: .constant(.player))
        .environmentObject(NowPlayingState())
        .environmentObject(CollectionState())
}
