import SwiftUI
#if os(iOS)
import UIKit
#endif

private struct FavoriteItem: Identifiable, Equatable {
    let id = UUID()
    let identifier: Int
    let title: String
}

private extension FavoriteItem {
    static func initialItems() -> [FavoriteItem] {
        let titles = ["Post-Punk", "Shoegaze", "Noise Rock", "Post-Rock", "Hardcore", "Krautrock"]
        return titles.enumerated().map { index, title in
            FavoriteItem(identifier: index, title: title)
        }
    }
}

struct Collection: View {
    @EnvironmentObject private var collectionState: CollectionState
    @EnvironmentObject private var offlineModeState: OfflineModeState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    @EnvironmentObject private var curationManager: ContentCurationManager
    @Binding var downloadsContentScale: CGFloat
    @State private var selectedTopTab = 0
    
    init(downloadsContentScale: Binding<CGFloat> = .constant(1)) {
        _downloadsContentScale = downloadsContentScale
    }
    @State private var favoriteItems: [FavoriteItem] = FavoriteItem.initialItems()
    @State private var itemPositions: [UUID: CGPoint] = [:]
    @State private var dragStartPositions: [UUID: CGPoint] = [:]
    @State private var safeAreaBottom: CGFloat = 0
    @State private var activeDragItemId: UUID?
    @State private var topmostItemId: UUID?
    /// Жест дошёл до порога «мини в нижнем положении»; офлайн — только после отпускания (см. `onFingerReleased` в репортёре).
    @State private var downloadsPullPassedThresholdForCommit = false
    @State private var downloadsPullMiniBottomHapticPrimed = true
    
    private let cardSize = CGSize(width: 140, height: 160)
    private let gridSpacing: CGFloat = 24
    private let paddingTop: CGFloat = 64
    private let paddingHorizontal: CGFloat = 24
    /// Downloads tab: margin from screen edges (banner full-bleed within this inset).
    private let downloadsHorizontalPadding: CGFloat = 16
    private let paddingVertical: CGFloat = 12
    private let edgeOverflow: CGFloat = 120
    private let bottomBarHeight: CGFloat = 140
    /// Дистанция оттягивания (pt), при которой `downloadsPullChromeProgress` = 1.
    private let downloadsPullChromeThreshold: CGFloat = 88
    /// Синхронно с `BottomBarV2.miniChromeProgressBoost`: мини в офлайн-низу при `progress * boost ≥ 1`.
    private static let downloadsMiniChromeBoost: CGFloat = 1.18
    private static var downloadsPullProgressWhenMiniAtOfflineBottom: CGFloat { 1 / downloadsMiniChromeBoost }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            Group {
                if selectedTopTab == 0 {
                    favoritesContent
                } else {
                    downloadsContent
                        .scaleEffect(downloadsContentScale)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            VStack(spacing: 0) {
                TopNavBar(selectedTab: $selectedTopTab, tabs: ["Favorites", "Downloads"])
                Spacer()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear {
            applyPreferredCollectionTopTab()
            offlineModeState.collectionTopTabIndex = selectedTopTab
        }
        .onChange(of: offlineModeState.preferredCollectionTopTab) { _, _ in
            applyPreferredCollectionTopTab()
            offlineModeState.collectionTopTabIndex = selectedTopTab
        }
        .onChange(of: selectedTopTab) { _, newValue in
            resetDownloadsPullScrollState()
            offlineModeState.collectionTopTabIndex = newValue
        }
    }
    
    private func applyPreferredCollectionTopTab() {
        guard let tab = offlineModeState.preferredCollectionTopTab else { return }
        selectedTopTab = tab
        offlineModeState.preferredCollectionTopTab = nil
    }
    
    private var favoritesContent: some View {
        return ScrollView {
            GeometryReader { geo in
                let size = geo.size
                ZStack(alignment: .topLeading) {
                    ForEach(favoriteItems) { item in
                        FavoriteCard(
                            identifier: item.identifier,
                            title: item.title,
                            previousCover: collectionState.previousCover,
                            latestCover: collectionState.latestCover,
                            isPressed: activeDragItemId == item.id,
                            instantPressedLayout: activeDragItemId == item.id,
                            previousCoverURL: collectionState.previousCoverURL,
                            latestCoverURL: collectionState.latestCoverURL
                        )
                        .frame(width: cardSize.width, height: cardSize.height)
                        .zIndex(
                            activeDragItemId == item.id
                            ? 2
                            : (activeDragItemId == nil && topmostItemId == item.id ? 1 : 0)
                        )
                        .position(position(for: item, in: size))
                        .gesture(pressAndDragGesture(for: item, in: size))
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.3).onEnded { _ in
                                guard activeDragItemId == nil else { return }
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                                let cover = collectionState.latestCover ?? "album"
                                overflowMenuState.present(.playlist(title: item.title, coverImageName: cover))
                            }
                        )
                    }
                    
                    Color.clear
                        .onAppear {
                            safeAreaBottom = geo.safeAreaInsets.bottom
                        }
                        .onChange(of: geo.safeAreaInsets.bottom) { newValue in
                            safeAreaBottom = newValue
                        }
                }
                .frame(
                    width: effectiveWidth(in: size) + edgeOverflow * 2,
                    height: contentHeight(in: size)
                )
                .onAppear {
                    initializePositionsIfNeeded(in: size)
                }
                .onChange(of: size) { newSize in
                    initializePositionsIfNeeded(in: newSize)
                }
            }
            .padding(.top, paddingTop)
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
        }
        .scrollDisabled(activeDragItemId != nil)
        .refreshable { offlineModeState.isEnabled = true }
    }

