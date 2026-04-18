import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Все константы жеста «схватил — тащишь — отпустил»: пороги, пружина, вылет при dismiss.
private enum ShareCardDragConfig {
    static let cardWidth: CGFloat = 254

    /// Смещение от центра 0…1 для размытия нижнего блока и фона
    static let dismissDistanceThreshold: CGFloat = 120
    /// Порог скорости выброса карточки, чтобы закрыть оверлей
    static let dismissVelocityThreshold: CGFloat = 300

    static let rotationSensitivity: Double = 0.18
    static let inertiaTranslationFactor: CGFloat = 0.25
    static let inertiaRotationFactor: Double = 0.2

    static let grabScale: CGFloat = 0.98
    /// Масштаб карточки при «захвате» и возврат в 1
    static let grabAnimationDuration: Double = 0.2
    static let closeButtonHideOnDragDuration: Double = 0.2
    static let minDragBeforeGrabFeedback: CGFloat = 4
    /// Ниже этого смещения при отпускании — без инерции (тап/случайный джиттер), только пружина в центр
    static let noInertiaMaxReleaseDistance: CGFloat = 12

    static let returnSpringResponse: Double = 0.52
    static let returnSpringDamping: Double = 0.72

    static let flyOutDuration: Double = 0.42
    static let flyOutDistance: CGFloat = 720
    static let flyVelocityBoost: CGFloat = 0.3
    /// Размытие фона после вылета карточки (карта должна уехать раньше)
    static let blurFadeAfterFlyDuration: Double = 0.24
}

private enum ShareOverlayOpenConfig {
    static let blurIn: Double = 0.4
    /// Общая задержка перед появлением карточки и нижнего блока (синхронно).
    static let cardAndBottomDelay: Double = 0.2
    static let cardIn: Double = 0.3
    static let bottomIn: Double = 0.3
    /// Задержка между появлением соседних кнопок шеринга (волна слева направо).
    static let bottomButtonStagger: Double = 0.06
    static let bottomButtonItemIn: Double = 0.2
    static let bottomButtonInitialOffsetY: CGFloat = 10
    static let initialCardScale: CGFloat = 0.97
    static let bottomOffsetY: CGFloat = 8
}

private let shareBottomActionItems: [(icon: String, label: String)] = [
    ("instagram", "Stories"),
    ("whatsapp", "WhatsApp"),
    ("copy link", "Copy link"),
    ("more", "More"),
]

private enum ShareOverlayDismissConfig {
    static let contentOut: Double = 0.3
    static let blurOut: Double = 0.4
    static let closeButtonFade: Double = 0.25
}

/// Пробрасываем высоту контента карточки: жест крутит вокруг точки захвата, для `y` якоря нужна реальная высота.
private struct ShareCardLayoutHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let h = nextValue()
        if h > 0 { value = h }
    }
}

struct ShareOverlay: View {
    let entity: ShareableEntity

    @EnvironmentObject private var shareOverlayState: ShareOverlayState

    /// Защита от колбэков открытия после закрытия (иначе невидимый hit-слой).
    @State private var openAnimSession: UInt64 = 0

    @State private var blurOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var cardScale: CGFloat = ShareOverlayOpenConfig.initialCardScale
    @State private var bottomBlockOpacity: Double = 0
    @State private var bottomBlockOffsetY: CGFloat = ShareOverlayOpenConfig.bottomOffsetY
    @State private var shareButtonOpacity: [Double] = Array(repeating: 0, count: shareBottomActionItems.count)
    @State private var shareButtonOffsetY: [CGFloat] = Array(
        repeating: ShareOverlayOpenConfig.bottomButtonInitialOffsetY,
        count: shareBottomActionItems.count
    )
    @State private var closeButtonOpacity: Double = 0

    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var grabAnchor: UnitPoint = .center
    @State private var cardDragActive = false
    @State private var closeButtonVisibleAfterDrag: Double = 1
    @State private var cardInteractionScale: CGFloat = 1
    @State private var dragGrabFeedbackStarted = false
    @State private var shareCardLayoutHeight: CGFloat = 360

    var body: some View {
        ZStack {
            // Слой 1: весь экран — тап закрывает; карточка выше по Z и перехватывает тачи только на себе.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.black.opacity(backgroundBlackLayerOpacity))
                    }
                    .opacity(blurOpacity)
                    .ignoresSafeArea()
                )

