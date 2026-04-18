#if canImport(UIKit)
import UIKit
#endif
import CoreHaptics
import SwiftUI

@main
struct MusicApp: App {
    init() {
        // Register custom fonts on app launch
        FontManager.shared.registerFonts()
#if canImport(UIKit)
        UIWindow.appearance().backgroundColor = UIColor.black
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var gyroManager = GyroManager.shared
    @StateObject private var showcaseNavState = ShowcaseNavState()
    @StateObject private var shareOverlayState = ShareOverlayState()
    @StateObject private var overflowMenuState = OverflowMenuState()
    @StateObject private var nowPlayingState: NowPlayingState
    @StateObject private var collectionState = CollectionState()
    @StateObject private var offlineModeState = OfflineModeState()
    @StateObject private var curationManager = ContentCurationManager.shared
    
    init() {
        let initialIndex = GridIndex(x: 0, y: 0)
        let tracks = ContentCurationManager.shared.curatedTracks
        let initialTrack: Track? = tracks.isEmpty ? nil : Player.track(for: initialIndex)
        _nowPlayingState = StateObject(
            wrappedValue: NowPlayingState(
                track: initialTrack,
                isPlaying: false,
                trackIndex: initialIndex
            )
        )
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            MainContentView()
                .background(Color.black)
                .statusBar(hidden: false)
                .preferredColorScheme(.dark)
        }
        .environmentObject(gyroManager)
        .environmentObject(showcaseNavState)
        .environmentObject(shareOverlayState)
        .environmentObject(overflowMenuState)
        .environmentObject(nowPlayingState)
        .environmentObject(collectionState)
        .environmentObject(offlineModeState)
        .environmentObject(curationManager)
        .toast(isPresented: $toastManager.isPresented, config: toastManager.currentConfig)
        .task {
            await curationManager.loadInitial()
            let initialIndex = nowPlayingState.trackIndex ?? GridIndex(x: 0, y: 0)
            nowPlayingState.track = Player.track(for: initialIndex)
            await curationManager.loadRemainingInBackground()
        }
    }
}

// Tracks when user is inside a detail screen (Album/Playlist) so we hide the global TopNavBar and show the screen's own nav bar with back button.
final class ShowcaseNavState: ObservableObject {
    @Published var isShowingDetail = false
    /// Инкремент — `ShowcaseFeedView` сбрасывает `navigationDestination` и возвращает на корень витрины.
    @Published var requestPopToRoot: Int = 0
}

// Tab selection enum for top-level navigation
enum AppTab: Int, CaseIterable {
    case showcase = 0
    case collection = 1
    case player = 2
}

/// Which bottom chrome to show. `classic` keeps the original mini player + showcase + collection covers; `v2` matches Figma «Tabbar • New Navigation».
enum BottomBarStyle {
    case classic
    case v2
}