    private var downloadsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                #if os(iOS)
                DownloadsUIKitScrollPullReporter(
                    onPullDistanceChange: { pull in
                        guard selectedTopTab == 1 else { return }
                        applyDownloadsPullChromeProgress(pullDistance: pull)
                    },
                    onFingerReleased: {
                        Task { @MainActor in
                            commitOfflineModeIfPullThresholdWasReached()
                        }
                    }
                )
                .frame(height: 1)
                .accessibilityHidden(true)
                #endif
                VStack(alignment: .leading, spacing: 24) {
                    OfflineWidget(isEnabled: $offlineModeState.isEnabled)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                        .padding(.horizontal, max(4, downloadsHorizontalPadding - 2))
                    AlbumCarousel(
                        title: "Downloaded Albums",
                        albums: Array(curationManager.featuredAlbums.prefix(8)),
                        onAlbumTap: { _ in },
                        onAlbumLongPress: { item in
                            overflowMenuState.present(.album(
                                title: item.albumTitle,
                                artistName: item.artistName,
                                releaseYear: 2025,
                                coverImageName: item.coverImageName,
                                artistImageName: item.coverImageName,
                                coverImageURL: item.coverImageURL
                            ))
                        }
                    )
                    AlbumCarousel(
                        title: "Downloaded Playlists",
                        albums: Array(curationManager.downloadedPlaylistShowcase.prefix(8)),
                        onAlbumTap: { _ in },
                        onAlbumLongPress: { item in
                            overflowMenuState.present(.playlist(
                                title: item.albumTitle,
                                coverImageName: item.coverImageName,
                                coverImageURL: item.coverImageURL
                            ))
                        }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, paddingTop)
            }
        }
        .onScrollPhaseChange { _, newPhase in
            guard selectedTopTab == 1 else { return }
            if newPhase == .idle {
                commitOfflineModeIfPullThresholdWasReached()
            }
        }
        .onDisappear { resetDownloadsPullScrollState() }
    }

    private func applyDownloadsPullChromeProgress(pullDistance: CGFloat) {
        guard selectedTopTab == 1 else { return }
        let progress = min(1, pullDistance / downloadsPullChromeThreshold)
        let miniAtBottom = Self.downloadsPullProgressWhenMiniAtOfflineBottom
        if progress + 0.001 >= miniAtBottom {
            if downloadsPullMiniBottomHapticPrimed {
                downloadsPullMiniBottomHapticPrimed = false
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.88)
                #endif
            }
            downloadsPullPassedThresholdForCommit = true
        } else if progress < miniAtBottom - 0.07 {
            downloadsPullPassedThresholdForCommit = false
            downloadsPullMiniBottomHapticPrimed = true
        }
        var txn = Transaction()
        txn.animation = nil
        withTransaction(txn) {
            offlineModeState.downloadsPullChromeProgress = progress
        }
    }

    /// Только после отпускания пальца: полноэкранная вспышка в `MainContentView` + `runOfflineFlashTransition`.
    private func commitOfflineModeIfPullThresholdWasReached() {
        guard selectedTopTab == 1 else { return }
        guard !offlineModeState.isEnabled else { return }
        guard downloadsPullPassedThresholdForCommit else { return }
        downloadsPullPassedThresholdForCommit = false
        let snap = offlineModeState.downloadsPullChromeProgress
        let floor = max(snap, Self.downloadsPullProgressWhenMiniAtOfflineBottom)
        offlineModeState.offlineTransitionChromeFloor = floor
        offlineModeState.isEnabled = true
    }

    private func resetDownloadsPullScrollState() {
        downloadsPullPassedThresholdForCommit = false
        downloadsPullMiniBottomHapticPrimed = true
        var txn = Transaction()
        txn.animation = nil
        withTransaction(txn) {
            offlineModeState.downloadsPullChromeProgress = 0
        }
    }

}

