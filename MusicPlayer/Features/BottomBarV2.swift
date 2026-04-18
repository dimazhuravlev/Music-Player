import SwiftUI
import VariableBlur

/// Нижний хром по Figma Sandbox Mobile:18166:83106 (онлайн), 18166:83132 (офлайн).
/// Онлайн: низ мини на 80pt; ряд табов с inset 30pt (+4pt к Figma — ниже).
/// Офлайн: низ мини 60pt (+4pt к макету 56pt); табы съезжают на 80pt; лейбл inset 16pt; +4pt вверх только через offset (не трогает онлайн-геометрию табов).
struct BottomBarV2: View {
    @EnvironmentObject private var nowPlayingState: NowPlayingState
    @EnvironmentObject private var offlineModeState: OfflineModeState
    @Binding var activeTab: AppTab

    var offlineFlashCover: CGFloat = 0
    var offlineFlashExitProgress: CGFloat = 0
    var offlineFlashRunning: Bool = false
    var offlineFlashReverse: Bool = false
    /// 0…1: подъём мини + лейбла Offline снизу после редиректа на витрину (синхрон со скейлом витрины в `MusicApp`).
    var offlineShowcaseBottomChromeEntrance: CGFloat = 1
    /// Длительность `.smooth` для `offlineShowcaseBottomChromeEntrance` (та же, что у скейла витрины).
    var offlineShowcaseChromeEntranceAnimationDuration: TimeInterval = 0.13
    /// 0…1: подъём мини + таббара снизу после редиректа на Collection при выходе из offline (как скейл Downloads в `MusicApp`).
    var onlineCollectionBottomChromeEntrance: CGFloat = 1
    var onlineCollectionChromeEntranceAnimationDuration: TimeInterval = 0.13

    @State private var discoverPressed = false
    @State private var searchPressed = false
    @State private var collectionPressed = false

    private var discoverSelected: Bool {
        activeTab == .showcase || activeTab == .player
    }

    private var collectionSelected: Bool {
        activeTab == .collection
    }

    /// Анимировать сдвиг мини/таббара только во время вспышки или уже включённого офлайна; при оттягивании Downloads — без анимации (следует за пальцем).
    private var shouldAnimateOfflineChrome: Bool {
        offlineFlashRunning || offlineModeState.isEnabled
    }

    /// Короткая анимация по `offlineChromeProgress` не смешивается с entrance на выходе в онлайн — иначе дёргается offset + padding мини.
    private var shouldAnimateOfflineChromeProgressLocally: Bool {
        shouldAnimateOfflineChrome && !isOnlineCollectionExitChromeEntrance
    }

    /// 0…1: синхрон с OfflineFlashOverlay (скрытие табов, появление лейбла) + интерактивный pull на Downloads.
    private var offlineChromeProgress: CGFloat {
        let p = min(1, max(0, offlineFlashCover))
        let e = min(1, max(0, offlineFlashExitProgress))

        if offlineModeState.isEnabled {
            if offlineFlashRunning {
                if offlineFlashReverse { return 1 }
                if e > 0 { return 1 }
                let raw = p
                if let floor = offlineModeState.offlineTransitionChromeFloor {
                    return max(raw, floor)
                }
                return raw
            }
            return 1
        }

        if offlineFlashRunning, offlineFlashReverse {
            return 1 - e
        }

        if activeTab == .collection {
            return min(1, max(0, offlineModeState.downloadsPullChromeProgress))
        }

        return 0
    }

    private var isOfflineShowcaseLayout: Bool {
        activeTab == .showcase && (offlineModeState.isEnabled || offlineFlashRunning)
    }

    /// Выход из offline: редирект на Collection под обратной вспышкой — отдельный entrance для онлайн-хрома.
    private var isOnlineCollectionExitChromeEntrance: Bool {
        activeTab == .collection
            && !offlineModeState.isEnabled
            && offlineFlashRunning
            && offlineFlashReverse
    }

    private var onlineExitChromeEntranceOffsetY: CGFloat {
        guard isOnlineCollectionExitChromeEntrance else { return 0 }
        return Self.offlineShowcaseChromeEntranceOffset * (1 - onlineCollectionBottomChromeEntrance)
    }

    /// Пока `tabBarOpacity` = 0 при полном офлайн-прогрессе, тянем видимость иконок за `onlineCollectionBottomChromeEntrance`.
    private var tabBarOpacityWithOnlineExitEntrance: CGFloat {
        let base = tabBarOpacity
        if isOnlineCollectionExitChromeEntrance {
            return base + (1 - base) * onlineCollectionBottomChromeEntrance
        }
        return base
    }