            // Слой 2: карточка по центру, блок «Share» снизу; при уводе карточки нижний блок гаснет/размывается.
            VStack(spacing: 0) {
                Spacer()
                shareCardWithDrag
                    .opacity(cardOpacity)
                    .scaleEffect(cardScale * cardInteractionScale)
                Spacer()
                shareBottomBlock
                    .opacity(dragAwayVisibility)
                    .blur(radius: 6 * dragAwayProgress)
                    .offset(y: bottomBlockOffsetY + 16 * dragAwayProgress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                closeButton
                    .opacity(closeButtonOpacity * closeButtonVisibleAfterDrag)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
        }
        .onAppear {
            openAnimSession += 1
            runOpenAnimation(session: openAnimSession)
        }
        // После возврата карточки в центр снова показываем крестик (во время драга он скрыт).
        .onChange(of: dragOffset) { _, new in
            guard !cardDragActive, hypot(new.width, new.height) < 2 else { return }
            withAnimation(.easeOut(duration: ShareOverlayDismissConfig.closeButtonFade)) {
                closeButtonVisibleAfterDrag = 1
            }
        }
    }

    /// Насколько карточка «ушла» от центра (0…1) — общий прогресс для фона, нижнего блока и размытия.
    private var dragAwayProgress: CGFloat {
        let d = hypot(dragOffset.width, dragOffset.height)
        return min(1, max(0, d / ShareCardDragConfig.dismissDistanceThreshold))
    }

    private var dragAwayVisibility: Double { 1 - Double(dragAwayProgress) }