#if os(iOS)
/// Считает натяжение от **фактического покоя** вертикального `UIScrollView` (как у ленты под навбаром), а не от геометрического верха экрана.
private struct DownloadsUIKitScrollPullReporter: UIViewRepresentable {
    var onPullDistanceChange: (CGFloat) -> Void
    var onFingerReleased: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onPullDistanceChange: onPullDistanceChange, onFingerReleased: onFingerReleased)
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPullDistanceChange = onPullDistanceChange
        context.coordinator.onFingerReleased = onFingerReleased
        context.coordinator.scheduleBind(anchor: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator: NSObject {
        var onPullDistanceChange: (CGFloat) -> Void
        var onFingerReleased: (() -> Void)?
        weak var scrollView: UIScrollView?
        var offsetObservation: NSKeyValueObservation?
        private var bindAttempts = 0
        private var didAddPanEndTarget = false

        init(onPullDistanceChange: @escaping (CGFloat) -> Void, onFingerReleased: (() -> Void)?) {
            self.onPullDistanceChange = onPullDistanceChange
            self.onFingerReleased = onFingerReleased
        }

        func scheduleBind(anchor: UIView) {
            bindAttempts = 0
            tryBind(anchor: anchor)
        }

        private func tryBind(anchor: UIView) {
            guard scrollView == nil else { return }
            guard let sv = anchor.bestVerticalScrollAncestor() else {
                bindAttempts += 1
                guard bindAttempts < 30 else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.tryBind(anchor: anchor)
                }
                return
            }
            scrollView = sv
            offsetObservation = sv.observe(\.contentOffset, options: [.initial, .new]) { [weak self] sv, _ in
                self?.emitPull(for: sv)
            }
            if !didAddPanEndTarget {
                sv.panGestureRecognizer.addTarget(self, action: #selector(handlePanEnd(_:)))
                didAddPanEndTarget = true
            }
        }

        @objc private func handlePanEnd(_ gr: UIPanGestureRecognizer) {
            switch gr.state {
            case .ended, .cancelled, .failed:
                DispatchQueue.main.async { [weak self] in
                    self?.onFingerReleased?()
                }
            default:
                break
            }
        }

        private func emitPull(for sv: UIScrollView) {
            let minY = -sv.adjustedContentInset.top
            let pull = max(0, minY - sv.contentOffset.y)
            var txn = Transaction()
            txn.animation = nil
            withTransaction(txn) {
                onPullDistanceChange(pull)
            }
        }

        func teardown() {
            if let sv = scrollView, didAddPanEndTarget {
                sv.panGestureRecognizer.removeTarget(self, action: #selector(handlePanEnd(_:)))
            }
            didAddPanEndTarget = false
            offsetObservation?.invalidate()
            offsetObservation = nil
            scrollView = nil
        }
    }
}

private extension UIView {
    /// Берём предка-`UIScrollView` с наибольшей высотой контента — вертикальная лента, а не горизонтальная карусель.
    func bestVerticalScrollAncestor() -> UIScrollView? {
        var candidates: [UIScrollView] = []
        var v: UIView? = superview
        while let cur = v {
            if let sv = cur as? UIScrollView {
                candidates.append(sv)
            }
            v = cur.superview
        }
        return candidates.max(by: { lhs, rhs in
            if abs(lhs.bounds.height - rhs.bounds.height) > 0.5 {
                return lhs.bounds.height < rhs.bounds.height
            }
            return lhs.contentSize.height < rhs.contentSize.height
        })
    }
}
#endif

#Preview {
    NavigationStack {
        Collection(downloadsContentScale: .constant(1))
            .environmentObject(NowPlayingState())
            .environmentObject(CollectionState())
            .environmentObject(OfflineModeState())
            .environmentObject(OverflowMenuState())
    }
}

// MARK: - Layout & Drag Helpers
private extension Collection {
    func initializePositionsIfNeeded(in size: CGSize) {
        guard itemPositions.isEmpty else { return }
        guard size.width > (cardSize.width * 1.5) else { return }
        for (index, item) in favoriteItems.enumerated() {
            itemPositions[item.id] = initialPosition(for: index, in: size)
        }
    }
    