    private var miniPlayerOpacity: CGFloat {
        if isOfflineShowcaseLayout { return offlineShowcaseBottomChromeEntrance }
        return 1
    }

    /// При обратной вспышке выхода в онлайн фиксируем мини в онлайн-геометрии (без сдвига по `offlineChromeProgress`).
    private var miniChromeProgressForLayout: CGFloat {
        if isOnlineCollectionExitChromeEntrance { return 0 }
        return miniChromeProgress
    }

    // MARK: - Figma (375pt ref.)

    /// Онлайн: низ мини от низа экрана; офлайн 60pt; доп. −4pt по Y только при `offlineChromeVisualLift`.
    private static let figmaMiniBottomInsetOnline: CGFloat = 80
    private static let figmaMiniBottomInsetOffline: CGFloat = 60
    /// Онлайн: inset ряда табов от safe-area (+8 pt к базовым 30 pt).
    private static let figmaTabsBottomInset: CGFloat = 38
    /// Сдвиг ряда табов вниз по мере офлайн-прогресса (pull / вспышка). Меньше макетных 80pt — иконки не уезжают так низко.
    private static let figmaTabsSlideDown: CGFloat = 44
    /// Pull / не вспышка: таббар следует за прогрессом без сильного сглаживания.
    private static let tabBarSlideAnimationDuration: Double = 0.089
    /// Вход в offline по вспышке: таббар и мини опускаются в офлайн-позицию.
    private static let offlineEnterFlashChromeSlideDuration: TimeInterval = 1.0
    /// Иконки 1→0 линейно по первым стольким долям `offlineChromeProgress`.
    private static let tabBarFadeOutProgressEnd: CGFloat = 0.35
    /// С этой доли pull (коллекция) линейно проявляется подсказка «Pull to go Offline» до opacity 1 к 100%.
    private static let pullToOfflineHintOpacityStartProgress: CGFloat = tabBarFadeOutProgressEnd
    /// Мини раньше доезжает до офлайн-позиции относительно того же оттяга (1 = как общий прогресс).
    private static let miniChromeProgressBoost: CGFloat = 1.18
    /// Лейбл: отступ снизу до текста; +4pt вверх — `offlineChromeVisualLift`.
    private static let figmaOfflineLabelBottomInset: CGFloat = 16
    /// Сдвиг лейбла и мини вверх в офлайне (offset, не меняет padding таббара / онлайн-мини).
    private static let offlineChromeVisualLift: CGFloat = 4
    /// Стартовый сдвиг мини и лейбла вниз при входе на Offline-витрину по вспышке (`entrance` 0→1).
    private static let offlineShowcaseChromeEntranceOffset: CGFloat = 32
    /// Доп. подъём подсказки pull-to-offline относительно якоря офлайн-лейбла.
    private static let pullToOfflineHintExtraLift: CGFloat = 2
    /// Высота мини-плеера (см. `MiniPlayerV2.barHeight`).
    private static let miniPlayerBarHeight: CGFloat = 56
    /// Pull-to-offline: блобы поднимаются снизу; при полном оттяге верх свечения — у верхнего края мини.
    private static func downloadsPullBlobMistHeight(safeBottom: CGFloat) -> CGFloat {
        safeBottom + figmaMiniBottomInsetOffline + miniPlayerBarHeight
    }

    /// Доп. подъём блобов по мере оттяга (0→32 pt снизу вверх, синхронно с `downloadsPullChromeProgress`).
    private static let downloadsPullBlobProgressLift: CGFloat = 32
    /// Смещение блобов вниз, чтобы при p=1 геометрический низ эллипсов был за нижним краем экрана (виден только размытый «хвост»).
    private static let downloadsPullBlobBottomBleedDown: CGFloat = 96

    /// При оттяге Downloads: лейбл «Pull to go Offline» поднимается снизу вверх на 0…12 pt по прогрессу.
    private static let pullToOfflineHintPullLift: CGFloat = 12
    /// На полном оттяге опускает лейбл на 4 pt вниз относительно прежней верхней точки; растёт линейно с прогрессом.
    private static let pullToOfflineHintFinalNudgeDown: CGFloat = 4
    /// Variable blur + лёгкий градиент над ним (одинаковая высота).
    private static let chromeBottomMaterialHeight: CGFloat = 120