    private var backgroundBlackLayerOpacity: Double {
        0.48 + 0.12 * (1 - Double(dragAwayProgress))
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image("cross")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.fill1)
                .frame(width: 16, height: 16)
                .padding(6)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
        }
        .frame(width: 28, height: 28)
        .buttonStyle(.plain)
    }

    private var shareCardHasMetaRow: Bool {
        entity.subtitle != nil || entity.year != nil
    }

    // Верстка шаринг-карточки

    private var shareCardContent: some View {
        VStack(spacing: 0) {
            Image("Yango Music Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .padding(.top, 24)
                .padding(.bottom, 24)

            // Обложка
            CachedAsyncImage(url: entity.coverImageURL, assetName: entity.coverImageName)
                .frame(width: 230, height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
                .padding(.bottom, 8)

            // Заголовок сущности
            Text(entity.title)
                .font(.Headline4)
                .foregroundColor(.fill1)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, shareCardHasMetaRow ? 4 : 0)

            // Если сущность — плейлист
            if shareCardHasMetaRow {
                HStack(spacing: 8) {
                    if let avatar = entity.artistImageName {
                        CachedAsyncImage(url: entity.artistImageURL, assetName: avatar)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let subtitle = entity.subtitle {
                            Text(subtitle).font(.Text1).foregroundColor(.fill1)
                        }
                        if let year = entity.year {
                            Text(String(year)).font(.Text1).foregroundColor(.subtitle)
                        }
                    }
                    Spacer()
                }
                .frame(height: 40)
                .padding(.horizontal, 12)
            }
        }
        .padding(.bottom, 12)
        .frame(width: ShareCardDragConfig.cardWidth)
        .background(
            ZStack {
                Color.white.opacity(0.08)
                // Замер высоты для якоря вращения при перетаскивании
                GeometryReader { geo in
                    Color.clear.preference(key: ShareCardLayoutHeightKey.self, value: geo.size.height)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 0.66))
        .contentShape(Rectangle())
    }

    // Перетаскивание карточки

    private var shareCardWithDrag: some View {
        shareCardContent
            .onPreferenceChange(ShareCardLayoutHeightKey.self) { h in
                if h > 0 { shareCardLayoutHeight = h }
            }
            .offset(x: dragOffset.width, y: dragOffset.height)
            .rotationEffect(.degrees(dragRotation), anchor: grabAnchor)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged(handleDragChanged)
                    .onEnded(handleDragEnded)
            )
    }

    /// Тащишь пальцем — карточка едет вместе с ним и чуть заваливается, будто ты схватил её за тот уголок, куда ткнул.
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !cardDragActive {
            cardDragActive = true
            let w = ShareCardDragConfig.cardWidth
            let h = max(shareCardLayoutHeight, 200)
            grabAnchor = UnitPoint(
                x: max(0.05, min(0.95, value.startLocation.x / w)),
                y: max(0.05, min(0.95, value.startLocation.y / h))
            )
        }
        let dx = value.translation.width
        let dy = value.translation.height
        if hypot(dx, dy) > ShareCardDragConfig.minDragBeforeGrabFeedback, !dragGrabFeedbackStarted {
            dragGrabFeedbackStarted = true
            withAnimation(.easeOut(duration: ShareCardDragConfig.closeButtonHideOnDragDuration)) {
                closeButtonVisibleAfterDrag = 0
            }
            withAnimation(.easeOut(duration: ShareCardDragConfig.grabAnimationDuration)) {
                cardInteractionScale = ShareCardDragConfig.grabScale
            }
        }
        let ax = Double(grabAnchor.x) - 0.5
        let ay = Double(grabAnchor.y) - 0.5
        dragRotation = ShareCardDragConfig.rotationSensitivity * (ax * Double(dy) - ay * Double(dx))
        dragOffset = CGSize(width: dx, height: dy)
    }

    /// Логика закрытия перетаскиванием:
    /// 1) Далеко увели или резко смахнули при отпускании → `dismissWithDrag` (карта улетает, потом гаснет фон).
    /// 2) Иначе — возврат: короткое движение только пружина; длиннее — инерция + пружина в центр. Тап по карте не закрывает.
    private func handleDragEnded(_ value: DragGesture.Value) {
        cardDragActive = false
        dragGrabFeedbackStarted = false
        let dx = value.translation.width
        let dy = value.translation.height
        let distance = hypot(dx, dy)
        let vx = value.predictedEndLocation.x - value.location.x
        let vy = value.predictedEndLocation.y - value.location.y
        let velocity = hypot(vx, vy)
        let cfg = ShareCardDragConfig.self

        // Закрытие жестом: порог по расстоянию или по скорости отпускания
        if distance > cfg.dismissDistanceThreshold || velocity > cfg.dismissVelocityThreshold {
            dismissWithDrag(translation: CGSize(width: dx, height: dy), velocity: CGSize(width: vx, height: vy))
            return
        }

        withAnimation(.easeOut(duration: cfg.grabAnimationDuration)) {
            cardInteractionScale = 1
        }

        let springBack = {
            DispatchQueue.main.async {
                withAnimation(.spring(response: cfg.returnSpringResponse, dampingFraction: cfg.returnSpringDamping)) {
                    dragOffset = .zero
                    dragRotation = 0
                }
            }
        }

        // Малое смещение
        if distance < cfg.noInertiaMaxReleaseDistance {
            springBack()
            return
        }

        let ax = Double(grabAnchor.x) - 0.5
        let ay = Double(grabAnchor.y) - 0.5
        let angularVel = cfg.rotationSensitivity * (ax * Double(vy) - ay * Double(vx))
        dragOffset = CGSize(width: dragOffset.width + vx * cfg.inertiaTranslationFactor,
                            height: dragOffset.height + vy * cfg.inertiaTranslationFactor)
        dragRotation += angularVel * cfg.inertiaRotationFactor
        // Инерция по направлению отпускания, затем пружина в исходное положение
        springBack()
    }

    /// Блок с кнопками снизу
    private var shareBottomBlock: some View {
        VStack(spacing: 24) {
            Text("Share with friends")
                .font(.Text1)
                .foregroundColor(.fill1)
                .lineSpacing(5)
                .opacity(bottomBlockOpacity)
            HStack(spacing: 16) {
                ForEach(Array(shareBottomActionItems.enumerated()), id: \.offset) { index, item in
                    ShareActionButton(iconName: item.icon, label: item.label)
                        .opacity(shareButtonOpacity[index])
                        .offset(y: shareButtonOffsetY[index])
                }
            }
        }
        .padding(.bottom, 32)
    }

    private func runOpenAnimation(session: UInt64) {
        blurOpacity = 0
        cardOpacity = 0
        cardScale = ShareOverlayOpenConfig.initialCardScale
        bottomBlockOpacity = 0
        bottomBlockOffsetY = ShareOverlayOpenConfig.bottomOffsetY
        shareButtonOpacity = Array(repeating: 0, count: shareBottomActionItems.count)
        shareButtonOffsetY = Array(
            repeating: ShareOverlayOpenConfig.bottomButtonInitialOffsetY,
            count: shareBottomActionItems.count
        )
        closeButtonOpacity = 0
        dragOffset = .zero
        dragRotation = 0
        grabAnchor = .center
        cardDragActive = false
        closeButtonVisibleAfterDrag = 1
        cardInteractionScale = 1
        dragGrabFeedbackStarted = false

        let open = ShareOverlayOpenConfig.self
        withAnimation(.easeOut(duration: open.blurIn)) { blurOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + open.cardAndBottomDelay) {
            guard session == openAnimSession else { return }
            withAnimation(.easeOut(duration: open.cardIn)) {
                cardOpacity = 1
                cardScale = 1
            }
            withAnimation(.easeOut(duration: open.bottomIn)) {
                bottomBlockOpacity = 1
                bottomBlockOffsetY = 0
                closeButtonOpacity = 1
            }
            let stagger = open.bottomButtonStagger
            let itemIn = open.bottomButtonItemIn
            for index in shareBottomActionItems.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + stagger * Double(index)) {
                    guard session == openAnimSession else { return }
                    withAnimation(.easeOut(duration: itemIn)) {
                        shareButtonOpacity[index] = 1
                        shareButtonOffsetY[index] = 0
                    }
                }
            }
        }
    }

    /// Закрытие тапом по фону или крестик
    private func dismiss() {
        let d = ShareOverlayDismissConfig.self
        withAnimation(.easeIn(duration: d.contentOut)) {
            closeButtonOpacity = 0
            bottomBlockOpacity = 0
            bottomBlockOffsetY = ShareOverlayOpenConfig.bottomOffsetY
            shareButtonOpacity = Array(repeating: 0, count: shareBottomActionItems.count)
            shareButtonOffsetY = Array(
                repeating: ShareOverlayOpenConfig.bottomButtonInitialOffsetY,
                count: shareBottomActionItems.count
            )
            cardOpacity = 0
            cardScale = ShareOverlayOpenConfig.initialCardScale
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d.contentOut) {
            withAnimation(.easeIn(duration: d.blurOut)) { blurOpacity = 0 }
        }
        shareOverlayState.scheduleRemovalAfterAnimation(d.contentOut + d.blurOut)
    }

    /// Закрытие через «выброс» карточки
    private func dismissWithDrag(translation: CGSize, velocity: CGSize) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        let cfg = ShareCardDragConfig.self
        let tx = translation.width + velocity.width * cfg.flyVelocityBoost
        let ty = translation.height + velocity.height * cfg.flyVelocityBoost
        let norm = hypot(tx, ty)
        let ux = norm > 1 ? tx / norm : 1
        let uy = norm > 1 ? ty / norm : 0
        let ax = Double(grabAnchor.x) - 0.5
        let ay = Double(grabAnchor.y) - 0.5
        let flyX = ux * cfg.flyOutDistance
        let flyY = uy * cfg.flyOutDistance
        let totalDx = translation.width + flyX
        let totalDy = translation.height + flyY
        let finalRotation = cfg.rotationSensitivity * (ax * Double(totalDy) - ay * Double(totalDx))

        // Карточка уезжает за экран; крестик и нижний блок сразу гаснут
        withAnimation(.easeOut(duration: cfg.flyOutDuration)) {
            closeButtonOpacity = 0
            bottomBlockOpacity = 0
            bottomBlockOffsetY = ShareOverlayOpenConfig.bottomOffsetY
            shareButtonOpacity = Array(repeating: 0, count: shareBottomActionItems.count)
            shareButtonOffsetY = Array(
                repeating: ShareOverlayOpenConfig.bottomButtonInitialOffsetY,
                count: shareBottomActionItems.count
            )
            dragOffset = CGSize(width: totalDx, height: totalDy)
            dragRotation = finalRotation
        }
        // После вылета — быстро гасим blur, затем убираем оверлей из дерева
        DispatchQueue.main.asyncAfter(deadline: .now() + cfg.flyOutDuration) {
            withAnimation(.easeIn(duration: cfg.blurFadeAfterFlyDuration)) { blurOpacity = 0 }
        }
        shareOverlayState.scheduleRemovalAfterAnimation(cfg.flyOutDuration + cfg.blurFadeAfterFlyDuration)
    }
}

// Кнопка шеринга
private struct ShareActionButton: View {
    let iconName: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.fill1)
                    .frame(width: 24, height: 24)
            }
            Text(label)
                .font(.Text2)
                .foregroundColor(.subtitle)
                .lineSpacing(3)
        }
        .frame(width: 64)
    }
}

#Preview {
    ShareOverlayPreviewHost()
}

private struct ShareOverlayPreviewHost: View {
    @StateObject private var shareOverlayState = ShareOverlayState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let entity = shareOverlayState.presentedShareEntity {
                ShareOverlay(entity: entity)
                    .environmentObject(shareOverlayState)
                    .id(shareOverlayState.presentationID)
            }
        }
        .onAppear {
            shareOverlayState.present(
                .album(
                    title: "Videotape",
                    artistName: "Tame Impala",
                    releaseYear: 2026,
                    coverImageName: "album",
                    artistImageName: "userpic"
                )
            )
        }
    }
}