    func position(for item: FavoriteItem, in size: CGSize) -> CGPoint {
        if let stored = itemPositions[item.id] {
            return stored
        }
        guard let index = favoriteItems.firstIndex(where: { $0.id == item.id }) else {
            return CGPoint(x: cardSize.width / 2, y: cardSize.height / 2)
        }
        return initialPosition(for: index, in: size)
    }
    
    func initialPosition(for index: Int, in size: CGSize) -> CGPoint {
        let availableWidth = effectiveWidth(in: size) - paddingHorizontal * 2
        let calculated = Int((availableWidth + gridSpacing) / (cardSize.width + gridSpacing))
        let fitsTwo = availableWidth >= (cardSize.width * 2 + gridSpacing)
        let columns = fitsTwo ? max(2, calculated) : 1
        let column = index % columns
        let row = index / columns
        
        let totalWidth = CGFloat(columns) * cardSize.width + CGFloat(columns - 1) * gridSpacing
        let startX = max((availableWidth - totalWidth) / 2, 0) + paddingHorizontal + cardSize.width / 2
        let x = startX + CGFloat(column) * (cardSize.width + gridSpacing)
        let y = (cardSize.height / 2) + CGFloat(row) * (cardSize.height + gridSpacing)
        return CGPoint(x: x, y: y)
    }
    
    func pressAndDragGesture(for item: FavoriteItem, in size: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first:
                    break
                case .second(true, nil):
                    guard activeDragItemId != item.id else { return }
                    triggerLightHaptic()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeDragItemId = item.id
                        topmostItemId = item.id
                    }
                case .second(true, let drag):
                    guard let drag, activeDragItemId == item.id else { return }
                    // Фиксируем опору при первом drag: центр = так, чтобы точка захвата (startLocation) была под пальцем.
                    if dragStartPositions[item.id] == nil {
                        let cur = position(for: item, in: size)
                        dragStartPositions[item.id] = CGPoint(
                            x: cur.x - (drag.location.x - drag.startLocation.x),
                            y: cur.y - (drag.location.y - drag.startLocation.y)
                        )
                    }
                    guard let start = dragStartPositions[item.id] else { return }
                    // Точка захвата всегда под пальцем: центр = опора + (текущая позиция пальца в view − точка захвата в view).
                    let dx = drag.location.x - drag.startLocation.x
                    let dy = drag.location.y - drag.startLocation.y
                    var newPoint = CGPoint(x: start.x + dx, y: start.y + dy)
                    let minX = paddingHorizontal + cardSize.width / 2 - edgeOverflow
                    let maxX = effectiveWidth(in: size) - paddingHorizontal - cardSize.width / 2 + edgeOverflow
                    let minY = cardSize.height / 2 - edgeOverflow
                    let maxY = effectiveHeight(in: size) - bottomBarHeight - safeAreaBottom - cardSize.height / 2
                    newPoint.x = min(max(newPoint.x, minX), maxX)
                    newPoint.y = min(max(newPoint.y, minY), maxY)
                    var tx = Transaction()
                    tx.animation = nil
                    withTransaction(tx) {
                        itemPositions[item.id] = newPoint
                    }
                case .second(false, _):
                    break
                }
            }
            .onEnded { value in
                if case .second(true, _) = value {
                    resetDragState(for: item)
                }
            }
    }
    
    func contentHeight(in size: CGSize) -> CGFloat {
        let maxY = itemPositions.values.map { $0.y }.max() ?? 0
        let limit = effectiveHeight(in: size) - bottomBarHeight - safeAreaBottom
        return max(maxY + cardSize.height / 2 + edgeOverflow, limit)
    }
    
    func effectiveWidth(in size: CGSize) -> CGFloat {
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        #else
        let screenWidth = size.width
        #endif
        return max(size.width, screenWidth)
    }
    
    func effectiveHeight(in size: CGSize) -> CGFloat {
        #if os(iOS)
        let screenHeight = UIScreen.main.bounds.height
        #else
        let screenHeight = size.height
        #endif
        return max(size.height, screenHeight)
    }
    
    func triggerLightHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    func resetDragState(for item: FavoriteItem) {
        dragStartPositions[item.id] = nil
        if activeDragItemId == item.id {
            withAnimation(.easeOut(duration: 0.18)) {
                activeDragItemId = nil
            }
        }
    }
}