    private static let tabBarHorizontalPadding: CGFloat = 40
    private static let tabBarBottomInset: CGFloat = 24
    private static let tabBarRowLayoutHeight: CGFloat = 16 + 32 + 16 + 24

    private static let offlineCaptionLineHeight: CGFloat = 16

    /// 0…1: только мини — чуть быстрее общего `offlineChromeProgress` (pull / вспышка).
    private var miniChromeProgress: CGFloat {
        min(1, offlineChromeProgress * Self.miniChromeProgressBoost)
    }

    /// Низ мини: 80pt → 60pt по прогрессу (сдвиг 20pt).
    private func miniBottomPadding(safeBottom: CGFloat) -> CGFloat {
        let t = miniChromeProgressForLayout
        let inset = Self.figmaMiniBottomInsetOnline
            + (Self.figmaMiniBottomInsetOffline - Self.figmaMiniBottomInsetOnline) * t
        return safeBottom + inset
    }

    /// Opacity 1→0 линейно за первые `tabBarFadeOutProgressEnd` прогресса (вместе со стартом сдвига).
    private var tabBarOpacity: CGFloat {
        let p = offlineChromeProgress
        let e = Self.tabBarFadeOutProgressEnd
        if p <= 0 { return 1 }
        if p >= e { return 0 }
        return 1 - p / e
    }

    /// Только коллекция + не офлайн: 0…1 между `pullToOfflineHintOpacityStartProgress` и полным оттягом.
    /// Только `downloadsPullChromeProgress` — не `offlineChromeProgress`: при вспышке выхода из офлайна тот же прогресс идёт 1→0 и ошибочно проявлял бы подсказку, пока таббар едет вверх.
    private var collectionPullToOfflineHintOpacity: CGFloat {
        guard activeTab == .collection, !offlineModeState.isEnabled else { return 0 }
        let p = offlineModeState.downloadsPullChromeProgress
        let s = Self.pullToOfflineHintOpacityStartProgress
        if p <= s { return 0 }
        return min(1, (p - s) / (1 - s))
    }

    /// Смещение по Y для подсказки pull-to-offline; сдвиг вниз к полному оттягу см. `pullToOfflineHintFinalNudgeDown`.
    private var pullToOfflineHintOffsetY: CGFloat {
        let p = offlineModeState.downloadsPullChromeProgress
        return -Self.pullToOfflineHintPullLift * p
            - Self.pullToOfflineHintExtraLift
            + Self.pullToOfflineHintFinalNudgeDown * p
    }

    /// Пока идёт fade, высота ряда полная — иначе clip съедает иконки до того, как они «угаснут».
    private var tabBarLayoutHeightFactor: CGFloat {
        let p = offlineChromeProgress
        let e = Self.tabBarFadeOutProgressEnd
        if p <= 0 { return 1 }
        if p >= 1 { return 0 }
        if p <= e { return 1 }
        return 1 - (p - e) / (1 - e)
    }

    /// При выходе из offline `p` ещё 1 — без этого ряд схлопнут (height 0), entrance не виден.
    private var tabBarLayoutHeightFactorWithOnlineExit: CGFloat {
        if isOnlineCollectionExitChromeEntrance {
            return max(tabBarLayoutHeightFactor, onlineCollectionBottomChromeEntrance)
        }
        return tabBarLayoutHeightFactor
    }

    private var tabBarOfflineChromeProgressAnimation: Animation? {
        guard shouldAnimateOfflineChromeProgressLocally else { return nil }
        if offlineFlashRunning && !offlineFlashReverse {
            return .smooth(duration: Self.offlineEnterFlashChromeSlideDuration)
        }
        return .smooth(duration: Self.tabBarSlideAnimationDuration)
    }

    private var miniOfflineChromeProgressAnimation: Animation? {
        guard shouldAnimateOfflineChromeProgressLocally else { return nil }
        if offlineFlashRunning && !offlineFlashReverse {
            return .smooth(duration: Self.offlineEnterFlashChromeSlideDuration)
        }
        return .smooth(duration: 0.13)
    }

