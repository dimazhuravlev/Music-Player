#if os(iOS)
import UIKit
#endif
import SwiftUI
import VariableBlur

/// Full-screen 2D pager (TikTok/Reels style) with discrete snap on both axes.
///
/// Layout contract:
/// - Every slide is exactly `screenW × screenH` (UIScreen.main.bounds) — never changes.
/// - The pager container is also `screenW × screenH` with `.clipped()`.
/// - During drag, the current slide moves by `dragOffset` (projected to locked axis).
///   The neighbor slide sits flush next to it (offset ± screenSize).
/// - On commit the strip slides a full screen width/height, then state resets.
struct Player: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var collectionState: CollectionState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    @Binding var activeTab: AppTab

    @Binding var current: GridIndex
    @State private var displayedIndex: GridIndex
    @State private var outgoingIndex: GridIndex?
    @State private var crossfadeProgress: Double = 1
    @State private var dragOffset: CGSize = .zero
    @State private var lockedAxis: SwipeAxis?
    @State private var neighborSlide: (index: GridIndex, direction: SwipeDirection)? = nil
    @State private var isCoverPressed: Bool = false
    @StateObject private var factManager = MusicFactManager()
    @State private var factVisible = false
    @State private var slideColors: [GridIndex: (topHalf: Color, bottomHalf: Color)] = [:]

    private static var trackCache: [GridIndex: Track] = [:]
    private static let randomSalt: UInt64 = .random(in: 0..<UInt64.max)

    private let screenW = UIScreen.main.bounds.width
    private let screenH = UIScreen.main.bounds.height
    private let commitDuration: TimeInterval = 0.3
    private let lockThreshold: CGFloat = 8

    init(
        activeTab: Binding<AppTab> = .constant(.player),
        current: Binding<GridIndex> = .constant(GridIndex(x: 0, y: 0))
    ) {
        _activeTab = activeTab
        _current = current
        _displayedIndex = State(initialValue: current.wrappedValue)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Pager container — fills the full ignoresSafeArea space so no black gaps appear
            ZStack {
                // Crossfade layer for external index changes (e.g. tap from collection)
                if let outgoingIndex {
                    slideView(for: outgoingIndex)
                        .opacity(1 - crossfadeProgress)
                        .transition(.identity)
                }

                // Current slide — moves 1:1 with finger
                slideView(for: displayedIndex)
                    .offset(currentSlideOffset)
                    .opacity(crossfadeProgress)

                // Neighbor slide — persists in tree during snap-back animation
                if let neighbor = neighborSlide {
                    slideView(for: neighbor.index)
                        .offset(neighborOffset(for: neighbor.direction))
                        .transition(.identity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(makeDragGesture())
            .onChange(of: lockedAxis) { newAxis in
                if newAxis != nil, isCoverPressed {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isCoverPressed = false
                    }
                }
            }
            .onChange(of: current) { newValue in
                guard lockedAxis == nil else { return }
                startCrossfade(to: newValue)
            }
            .onReceive(nowPlayingState.audioPlayer.trackFinished) {
                autoAdvanceToNext()
            }
            .onChange(of: displayedIndex) { _ in
                withAnimation(.easeOut(duration: 0.15)) { factVisible = false }
                factManager.showCachedFact(for: Self.track(for: displayedIndex))
                preloadNeighborImages(around: displayedIndex)
                fetchDominantColor(for: displayedIndex)
            }
            .onAppear {
                factManager.showCachedFact(for: Self.track(for: displayedIndex))
                preloadNeighborImages(around: displayedIndex)
                fetchDominantColor(for: displayedIndex)
            }

            // Fact overlay pinned above tab bar
            VStack {
                Spacer()
                factView()
                    .opacity(factVisible ? 1 : 0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 136)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onChange(of: factManager.currentFact) { newFact in
            if newFact != nil {
                withAnimation(.easeIn(duration: 0.3)) { factVisible = true }
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    // MARK: - Slide Positioning

    /// Current slide offset, projected to the locked axis only.
    private var currentSlideOffset: CGSize {
        guard let axis = lockedAxis else { return .zero }
        return axis == .horizontal
            ? CGSize(width: dragOffset.width, height: 0)
            : CGSize(width: 0, height: dragOffset.height)
    }

    /// Computes the neighbor slide's offset from the current `dragOffset` and stored direction.
    private func neighborOffset(for direction: SwipeDirection) -> CGSize {
        switch direction {
        case .left:  return CGSize(width: dragOffset.width + screenW, height: 0)
        case .right: return CGSize(width: dragOffset.width - screenW, height: 0)
        case .up:    return CGSize(width: 0, height: dragOffset.height + screenH)
        case .down:  return CGSize(width: 0, height: dragOffset.height - screenH)
        }
    }

    // MARK: - Slide View

    private func slideView(for index: GridIndex) -> some View {
        let track = Self.track(for: index)
        let colors = slideColors[index] ?? (topHalf: .black, bottomHalf: .black)

        return ZStack {
            slideBackground(for: track, colors: colors)

            VStack(spacing: 12) {
                CachedAsyncImage(url: track.albumCoverURL, assetName: track.albumCover, contentMode: .fit)
                    .frame(width: 188, height: 188)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 6)
                    .contentShape(Rectangle())
                    .scaleEffect(isCoverPressed ? 0.97 : 1)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isCoverPressed)
                    .onLongPressGesture(
                        minimumDuration: 0.3,
                        maximumDistance: 20,
                        pressing: { pressing in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                isCoverPressed = pressing
                            }
                        },
                        perform: {
                            isCoverPressed = false
                            handleCoverLongPress(for: track)
                        }
                    )
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                handleCoverTap(for: track, at: index)
                            }
                    )

                trackHeader(for: index, track: track)

                Spacer()
            }
            .padding(.top, screenH * 0.32)
        }
        .frame(width: screenW, height: screenH)
    }

    /// Artist photo background — uses fixed UIScreen dimensions, immune to layout changes.
    private func slideBackground(
        for track: Track,
        colors: (topHalf: Color, bottomHalf: Color)
    ) -> some View {
        let topH = screenH * 0.4
        let bottomH = screenH * 0.6

        return ZStack {
            VStack(spacing: 0) {
                CachedAsyncImage(url: track.artistImageURL, assetName: track.albumCover)
                    .frame(width: screenW, height: topH)
                    .clipped()

                CachedAsyncImage(url: track.artistImageURL, assetName: track.albumCover)
                    .frame(width: screenW, height: bottomH)
                    .clipped()
                    .scaleEffect(x: 1, y: -1)
            }

            VariableBlurView(maxBlurRadius: 50, direction: .blurredBottomClearTop, startOffset: 0.32)

            // Gradient: starts at 30% from top (matching variable blur startOffset).
            LinearGradient(
                stops: [
                    .init(color: colors.bottomHalf.opacity(0),    location: 0.00),
                    .init(color: colors.bottomHalf.opacity(0.45), location: 0.45),
                    .init(color: colors.topHalf.opacity(0.7),     location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: screenW, height: screenH * 0.7)
            .frame(width: screenW, height: screenH, alignment: .bottom)
            .opacity(0.2)
        }
        .frame(width: screenW, height: screenH)
        .clipped()
        .allowsHitTesting(false)
    }

    private func factView() -> some View {
        Group {
            if factManager.isLoading {
                VStack(alignment: .center, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 16)
                        .shimmering()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 180, height: 16)
                        .shimmering()
                }
            } else if let fact = factManager.currentFact {
                Text(fact)
                    .font(.custom("YangoGroupHeadlineAR-ExtraBold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Gesture

    private func makeDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                if lockedAxis == nil {
                    let absX = abs(value.translation.width)
                    let absY = abs(value.translation.height)
                    guard max(absX, absY) > lockThreshold else {
                        dragOffset = .zero
                        return
                    }
                    lockedAxis = absX > absY ? .horizontal : .vertical
                    withAnimation(.easeOut(duration: 0.15)) { factVisible = false }
                }

                guard let axis = lockedAxis else { return }
                let primary = primaryValue(from: value.translation, axis: axis)
                let dir = directionFor(primary: primary, axis: axis)
                let hasNeighbor = dir != nil
                let adjusted = hasNeighbor ? primary : primary * 0.25

                // Update stored neighbor when direction changes
                if let dir {
                    let idx = neighborIndex(for: dir)
                    if neighborSlide?.direction != dir {
                        neighborSlide = (idx, dir)
                    }
                }

                dragOffset = axis == .horizontal
                    ? CGSize(width: adjusted, height: 0)
                    : CGSize(width: 0, height: adjusted)
            }
            .onEnded { value in
                guard let axis = lockedAxis else {
                    dragOffset = .zero
                    neighborSlide = nil
                    return
                }

                let primary = primaryValue(from: value.translation, axis: axis)
                let predicted = primaryValue(from: value.predictedEndTranslation, axis: axis)
                let span = axis == .horizontal ? screenW : screenH
                let threshold = span * 0.2
                let neighbor = neighborSlide?.index
                let shouldCommit = neighbor != nil && (abs(primary) > threshold || abs(predicted) > threshold)

                let targetPrimary: CGFloat
                if shouldCommit, let dir = neighborSlide?.direction {
                    targetPrimary = (dir == .left || dir == .up) ? -span : span
                } else {
                    targetPrimary = 0
                }

                let targetOffset = axis == .horizontal
                    ? CGSize(width: targetPrimary, height: 0)
                    : CGSize(width: 0, height: targetPrimary)

                if shouldCommit { triggerSwipeHaptic(for: axis) }

                withAnimation(.easeInOut(duration: commitDuration)) {
                    dragOffset = targetOffset
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + commitDuration + 0.02) {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        if shouldCommit, let next = neighbor {
                            current = next
                            displayedIndex = next
                            outgoingIndex = nil
                            crossfadeProgress = 1
                        }
                        dragOffset = .zero
                        lockedAxis = nil
                        neighborSlide = nil
                    }
                }
            }
    }

    // MARK: - Neighbor Index

    private func neighborIndex(for direction: SwipeDirection) -> GridIndex {
        var candidate = displayedIndex
        switch direction {
        case .left:  candidate.x -= 1
        case .right: candidate.x += 1
        case .up:    candidate.y -= 1
        case .down:  candidate.y += 1
        }
        return candidate
    }

    // MARK: - Track Header & Like

    private func trackHeader(for index: GridIndex, track: Track) -> some View {
        VStack(spacing: -2) {
            if let trackTitle = track.trackTitle {
                    Text(trackTitle)
                        .font(.Headline3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
                Text(track.artist)
                    .font(.Headline3)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func handleCoverTap(for track: Track, at index: GridIndex) {
        let isCurrentTrack = nowPlayingState.trackIndex == index || nowPlayingState.track.id == track.id
        if isCurrentTrack {
            nowPlayingState.isPlaying.toggle()
            return
        }
        nowPlayingState.track = track
        nowPlayingState.trackIndex = index
        nowPlayingState.isPlaying = true
        factManager.triggerPlay(for: track)
    }

    /// Programmatically slides to the next track (right-to-left) when a track finishes playing.
    private func autoAdvanceToNext() {
        guard lockedAxis == nil, outgoingIndex == nil else { return }

        let nextIndex = GridIndex(x: displayedIndex.x - 1, y: displayedIndex.y)

        // lockedAxis must be set BEFORE animating so currentSlideOffset follows dragOffset
        lockedAxis = .horizontal
        neighborSlide = (nextIndex, .left)
        withAnimation(.easeOut(duration: 0.15)) { factVisible = false }
        triggerSwipeHaptic(for: .horizontal)

        withAnimation(.easeInOut(duration: commitDuration)) {
            dragOffset = CGSize(width: -screenW, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + commitDuration + 0.02) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                current = nextIndex
                displayedIndex = nextIndex
                outgoingIndex = nil
                crossfadeProgress = 1
                dragOffset = .zero
                lockedAxis = nil
                neighborSlide = nil
            }

            let nextTrack = Self.track(for: nextIndex)
            nowPlayingState.track = nextTrack
            nowPlayingState.trackIndex = nextIndex
            nowPlayingState.isPlaying = true
            factManager.triggerPlay(for: nextTrack)
        }
    }

    private func handleCoverLongPress(for track: Track) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        overflowMenuState.present(ShareableEntity(
            title: track.trackTitle ?? track.title,
            subtitle: track.artist,
            year: track.releaseYear,
            coverImageName: track.albumCover,
            artistImageName: nil,
            coverImageURL: track.albumCoverURL,
            artistImageURL: track.artistThumbnailURL
        ))
    }

    // MARK: - Helpers

    private func primaryValue(from translation: CGSize, axis: SwipeAxis) -> CGFloat {
        axis == .horizontal ? translation.width : translation.height
    }

    private func directionFor(primary: CGFloat, axis: SwipeAxis) -> SwipeDirection? {
        guard primary != 0 else { return nil }
        return axis == .horizontal
            ? (primary < 0 ? .left : .right)
            : (primary < 0 ? .up : .down)
    }

    private func triggerSwipeHaptic(for axis: SwipeAxis) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        #endif
    }

    private func startCrossfade(to newValue: GridIndex) {
        guard newValue != displayedIndex else { return }
        outgoingIndex = displayedIndex
        displayedIndex = newValue
        crossfadeProgress = 0
        withAnimation(.easeInOut(duration: 0.35)) { crossfadeProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { outgoingIndex = nil }
    }

    /// Preloads artist + album cover images for the 4 neighbors around the given index.
    private func preloadNeighborImages(around center: GridIndex) {
        let neighbors = [
            GridIndex(x: center.x - 1, y: center.y),
            GridIndex(x: center.x + 1, y: center.y),
            GridIndex(x: center.x, y: center.y - 1),
            GridIndex(x: center.x, y: center.y + 1),
        ]
        var urls: [URL?] = []
        for idx in neighbors {
            let track = Self.track(for: idx)
            urls.append(track.artistImageURL)
            urls.append(track.albumCoverURL)
            fetchDominantColor(for: idx)
        }
        ImageLoader.preload(urls)
    }

    /// Asynchronously computes the top/bottom average colours of the artist image.
    private func fetchDominantColor(for index: GridIndex) {
        guard slideColors[index] == nil else { return }
        let url = Self.track(for: index).artistImageURL
        Task {
            let pair = await ImageLoader.averageColorPair(url: url)
            withAnimation(.easeInOut(duration: 0.4)) {
                slideColors[index] = pair
            }
        }
    }

    static func track(for index: GridIndex) -> Track {
        let tracks = ContentCurationManager.shared.curatedTracks
        guard !tracks.isEmpty else {
            return Track(id: 0, title: "Track", artist: "Artist", albumCover: "album", releaseYear: 2024)
        }
        if let cached = Self.trackCache[index] { return cached }
        let base = UInt64(bitPattern: Int64(index.x &* 73856093 ^ index.y &* 19349663))
        let seed = base ^ Self.randomSalt
        var generator = SeededGenerator(seed: seed)
        let pickedIndex = Int.random(in: 0..<tracks.count, using: &generator)
        let track = tracks[pickedIndex]
        Self.trackCache[index] = track
        return track
    }
}

// MARK: - Models

struct GridIndex: Hashable {
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
    Player(
        activeTab: .constant(.player),
        current: .constant(GridIndex(x: 0, y: 0))
    )
    .environmentObject(NowPlayingState())
    .environmentObject(CollectionState())
    .environmentObject(OverflowMenuState())
}