struct MainContentView: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var showcaseNavState: ShowcaseNavState
    @EnvironmentObject private var shareOverlayState: ShareOverlayState
    @EnvironmentObject private var overflowMenuState: OverflowMenuState
    @EnvironmentObject private var offlineModeState: OfflineModeState
    @State private var selectedTab = 0
    @State private var isTransitioning = false
    @State private var previousTab = 0
    @State private var pendingTab = 0
    @State private var activeAppTab: AppTab = .showcase
    @StateObject private var shaderPlayer = ShaderPlayerManager()
    @State private var playerGridIndex = GridIndex(x: 0, y: 0)
    @State private var didRestorePlayerGridIndex = false
    
    // Navigation paths for each tab to maintain independent navigation history
    @State private var showcaseNavigationPath = NavigationPath()
    @State private var collectionNavigationPath = NavigationPath()
    
    @State private var offlineFlashRunning = false
    @State private var offlineFlashCover: CGFloat = 0
    @State private var offlineFlashExitProgress: CGFloat = 0
    @State private var offlineFlashReverse = false
    /// Общий множитель непрозрачности оверлея вспышки + нижней дымки; 1→0 за последние `offlineFlashFinalFadeOutDurationSeconds` при входе в offline.
    @State private var offlineFlashVisualOpacity: CGFloat = 1
    /// Перестановка цветов блобов 0…6 для слотов b0…b6 — новая при каждом запуске вспышки.
    @State private var offlineFlashBlobColorSlots: [CGFloat] = [0, 1, 2, 3, 4, 5, 6].map { CGFloat($0) }
    /// Радиусы цветных блобов (UV) — новые при каждом запуске.
    @State private var offlineFlashBlobRadii: [CGFloat] = Array(repeating: 0.25, count: 7)
    /// Общая opacity семи цветных блобов — новая при каждом показе вспышки (не влияет на фоновый блоб и белую волну).
    @State private var offlineFlashColoredBlobsOpacity: CGFloat = 0.45
    @State private var suppressOfflineDisableSideEffects = false
    @State private var offlineFlashTask: Task<Void, Never>?
    @State private var offlineFlashHapticEngine: CHHapticEngine?
    @State private var offlineFlashHapticPlayer: CHHapticPatternPlayer?
    /// Set to `.classic` to use `BottomBar` + original `MiniPlayer` behavior.
    private let bottomBarStyle: BottomBarStyle = .v2
    /// Зум витрины Offline (0.9→1) при входе по вспышке; завершается вместе с исчезновением оверлея.
    @State private var offlineShowcaseEntranceScale: CGFloat = 1
    /// Мини + лейбл Offline: 0 = +32 pt / opacity 0 при редиректе; 1 — финал; та же `.smooth` и длительность, что и скейл витрины.
    @State private var offlineShowcaseBottomChromeEntrance: CGFloat = 1
    /// Мини + таббар при выходе из offline на Collection: 0 = +32 pt / opacity 0 при редиректе; 1 — финал; как `downloadsEntranceScale`.
    @State private var onlineCollectionBottomChromeEntrance: CGFloat = 1
    /// Зум вкладки Downloads (0.9→1) при выходе из offline по вспышке; старт и длительность как у скейла витрины Offline (`offlineShowcaseEntranceScaleAnimationDuration`).
    @State private var downloadsEntranceScale: CGFloat = 1
    /// Тёмный слой под скелетон-шторкой: только fade, без сдвига; появляется с короткой задержкой после открытия.
    @State private var skeletonOfflineScrimReveal: CGFloat = 0
    @State private var skeletonOfflineScrimTask: Task<Void, Never>?
    /// Дополнительный сдвиг шторки вверх при оттягивании (≤ 0).
    @State private var skeletonOfflineSheetDragTranslation: CGFloat = 0
    /// После коммита в офлайн: не обновлять drag из жеста (иначе translation снова тянет шторку после сброса в 0 — дрожание).
    @State private var skeletonOfflineSheetDragLocked = false
    /// Порог оттягивания шторки вверх (pt) для перехода в офлайн.
    private static let skeletonOfflineDragThreshold: CGFloat = 40
    /// Длительность `withAnimation(.smooth)` при открытии шторки (`AlbumSkeletonScreen`).
    private static let skeletonSheetEntranceAnimationSeconds: TimeInterval = 0.65
    /// Пауза после приезда шторки, затем появление тёмного фона (opacity).
    private static let skeletonOfflineScrimAfterSheetDelaySeconds: TimeInterval = 0.1
    private static let skeletonOfflineScrimFadeInDuration: TimeInterval = 0.32

    /// Высота шторки: ~92% экрана + нижний safe area, чтобы фон доходил до физического низа без чёрной щели.
    private func skeletonOfflineSheetHeight(safeBottom: CGFloat) -> CGFloat {
        #if canImport(UIKit)
        min(UIScreen.main.bounds.height * 0.92 + safeBottom, UIScreen.main.bounds.height)
        #else
        700
        #endif
    }

    init() {
        // Initialize pendingTab to match selectedTab
        _pendingTab = State(initialValue: 0)
    }

    /// Go Offline / жест вверх: сначала вспышка на текущем экране; `isEnabled` и редирект на корень витрины — под оверлеем (см. `runOfflineFlashTransition(skeletonSheetFlash:)`).
    private func commitSkeletonOfflineTransition() {
        guard !offlineModeState.isEnabled else { return }
        guard !offlineFlashRunning else { return }
        skeletonOfflineSheetDragLocked = true
        var dragTxn = Transaction()
        dragTxn.animation = nil
        withTransaction(dragTxn) {
            skeletonOfflineSheetDragTranslation = 0
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.85)
        #endif
        runOfflineFlashTransition(skeletonSheetFlash: true)
    }

    /// Пока оверлей вспышки видим — множитель как `offlineFlashVisualOpacity` (финальный fade синхронно с хедером). Когда оверлей уже 0, но ещё смонтирован, не умножаем на 0 — иначе фиолетовое свечение пропадало бы до снятия оверлея.
    private var offlineHeaderGlowVisualFactor: Double {
        guard offlineFlashRunning else { return 1 }
        return offlineFlashVisualOpacity > 0 ? Double(offlineFlashVisualOpacity) : 1
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Tab content with independent NavigationStacks
            Group {
                switch activeAppTab {
                case .showcase:
                    NavigationStack(path: $showcaseNavigationPath) {
                        // Showcase content with sequential fade and slight blur
                        Group {
                            if offlineModeState.isEnabled {
                                OfflineShowcase(shaderPlayer: shaderPlayer)
                                    .scaleEffect(offlineShowcaseEntranceScale)
                                    .opacity(1)
                                    .blur(radius: 0)
                            } else {
                                switch pendingTab {
                                case 0:
                                    ForYouShowcase(shaderPlayer: shaderPlayer)
                                        .opacity(isTransitioning ? 0 : 1)
                                        .blur(radius: isTransitioning ? 4 : 0)
                                case 1:
                                    TrendsShowcase()
                                        .opacity(isTransitioning ? 0 : 1)
                                        .blur(radius: isTransitioning ? 4 : 0)
                                case 2:
                                    ReligiousShowcase()
                                        .opacity(isTransitioning ? 0 : 1)
                                        .blur(radius: isTransitioning ? 4 : 0)
                                default:
                                    ForYouShowcase(shaderPlayer: shaderPlayer)
                                        .opacity(isTransitioning ? 0 : 1)
                                        .blur(radius: isTransitioning ? 4 : 0)
                                }
                            }
                        }
                        .animation(.smooth(duration: 0.3), value: isTransitioning)
                        .onChange(of: selectedTab) { oldValue, newValue in
                            // Only animate if actually changing tabs (в офлайне один заголовок — переключения нет)
                            guard !offlineModeState.isEnabled else { return }
                            guard oldValue != newValue else { return }
                            
                            // Phase 1: Fade out current showcase (0.3s)
                            isTransitioning = true
                            
                            // Phase 2: After fade out completes, switch content and fade in new showcase
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                previousTab = pendingTab
                                pendingTab = newValue
                                isTransitioning = true
                                
                                // Then fade in the new showcase
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                                    isTransitioning = false
                                }
                            }
                        }
                        .background(Color.black)
                    }
                    
                case .collection:
                    NavigationStack(path: $collectionNavigationPath) {
                        Collection(downloadsContentScale: $downloadsEntranceScale)
                            .background(Color.black)
                    }
                    
                case .player:
                    Player(
                        activeTab: $activeAppTab,
                        current: $playerGridIndex
                    )
                    .background(Color.black)
                }
            }
            
            if offlineModeState.isEnabled,
               activeAppTab == .showcase,
               !showcaseNavState.isShowingDetail {
                OfflineHeaderGlow(
                    intensity: offlineModeState.headerGlowOpacity * offlineHeaderGlowVisualFactor
                )
            }

            // Fixed top navbar that stays in place during navigation
            // Only show on showcase tab when at root (not inside Album/Playlist — those screens have their own nav bar with back button)
            if activeAppTab == .showcase, !showcaseNavState.isShowingDetail {
                VStack {
                    if offlineModeState.isEnabled {
                        TopNavBar(
                            selectedTab: .constant(0),
                            tabs: ["Offline"],
                            onRequestDisableOffline: { runOfflineExitTransition() },
                            isOfflineExitFlashActive: offlineFlashRunning && offlineFlashReverse
                        )
                    } else {
                        TopNavBar(selectedTab: $selectedTab)
                    }
                    Spacer()
                }
            }
            
            // Fixed bottom bar that stays in place during navigation
            VStack {
                Spacer()
                switch bottomBarStyle {
                case .classic:
                    BottomBar(activeTab: $activeAppTab, playerGridIndex: $playerGridIndex)
                case .v2:
                    BottomBarV2(
                        activeTab: $activeAppTab,
                        offlineFlashCover: offlineFlashCover,
                        offlineFlashExitProgress: offlineFlashExitProgress,
                        offlineFlashRunning: offlineFlashRunning,
                        offlineFlashReverse: offlineFlashReverse,
                        offlineShowcaseBottomChromeEntrance: offlineShowcaseBottomChromeEntrance,
                        offlineShowcaseChromeEntranceAnimationDuration: Self.offlineShowcaseEntranceScaleAnimationDuration,
                        onlineCollectionBottomChromeEntrance: onlineCollectionBottomChromeEntrance,
                        onlineCollectionChromeEntranceAnimationDuration: Self.offlineShowcaseEntranceScaleAnimationDuration
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Share overlay above tab bar — full screen, tap to dismiss
            if let entity = shareOverlayState.presentedShareEntity {
                ShareOverlay(entity: entity)
                    .id(shareOverlayState.presentationID)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Overflow menu (long tap on any entity)
            if let entity = overflowMenuState.presentedEntity {
                OverflowMenu(entity: entity)
                    .id(overflowMenuState.presentationID)
                    .transition(.opacity)
                    .zIndex(101)
            }
            
        }
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                let h = skeletonOfflineSheetHeight(safeBottom: geo.safeAreaInsets.bottom)
                let sheetH = min(h, geo.size.height)
                let scrimOpacity: CGFloat = 0.2
                ZStack(alignment: .bottom) {
                    Color.black.opacity(scrimOpacity * skeletonOfflineScrimReveal)
                        .ignoresSafeArea(edges: .all)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.65)) {
                                offlineModeState.isSkeletonOfflineSheetPresented = false
                            }
                        }

                    OfflineBottomSheet(
                        isPresented: offlineModeState.isSkeletonOfflineSheetPresented,
                        onGoOffline: { commitSkeletonOfflineTransition() },
                        onDragChanged: { translation in
                            guard offlineModeState.isSkeletonOfflineSheetPresented else { return }
                            guard !skeletonOfflineSheetDragLocked else { return }
                            guard !offlineFlashRunning else { return }
                            guard !offlineModeState.isEnabled else { return }
                            guard translation <= 0 else { return }
                            skeletonOfflineSheetDragTranslation = translation
                            if translation <= -Self.skeletonOfflineDragThreshold {
                                commitSkeletonOfflineTransition()
                            }
                        },
                        onDragEnded: { translation in
                            guard !skeletonOfflineSheetDragLocked else { return }
                            guard !offlineModeState.isEnabled else { return }
                            guard offlineModeState.isSkeletonOfflineSheetPresented else { return }
                            guard translation > -Self.skeletonOfflineDragThreshold else { return }
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                                skeletonOfflineSheetDragTranslation = 0
                            }
                        }
                    )
                    .frame(width: geo.size.width, height: sheetH)
                    .offset(
                        y: offlineModeState.isSkeletonOfflineSheetPresented
                            ? skeletonOfflineSheetDragTranslation
                            : sheetH
                    )
                }
                .allowsHitTesting(offlineModeState.isSkeletonOfflineSheetPresented && !offlineFlashRunning)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay {
            if offlineFlashRunning {
                OfflineFlashOverlay(
                    coverProgress: offlineFlashCover,
                    exitProgress: offlineFlashExitProgress,
                    waveProgress: 0,
                    waveProgressB: 0,
                    isReversed: offlineFlashReverse,
                    blobColorSlots: offlineFlashBlobColorSlots,
                    blobRadii: offlineFlashBlobRadii,
                    coloredBlobsOpacity: offlineFlashColoredBlobsOpacity,
                    redirectCoverProgress: CGFloat(Self.offlineFlashRedirectCoverProgress)
                )
                .opacity(offlineFlashVisualOpacity)
                .ignoresSafeArea()
            }
        }
        .onChange(of: offlineModeState.isSkeletonOfflineSheetPresented) { _, shown in
            skeletonOfflineScrimTask?.cancel()
            skeletonOfflineScrimTask = nil
            if shown {
                skeletonOfflineSheetDragLocked = false
                var dragTxn = Transaction()
                dragTxn.animation = nil
                withTransaction(dragTxn) {
                    skeletonOfflineSheetDragTranslation = 0
                }
                skeletonOfflineScrimReveal = 0
                skeletonOfflineScrimTask = Task { @MainActor in
                    let delaySeconds =
                        Self.skeletonSheetEntranceAnimationSeconds
                        + Self.skeletonOfflineScrimAfterSheetDelaySeconds
                    try? await Task.sleep(
                        nanoseconds: UInt64(delaySeconds * 1_000_000_000)
                    )
                    guard !Task.isCancelled, offlineModeState.isSkeletonOfflineSheetPresented else { return }
                    withAnimation(.easeOut(duration: Self.skeletonOfflineScrimFadeInDuration)) {
                        skeletonOfflineScrimReveal = 1
                    }
                }
            } else {
                skeletonOfflineSheetDragLocked = false
                var dragTxn = Transaction()
                dragTxn.animation = nil
                withTransaction(dragTxn) {
                    skeletonOfflineSheetDragTranslation = 0
                }
                withAnimation(.easeOut(duration: 0.2)) {
                    skeletonOfflineScrimReveal = 0
                }
            }
        }
        .onChange(of: offlineModeState.isEnabled) { _, enabled in
            if !enabled {
                if suppressOfflineDisableSideEffects {
                    suppressOfflineDisableSideEffects = false
                    return
                }
                offlineModeState.offlineTransitionChromeFloor = nil
                withAnimation(.easeOut(duration: 0.38)) {
                    offlineModeState.headerGlowOpacity = 0
                }
                cancelOfflineFlashTransition()
                return
            }
            var clearPullTxn = Transaction()
            clearPullTxn.animation = nil
            withTransaction(clearPullTxn) {
                offlineModeState.downloadsPullChromeProgress = 0
            }
            // Вспышка со шторки уже запущена до `isEnabled`; не дублировать и не выставлять glow здесь.
            if offlineFlashRunning {
                var txn = Transaction()
                txn.animation = nil
                withTransaction(txn) {
                    isTransitioning = false
                }
                return
            }
            if activeAppTab == .showcase && !showcaseNavState.isShowingDetail {
                offlineModeState.headerGlowOpacity = 1
                return
            }
            // Вспышка всегда с `coverProgress` 0→1 (снизу вверх); хром после pull держится через `offlineTransitionChromeFloor`.
            runOfflineFlashTransition()
        }
        .onChange(of: activeAppTab) { _, newValue in
            offlineModeState.isSkeletonOfflineSheetPresented = false
            if newValue != .collection {
                var txn = Transaction()
                txn.animation = nil
                withTransaction(txn) {
                    offlineModeState.downloadsPullChromeProgress = 0
                }
            }
            guard newValue == .player else { return }
            guard !didRestorePlayerGridIndex else { return }
            if let targetIndex = nowPlayingState.trackIndex {
                playerGridIndex = targetIndex
            }
            didRestorePlayerGridIndex = true
        }
        .onAppear {
            setupOfflineFlashHapticEngine()
        }
    }
    
    private func setupOfflineFlashHapticEngine() {
        guard offlineFlashHapticEngine == nil else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            engine.stoppedHandler = { [weak engine] reason in
                guard let engine else { return }
                if reason == .audioSessionInterrupt || reason == .applicationSuspended {
                    try? engine.start()
                }
            }
            offlineFlashHapticEngine = engine
        } catch {
            offlineFlashHapticEngine = nil
        }
    }
    
    private func stopOfflineFlashHaptics() {
        try? offlineFlashHapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        offlineFlashHapticPlayer = nil
    }
    
    /// Моменты `hapticTransient` в окне `[0, duration)`: первый интервал `firstGap`, каждый следующий длиннее в `gapGrowth` раз (рулетка, затухание частоты).
    private func offlineFlashRouletteTransientTimes(
        duration: TimeInterval,
        firstGap: TimeInterval,
        gapGrowth: TimeInterval
    ) -> [TimeInterval] {
        guard duration > 0.03 else { return [] }
        var times: [TimeInterval] = [0]
        var t: TimeInterval = 0
        var gap = max(0.028, firstGap)
        let end = max(0, duration - 0.01)
        while true {
            t += gap
            if t > end { break }
            times.append(t)
            gap *= gapGrowth
            if gap > duration * 4 { break }
        }
        return times
    }
    
    /// Серия коротких ударов: рулетка по фазе cover — паузы только растут. Отдельной серии на финальный fade нет (иначе в конце снова шла быстрая пачка).
    private func playOfflineFlashHapticSequence(coverDuration: TimeInterval) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = offlineFlashHapticEngine else { return }
        stopOfflineFlashHaptics()
        let coverTimes = offlineFlashRouletteTransientTimes(
            duration: coverDuration,
            firstGap: 0.054,
            gapGrowth: 1.152
        )
        do {
            try engine.start()
            var events: [CHHapticEvent] = []
            events.reserveCapacity(coverTimes.count)
            func appendTransients(at times: [TimeInterval], baseIntensity: Float, indexOffset: Int) {
                for (i, relT) in times.enumerated() {
                    let k = indexOffset + i
                    let w = exp(-Float(k) * 0.048)
                    let intensity = max(0.38, min(0.95, baseIntensity * (0.84 + 0.16 * w)))
                    let params: [CHHapticEventParameter] = [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ]
                    events.append(CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: params,
                        relativeTime: relT
                    ))
                }
            }
            appendTransients(at: coverTimes, baseIntensity: 0.68, indexOffset: 0)
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            offlineFlashHapticPlayer = player
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            offlineFlashHapticPlayer = nil
        }
    }
    
    /// Сброс оверлея вспышки. `resetEntranceScale: false` — если зум витрины ещё доигрывается после снятия оверлея.
    private func resetOfflineFlashVisuals(resetEntranceScale: Bool = true) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            offlineFlashRunning = false
            offlineFlashCover = 0
            offlineFlashExitProgress = 0
            offlineFlashReverse = false
            offlineFlashVisualOpacity = 1
            offlineModeState.offlineTransitionChromeFloor = nil
            if resetEntranceScale {
                offlineShowcaseEntranceScale = 1
                downloadsEntranceScale = 1
                offlineShowcaseBottomChromeEntrance = 1
                onlineCollectionBottomChromeEntrance = 1
            }
        }
    }
    
    private func cancelOfflineFlashTransition() {
        offlineFlashTask?.cancel()
        offlineFlashTask = nil
        stopOfflineFlashHaptics()
        resetOfflineFlashVisuals()
    }
    
    /// Тяжёлая смена таба / `isEnabled` / корня витрины в том же синхронном кадре, что тик `linear` по `offlineFlashCover`, даёт микрофриз. Переносим пакет на следующий проход run loop — момент по времени почти тот же, анимация не рвётся.
    @MainActor
    private func performDeferredOfflineNavigationRedirect(_ updates: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                var txn = Transaction()
                txn.animation = nil
                withTransaction(txn) {
                    updates()
                }
                continuation.resume()
            }
        }
    }
    
    /// Линейный проход `offlineFlashCover` 0→1.
    private static let offlineFlashCoverDurationSeconds: TimeInterval = 1.54
    /// Доля `coverProgress` 0…1, при которой фоновый блоб уже закрыл весь кадр непрозрачным «телом» (`bgSolid` в OfflineFlash.metal). Редирект таба/режима — в этот момент (доля не менялась — та же относительная точка относительно фазы cover).
    private static let offlineFlashRedirectCoverProgress: TimeInterval = 0.55
    /// Финальное затухание: вся вспышка + зелёный слой + свечение хедера — opacity 1→0 за это время (линейно). Выход из offline: тот же интервал для `exitProgress` в шейдере.
    private static let offlineFlashFinalFadeOutDurationSeconds: TimeInterval = 0.74
    /// Пауза перед финальным fade (сек) — совпадает с `Task.sleep` в `runOfflineFlashTransition`.
    private static let offlineFlashPreFinalFadePauseSeconds: TimeInterval = 9.2e-3
    /// Суммарное время фазы свечения (cover → пауза → финальный fade) — для длительности скейла витрины.
    private static var offlineFlashGlowAnimationTotalSeconds: TimeInterval {
        offlineFlashCoverDurationSeconds
            + offlineFlashPreFinalFadePauseSeconds
            + offlineFlashFinalFadeOutDurationSeconds
    }
    /// Скейл Offline-витрины 0.9→1: по длительности совпадает с полной фазой свечения; стартует с редиректа.
    private static var offlineShowcaseEntranceScaleAnimationDuration: TimeInterval {
        offlineFlashGlowAnimationTotalSeconds
    }
    private static let offlineShowcaseEntranceFromScale: CGFloat = 0.9
    /// Старт зума после начала exit-фазы вспышки; конец зума после `exitDuration + overlayCleanupPad`.
    private static let offlineShowcaseZoomStartAfterExitSeconds: TimeInterval = 0.058
    /// Малая пауза в расчёте снятия оверлея (в паре с финальной длительностью fade).
    private static let offlineFlashOverlayCleanupPadSeconds: TimeInterval = 0.007
    
    private static func shuffledBlobColorSlots() -> [CGFloat] {
        (0..<7).shuffled().map { CGFloat($0) }
    }

    /// Заметный разброс размеров: ~0.14…0.44 в UV-метрике шейдера (aspect-correct falloff).
    private static func randomBlobRadii() -> [CGFloat] {
        (0..<7).map { _ in CGFloat.random(in: 0.14 ... 0.44) }
    }

    private static func randomColoredBlobsOpacity() -> CGFloat {
        CGFloat.random(in: 0.3 ... 0.6)
    }
    
    /// Вспышка → переключение на витрину Offline в момент полного перекрытия фоновым блобом (`offlineFlashRedirectCoverProgress`) → затем доводка `cover` до 1 → растворение. Старт снизу (`coverProgress` с 0).
    /// - Parameter skeletonSheetFlash: шторка скелетона — pop + `isEnabled` под оверлеем; короткая пауза перед редиректом под сброс навигации.
    private func runOfflineFlashTransition(skeletonSheetFlash: Bool = false) {
        cancelOfflineFlashTransition()
        offlineFlashRunning = true
        offlineFlashCover = 0
        offlineFlashExitProgress = 0
        offlineFlashVisualOpacity = 1
        offlineFlashBlobColorSlots = Self.shuffledBlobColorSlots()
        offlineFlashBlobRadii = Self.randomBlobRadii()
        offlineFlashColoredBlobsOpacity = Self.randomColoredBlobsOpacity()
        var prep = Transaction()
        prep.animation = nil
        withTransaction(prep) {
            offlineModeState.headerGlowOpacity = 0
            offlineFlashReverse = false
        }
        
        let coverDuration = Self.offlineFlashCoverDurationSeconds
        let finalFadeDuration = Self.offlineFlashFinalFadeOutDurationSeconds
        let redirectAt = min(max(Self.offlineFlashRedirectCoverProgress, 0.05), 0.95)
        let redirectDelayNs = UInt64(coverDuration * redirectAt * 1_000_000_000)
        let remainingCoverNs = UInt64(max(0, coverDuration * (1.0 - redirectAt)) * 1_000_000_000)
        let cleanupTotalSeconds = finalFadeDuration + Self.offlineFlashOverlayCleanupPadSeconds
        let showcaseScaleDuration = Self.offlineShowcaseEntranceScaleAnimationDuration
        let zoomStartDelaySeconds = Self.offlineShowcaseZoomStartAfterExitSeconds
        let overlayOffAfterZoomStart = max(0, cleanupTotalSeconds - zoomStartDelaySeconds)
        let overlayOffAfterZoomStartNs = UInt64(overlayOffAfterZoomStart * 1_000_000_000)
        let zoomTailAfterOverlaySeconds = max(0, zoomStartDelaySeconds + showcaseScaleDuration - cleanupTotalSeconds)
        let zoomTailAfterOverlayNs = UInt64(zoomTailAfterOverlaySeconds * 1_000_000_000)
        
        // linear: равномерный `coverProgress` — иначе easeOut даёт «быстро улетело — потом ползём» и визуальную остановку.
        withAnimation(.linear(duration: coverDuration)) {
            offlineFlashCover = 1
        }
        playOfflineFlashHapticSequence(coverDuration: coverDuration)
        
        offlineFlashTask = Task { @MainActor in
            defer { offlineFlashTask = nil }
            let skeletonPrepNs: UInt64 = 7_700_000
            if skeletonSheetFlash {
                let firstSleepNs = redirectDelayNs > skeletonPrepNs ? redirectDelayNs - skeletonPrepNs : 0
                try? await Task.sleep(nanoseconds: firstSleepNs)
                guard !Task.isCancelled else {
                    abortOfflineFlashAndGlow()
                    return
                }
                // Сначала сбросить навигацию на корень For You (пока ещё смонтирован), иначе `isEnabled` заменит
                // корень на Offline до `onChange(requestPopToRoot)` — скелетон не сбросится.
                var popTxn = Transaction()
                popTxn.animation = nil
                withTransaction(popTxn) {
                    showcaseNavState.requestPopToRoot += 1
                    showcaseNavigationPath = NavigationPath()
                }
                try? await Task.sleep(nanoseconds: skeletonPrepNs)
                guard !Task.isCancelled else {
                    abortOfflineFlashAndGlow()
                    return
                }
                await performDeferredOfflineNavigationRedirect {
                    offlineModeState.isSkeletonOfflineSheetPresented = false
                    offlineModeState.isEnabled = true
                    activeAppTab = .showcase
                    offlineModeState.headerGlowOpacity = 1
                    offlineShowcaseEntranceScale = Self.offlineShowcaseEntranceFromScale
                    offlineShowcaseBottomChromeEntrance = 0
                }
                withAnimation(.smooth(duration: showcaseScaleDuration)) {
                    offlineShowcaseEntranceScale = 1
                    offlineShowcaseBottomChromeEntrance = 1
                }
            } else {
                try? await Task.sleep(nanoseconds: redirectDelayNs)
                guard !Task.isCancelled else {
                    abortOfflineFlashAndGlow()
                    return
                }
                guard offlineModeState.isEnabled else {
                    abortOfflineFlashAndGlow()
                    return
                }
                await performDeferredOfflineNavigationRedirect {
                    activeAppTab = .showcase
                    offlineModeState.headerGlowOpacity = 1
                    offlineShowcaseEntranceScale = Self.offlineShowcaseEntranceFromScale
                    offlineShowcaseBottomChromeEntrance = 0
                }
                withAnimation(.smooth(duration: showcaseScaleDuration)) {
                    offlineShowcaseEntranceScale = 1
                    offlineShowcaseBottomChromeEntrance = 1
                }
            }
            try? await Task.sleep(nanoseconds: remainingCoverNs)
            guard !Task.isCancelled, offlineModeState.isEnabled else {
                abortOfflineFlashAndGlow()
                return
            }
            try? await Task.sleep(
                nanoseconds: UInt64(Self.offlineFlashPreFinalFadePauseSeconds * 1_000_000_000)
            )
            guard !Task.isCancelled, offlineModeState.isEnabled else {
                abortOfflineFlashAndGlow()
                return
            }
            // Финальный fade: шейдер без exitProgress — затухание через opacity всего оверлея (включая зелёный слой); хедер синхронно.
            withAnimation(.linear(duration: finalFadeDuration)) {
                offlineFlashVisualOpacity = 0
                offlineModeState.headerGlowOpacity = 0
            }
            try? await Task.sleep(nanoseconds: UInt64(finalFadeDuration * 1_000_000_000))
            if offlineModeState.isEnabled {
                var glowTxn = Transaction()
                glowTxn.animation = nil
                withTransaction(glowTxn) {
                    offlineModeState.headerGlowOpacity = 1
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(zoomStartDelaySeconds * 1_000_000_000))
            guard !Task.isCancelled, offlineModeState.isEnabled else {
                abortOfflineFlashAndGlow()
                return
            }
            try? await Task.sleep(nanoseconds: overlayOffAfterZoomStartNs)
            guard !Task.isCancelled, offlineModeState.isEnabled else {
                abortOfflineFlashAndGlow()
                return
            }
            resetOfflineFlashVisuals(resetEntranceScale: false)
            try? await Task.sleep(nanoseconds: zoomTailAfterOverlayNs)
            guard !Task.isCancelled else {
                abortOfflineFlashAndGlow()
                return
            }
            resetOfflineFlashVisuals()
        }
    }
    
    /// Обратная вспышка сверху вниз → под оверлеем Коллекция / Downloads и выключенный тоггл.
    private func runOfflineExitTransition() {
        guard offlineModeState.isEnabled else { return }
        guard activeAppTab == .showcase else { return }
        guard !showcaseNavState.isShowingDetail else { return }
        // Уже идёт обратная вспышка — не дублировать.
        if offlineFlashRunning && offlineFlashReverse { return }
        // Входная вспышка ещё идёт — отменяем её и сразу запускаем выход (иначе тоггл «как будто» выключен, а режим остаётся).
        cancelOfflineFlashTransition()
        offlineFlashReverse = true
        offlineFlashRunning = true
        offlineFlashCover = 0
        offlineFlashExitProgress = 0
        offlineFlashVisualOpacity = 1
        offlineFlashBlobColorSlots = Self.shuffledBlobColorSlots()
        offlineFlashBlobRadii = Self.randomBlobRadii()
        offlineFlashColoredBlobsOpacity = Self.randomColoredBlobsOpacity()
        
        var prep = Transaction()
        prep.animation = nil
        withTransaction(prep) {
            offlineModeState.headerGlowOpacity = 0
        }
        
        let coverDuration = Self.offlineFlashCoverDurationSeconds
        let finalFadeDuration = Self.offlineFlashFinalFadeOutDurationSeconds
        let redirectAt = min(max(Self.offlineFlashRedirectCoverProgress, 0.05), 0.95)
        let redirectDelayNs = UInt64(coverDuration * redirectAt * 1_000_000_000)
        let remainingCoverNs = UInt64(max(0, coverDuration * (1.0 - redirectAt)) * 1_000_000_000)
        let cleanupTotalSeconds = finalFadeDuration + Self.offlineFlashOverlayCleanupPadSeconds
        let showcaseScaleDuration = Self.offlineShowcaseEntranceScaleAnimationDuration
        let zoomStartDelaySeconds = Self.offlineShowcaseZoomStartAfterExitSeconds
        let overlayOffAfterZoomStart = max(0, cleanupTotalSeconds - zoomStartDelaySeconds)
        let overlayOffAfterZoomStartNs = UInt64(overlayOffAfterZoomStart * 1_000_000_000)
        let zoomTailAfterOverlaySeconds = max(0, zoomStartDelaySeconds + showcaseScaleDuration - cleanupTotalSeconds)
        let zoomTailAfterOverlayNs = UInt64(zoomTailAfterOverlaySeconds * 1_000_000_000)
        
        withAnimation(.linear(duration: coverDuration)) {
            offlineFlashCover = 1
        }
        playOfflineFlashHapticSequence(coverDuration: coverDuration)
        
        offlineFlashTask = Task { @MainActor in
            defer { offlineFlashTask = nil }
            try? await Task.sleep(nanoseconds: redirectDelayNs)
            guard !Task.isCancelled else {
                abortOfflineFlashAndGlow()
                return
            }
            guard offlineModeState.isEnabled else {
                abortOfflineFlashAndGlow()
                return
            }
            suppressOfflineDisableSideEffects = true
            offlineModeState.preferredCollectionTopTab = 1
            await performDeferredOfflineNavigationRedirect {
                activeAppTab = .collection
                offlineModeState.isEnabled = false
                downloadsEntranceScale = Self.offlineShowcaseEntranceFromScale
                onlineCollectionBottomChromeEntrance = 0
            }
            withAnimation(.smooth(duration: showcaseScaleDuration)) {
                downloadsEntranceScale = 1
                onlineCollectionBottomChromeEntrance = 1
            }
            try? await Task.sleep(nanoseconds: remainingCoverNs)
            guard !Task.isCancelled else {
                suppressOfflineDisableSideEffects = false
                abortOfflineFlashAndGlow()
                return
            }
            try? await Task.sleep(
                nanoseconds: UInt64(Self.offlineFlashPreFinalFadePauseSeconds * 1_000_000_000)
            )
            guard !Task.isCancelled else {
                suppressOfflineDisableSideEffects = false
                abortOfflineFlashAndGlow()
                return
            }
            withAnimation(.linear(duration: finalFadeDuration)) {
                offlineFlashExitProgress = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(finalFadeDuration * 1_000_000_000))
            try? await Task.sleep(nanoseconds: UInt64(zoomStartDelaySeconds * 1_000_000_000))
            guard !Task.isCancelled else {
                suppressOfflineDisableSideEffects = false
                abortOfflineFlashAndGlow()
                return
            }
            try? await Task.sleep(nanoseconds: overlayOffAfterZoomStartNs)
            guard !Task.isCancelled else {
                suppressOfflineDisableSideEffects = false
                abortOfflineFlashAndGlow()
                return
            }
            resetOfflineFlashVisuals(resetEntranceScale: false)
            try? await Task.sleep(nanoseconds: zoomTailAfterOverlayNs)
            guard !Task.isCancelled else {
                suppressOfflineDisableSideEffects = false
                abortOfflineFlashAndGlow()
                return
            }
            suppressOfflineDisableSideEffects = false
            resetOfflineFlashVisuals()
        }
    }
    
    @MainActor
    private func abortOfflineFlashAndGlow() {
        offlineFlashTask?.cancel()
        offlineFlashTask = nil
        stopOfflineFlashHaptics()
        var t = Transaction()
        t.animation = nil
        withTransaction(t) {
            offlineModeState.headerGlowOpacity = 0
            offlineFlashVisualOpacity = 1
        }
        suppressOfflineDisableSideEffects = false
        resetOfflineFlashVisuals()
    }
}

#Preview {
    NavigationStack {
        MainContentView()
            .environmentObject(ShowcaseNavState())
            .environmentObject(ShareOverlayState())
            .environmentObject(NowPlayingState())
            .environmentObject(CollectionState())
            .environmentObject(OfflineModeState())
    }
}