    var body: some View {
        GeometryReader { geo in
            let safeBottom = geo.safeAreaInsets.bottom
            ZStack(alignment: .bottom) {
                if activeTab != .player {
                    chromeBackground()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                }

                tabBarRow(iconOpacity: tabBarOpacityWithOnlineExitEntrance)
                    .padding(.bottom, safeBottom + Self.figmaTabsBottomInset)
                    .frame(
                        height: Self.tabBarRowLayoutHeight * tabBarLayoutHeightFactorWithOnlineExit,
                        alignment: .top
                    )
                    .clipped()
                    .offset(y: (offlineChromeProgress < 1
                        ? Self.figmaTabsSlideDown * offlineChromeProgress
                        : 0) + onlineExitChromeEntranceOffsetY)
                    .allowsHitTesting(tabBarOpacityWithOnlineExitEntrance > 0.02)
                    .animation(tabBarOfflineChromeProgressAnimation, value: offlineChromeProgress)
                    .animation(
                        .smooth(duration: onlineCollectionChromeEntranceAnimationDuration),
                        value: onlineCollectionBottomChromeEntrance
                    )
                    .animation(.smooth(duration: 0.42), value: activeTab)

                if isOfflineShowcaseLayout {
                    offlineModeCaption
                        .padding(.bottom, safeBottom + Self.figmaOfflineLabelBottomInset)
                        .offset(
                            y: -Self.offlineChromeVisualLift * offlineChromeProgress
                                + Self.offlineShowcaseChromeEntranceOffset * (1 - offlineShowcaseBottomChromeEntrance)
                        )
                        .opacity(Double(offlineChromeProgress * offlineShowcaseBottomChromeEntrance))
                        .animation(shouldAnimateOfflineChrome ? .smooth(duration: 0.13) : nil, value: offlineChromeProgress)
                        .animation(
                            .smooth(duration: offlineShowcaseChromeEntranceAnimationDuration),
                            value: offlineShowcaseBottomChromeEntrance
                        )
                }

                MiniPlayerV2(track: nowPlayingState.track)
                    .padding(.horizontal, 24)
                    .padding(.bottom, miniBottomPadding(safeBottom: safeBottom))
                    .offset(
                        y: -Self.offlineChromeVisualLift * miniChromeProgressForLayout
                            + (isOfflineShowcaseLayout
                                ? Self.offlineShowcaseChromeEntranceOffset * (1 - offlineShowcaseBottomChromeEntrance)
                                : 0)
                    )
                    .opacity(Double(miniPlayerOpacity))
                    // Иначе `.animation(..., value: activeTab)` на ZStack интерполирует смену Showcase→Collection и тянет мини по дуге ~420ms.
                    .animation(nil, value: activeTab)
                    .animation(miniOfflineChromeProgressAnimation, value: miniChromeProgress)
                    .animation(
                        .smooth(duration: offlineShowcaseChromeEntranceAnimationDuration),
                        value: offlineShowcaseBottomChromeEntrance
                    )

                if activeTab == .collection, !offlineModeState.isEnabled {
                    ZStack(alignment: .bottom) {
                        downloadsPullOfflineBlobMist(safeBottom: safeBottom)
                            .animation(nil, value: offlineModeState.downloadsPullChromeProgress)

                        Text("Pull to go Offline")
                            .font(.Text2)
                            .foregroundColor(.subtitle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.bottom, safeBottom + Self.figmaOfflineLabelBottomInset)
                            .offset(y: pullToOfflineHintOffsetY)
                            .opacity(Double(collectionPullToOfflineHintOpacity))
                            .animation(nil, value: offlineModeState.downloadsPullChromeProgress)
                            .allowsHitTesting(false)
                            .accessibilityLabel("Pull to go Offline")
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            .ignoresSafeArea()
        }
    }

    private func tabBarRow(iconOpacity: CGFloat) -> some View {
        HStack(spacing: 0) {
            tabButton(
                title: "Discover",
                assetName: "music-fill",
                selectedAssetName: "music",
                isSelected: discoverSelected,
                isPressed: discoverPressed,
                iconOpacity: iconOpacity
            ) {
                triggerTabHaptic()
                activeTab = .showcase
            }
            .simultaneousGesture(pressGesture(binding: $discoverPressed))

            tabButton(
                title: "Search",
                assetName: "search",
                isSelected: false,
                isPressed: searchPressed,
                iconForeground: Color.subtitle,
                iconOpacity: iconOpacity
            ) {
                // Placeholder — not wired yet
            }
            .simultaneousGesture(pressGesture(binding: $searchPressed))

            tabButton(
                title: "My Collection",
                assetName: "like-default",
                selectedAssetName: "like-fill",
                isSelected: collectionSelected,
                isPressed: collectionPressed,
                iconOpacity: iconOpacity
            ) {
                triggerTabHaptic()
                activeTab = .collection
            }
            .simultaneousGesture(pressGesture(binding: $collectionPressed))
        }
        .padding(.horizontal, Self.tabBarHorizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, Self.tabBarBottomInset)
    }

    private func chromeBackground() -> some View {
        GeometryReader { bg in
            let h = min(Self.chromeBottomMaterialHeight, bg.size.height)
            ZStack(alignment: .bottom) {
                VariableBlurView(maxBlurRadius: 12, direction: .blurredBottomClearTop)
                    .frame(height: h)
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color.black.opacity(0.12), location: 0.5),
                        .init(color: Color.black.opacity(0.06), location: 0.82),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: h)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .frame(width: bg.size.width, height: bg.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    /// Туманное свечение при оттягивании Downloads: два размытых блоба выезжают снизу к уровню мини-плеера.
    private func downloadsPullOfflineBlobMist(safeBottom: CGFloat) -> some View {
        let p = min(1, max(0, offlineModeState.downloadsPullChromeProgress))
        let mistHeight = Self.downloadsPullBlobMistHeight(safeBottom: safeBottom)
        /// Сдвиг вниз при p=0 — почти весь слой под нижним краем экрана.
        let emergenceShift = mistHeight * 0.52

        return GeometryReader { geo in
            let w = geo.size.width
            let bleed = Self.downloadsPullBlobBottomBleedDown
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 233 / 255, green: 0, blue: 230 / 255).opacity(0.6),
                                Color(red: 255 / 255, green: 0, blue: 225 / 255).opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.56
                        )
                    )
                    .frame(width: w * 1.12, height: w * 0.84)
                    .blur(radius: 64)
                    .offset(x: -w * 0.1, y: mistHeight * 0.02 + bleed)

                Ellipse()
                    .fill(Color(red: 163 / 255, green: 50 / 255, blue: 1).opacity(0.6))
                    .frame(width: w * 0.68, height: w * 0.54)
                    .blur(radius: 54)
                    .offset(x: w * 0.18, y: mistHeight * 0.01 + bleed * 0.95)
            }
            .frame(width: w, height: mistHeight + bleed, alignment: .bottom)
            .offset(y: (1 - p) * emergenceShift - Self.downloadsPullBlobProgressLift * p)
            .opacity(Double(p))
        }
        .frame(height: mistHeight + Self.downloadsPullBlobBottomBleedDown)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }

    private func tabButton(
        title: String,
        assetName: String,
        selectedAssetName: String? = nil,
        isSelected: Bool,
        isPressed: Bool,
        iconForeground: Color? = nil,
        iconOpacity: CGFloat = 1,
        action: @escaping () -> Void
    ) -> some View {
        let iconAsset = isSelected ? (selectedAssetName ?? assetName) : assetName
        let resolvedForeground = iconForeground ?? (isSelected ? Color.fill1 : Color.subtitle)
        return Button(action: action) {
            Image(iconAsset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(resolvedForeground)
                .opacity(iconOpacity)
                .frame(width: 32, height: 32)
                .animation(nil, value: iconAsset)
                .scaleEffect(isPressed ? 0.92 : 1)
                .animation(.smooth(duration: 0.15), value: isPressed)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func pressGesture(binding: Binding<Bool>) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                withAnimation(.smooth(duration: 0.15)) {
                    binding.wrappedValue = true
                }
            }
            .onEnded { _ in
                withAnimation(.smooth(duration: 0.15)) {
                    binding.wrappedValue = false
                }
            }
    }

    private func triggerTabHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred(intensity: 0.7)
    }

    private var offlineModeCaption: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Offline Mode is on")
                .font(.Text2)
                .foregroundColor(.fill1)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .tracking(0)
                .frame(maxWidth: .infinity)
                .frame(height: Self.offlineCaptionLineHeight, alignment: .center)
            Text("Playing from Downloads")
                .font(.Text2)
                .foregroundColor(.subtitle)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .tracking(0)
                .frame(maxWidth: .infinity)
                .frame(height: Self.offlineCaptionLineHeight, alignment: .center)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline Mode is on, Playing from Downloads")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BottomBarV2(activeTab: .constant(.showcase))
            .environmentObject(NowPlayingState())
            .environmentObject(OfflineModeState())
    }
}
