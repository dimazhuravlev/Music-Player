import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reaction

private enum Reaction: Int, CaseIterable {
    case dislike = 0  // 👎
    case neutral = 1  // 😐
    case like = 2     // 👍
    case love = 3     // ❤️

    var emoji: String {
        switch self {
        case .dislike: return "🤢"
        case .neutral: return "😐"
        case .like:    return "👍"
        case .love:    return "❤️"
        }
    }
}

private let reactionCount = Reaction.allCases.count

// MARK: - Config

private enum OverflowCardConfig {
    static let cardWidth: CGFloat = 254
    static let coverSize: CGFloat = 176
    static let coverCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 18
    static let cardPadding: CGFloat = 8

    /// Карточка открывается с небольшим дефолтным наклоном.
    static let defaultRotation: Double = 3
    /// Начальный наклон при появлении (анимируется до defaultRotation).
    static let entryRotation: Double = -4

    /// Первый порог свайпа: 👍 (вправо) или 😐 (влево).
    static let reactionThreshold1: CGFloat = 100
    /// Второй порог свайпа: ❤️ (вправо) или 👎 (влево).
    static let reactionThreshold2: CGFloat = 160
    /// Шаг последовательного перехода между реакциями (когда уже есть активная).
    static let reactionStepSize: CGFloat = 80

    static let grabScale: CGFloat = 0.97
    static let grabAnimationDuration: Double = 0.18
    static let minDragBeforeGrabFeedback: CGFloat = 4

    static let returnSpringResponse: Double = 0.48
    static let returnSpringDamping: Double = 0.68

    static let rotationSensitivity: Double = 0.14
    /// Вертикальное движение карточки приглушается.
    static let verticalDampening: CGFloat = 0.35

    /// Макс. смещение кнопок реакций следом за карточкой.
    static let buttonParallaxMax: CGFloat = 14
    static let buttonParallaxFactor: CGFloat = 0.14
}

private enum OverflowMenuOpenConfig {
    static let blurIn: Double = 0.25
    static let cardAndBottomDelay: Double = 0.15
    static let cardIn: Double = 0.3
    static let initialCardScale: CGFloat = 0.96
}

private enum OverflowMenuDismissConfig {
    static let contentOut: Double = 0.28
    static let blurOut: Double = 0.36
}

// MARK: - PreferenceKeys

private struct OverflowCardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let h = nextValue(); if h > 0 { value = h }
    }
}


// MARK: - OverflowMenu

struct OverflowMenu: View {
    let entity: ShareableEntity

    @EnvironmentObject private var overflowMenuState: OverflowMenuState

    // Open animation
    @State private var openAnimSession: UInt64 = 0
    @State private var blurOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var cardScale: CGFloat = OverflowMenuOpenConfig.initialCardScale
    @State private var closeButtonOpacity: Double = 0

    // Drag
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = OverflowCardConfig.defaultRotation
    @State private var grabAnchor: UnitPoint = .center
    @State private var cardDragActive = false
    @State private var cardInteractionScale: CGFloat = 1
    @State private var dragGrabFeedbackStarted = false
    @State private var cardLayoutHeight: CGFloat = 300

    // Reactions (4 emoji buttons)
    @State private var emojiButtonOpacity: [Double] = Array(repeating: 0, count: reactionCount)
    @State private var emojiButtonOffsetY: [CGFloat] = Array(repeating: 10, count: reactionCount)
    @State private var activeReaction: Reaction? = nil
    @State private var reactionProgress: [CGFloat] = Array(repeating: 0, count: reactionCount)
    @State private var reactionBounce: [CGFloat] = Array(repeating: 1, count: reactionCount)
    @State private var progressBeforeDrag: [CGFloat] = Array(repeating: 0, count: reactionCount)

    // MARK: Body

    var body: some View {
        ZStack {
            // Слой 1: фон + тап в пустоту закрывает.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.black.opacity(0.52))
                    }
                    .opacity(blurOpacity)
                    .ignoresSafeArea()
                )

            // Слой 2: контент — реакции + карточка, вертикально по центру экрана.
            VStack(spacing: 28) {
                // Кнопки реакций над карточкой.
                reactionRow
                    .offset(x: reactionButtonsParallax.width, y: reactionButtonsParallax.height)
                    .opacity(cardOpacity)

                // Карточка сущности
                cardWithDrag
                    .opacity(cardOpacity)
                    .scaleEffect(cardScale * cardInteractionScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(alignment: .topTrailing) {
                closeButton
                    .opacity(closeButtonOpacity)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
        }
        .onAppear {
            openAnimSession += 1
            runOpenAnimation(session: openAnimSession)
        }
    }

    // MARK: Parallax

    /// Кнопки плавно следуют за карточкой в пределах ±24pt.
    private var reactionButtonsParallax: CGSize {
        let f = OverflowCardConfig.buttonParallaxFactor
        let cap = OverflowCardConfig.buttonParallaxMax
        return CGSize(
            width: max(-cap, min(cap, dragOffset.width * f)),
            height: max(-cap, min(cap, dragOffset.height * f))
        )
    }

    // MARK: Close Button

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

    // MARK: Card

    private var cardHasMetaRow: Bool { entity.subtitle != nil || entity.year != nil }

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Обложка
            CachedAsyncImage(url: entity.coverImageURL, assetName: entity.coverImageName)
                .frame(width: OverflowCardConfig.coverSize, height: OverflowCardConfig.coverSize)
                .clipShape(RoundedRectangle(cornerRadius: OverflowCardConfig.coverCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: OverflowCardConfig.coverCornerRadius)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 2)
                .padding(.bottom, 10)

            // Название
            Text(entity.title)
                .font(.Headline5)   // 24px
                .foregroundColor(.fill1)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: OverflowCardConfig.coverSize, alignment: .leading)
                .padding(.bottom, cardHasMetaRow ? 6 : 0)

            // Мета-строка (артист / год)
            if cardHasMetaRow {
                HStack(spacing: 8) {
                    if entity.artistImageURL != nil || entity.artistImageName != nil {
                        CachedAsyncImage(url: entity.artistImageURL, assetName: entity.artistImageName ?? "album")
                            .frame(width: 32, height: 32)
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
                .frame(width: OverflowCardConfig.coverSize, height: 32)
            }
        }
        // Единый отступ по кругу 8pt — задаёт внутренний padding карточки.
        .padding(OverflowCardConfig.cardPadding)
        .background(
            ZStack {
                Color.white.opacity(0.08)
                GeometryReader { geo in
                    Color.clear.preference(key: OverflowCardHeightKey.self, value: geo.size.height)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: OverflowCardConfig.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: OverflowCardConfig.cardCornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
        )
        .contentShape(Rectangle())
    }

    private var cardWithDrag: some View {
        cardContent
            .onPreferenceChange(OverflowCardHeightKey.self) { h in
                if h > 0 { cardLayoutHeight = h }
            }
            .offset(x: dragOffset.width, y: dragOffset.height)
            .rotationEffect(.degrees(dragRotation), anchor: grabAnchor)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged(handleDragChanged)
                    .onEnded(handleDragEnded)
            )
    }

    // MARK: Reaction Row (4 emoji buttons)

    /// Доп. отступ вокруг активной кнопки — соседи расходятся.
    private let reactionSpreadMax: CGFloat = 6

    private var reactionRow: some View {
        HStack(spacing: 16) {
            ForEach(Reaction.allCases, id: \.rawValue) { reaction in
                let i = reaction.rawValue
                let spread = min(1, reactionProgress[i]) * reactionSpreadMax
                OverflowEmojiButton(
                    emoji: reaction.emoji,
                    progress: reactionProgress[i],
                    bounceScale: reactionBounce[i],
                    onTap: { triggerReaction(reaction) }
                )
                .padding(.horizontal, spread)
                .opacity(emojiButtonOpacity[i])
                .offset(y: emojiButtonOffsetY[i])
            }
        }
    }

    // MARK: Reaction Actions

    private func triggerReaction(_ reaction: Reaction) {
        let isDeactivating = activeReaction == reaction
        activeReaction = isDeactivating ? nil : reaction
        bounceReaction(reaction)
        withAnimation(.spring(response: OverflowCardConfig.returnSpringResponse,
                              dampingFraction: OverflowCardConfig.returnSpringDamping)) {
            for i in 0..<reactionCount {
                reactionProgress[i] = (activeReaction?.rawValue == i) ? 1 : 0
            }
        }
    }

    private func successHaptic() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func thresholdHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func bounceReaction(_ reaction: Reaction) {
        successHaptic()
        let i = reaction.rawValue
        let bounceAnim = Animation.easeOut(duration: 0.08)
        let returnAnim = Animation.spring(response: 0.25, dampingFraction: 0.55)
        withAnimation(bounceAnim) { reactionBounce[i] = 1.2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(returnAnim) { reactionBounce[i] = 1 }
        }
    }

    // MARK: Drag Handlers

    /// Реакция на момент начала драга — определяет режим (absolute vs sequential).
    @State private var reactionBeforeDrag: Reaction? = nil
    /// Ближайший индекс реакции во время драга (для хаптика при смене). -1 = нет.
    @State private var lastDragNearestIndex: Int = -1

    // -- Absolute mode helpers (нет активной реакции) --

    private func dragZone(for dx: CGFloat) -> Int {
        let t1 = OverflowCardConfig.reactionThreshold1
        let t2 = OverflowCardConfig.reactionThreshold2
        let absDx = abs(dx)
        if absDx < t1 { return 0 }
        let sign = dx > 0 ? 1 : -1
        return absDx < t2 ? sign : sign * 2
    }

    private func reactionForZone(_ zone: Int) -> Reaction? {
        switch zone {
        case  1: return .like
        case  2: return .love
        case -1: return .neutral
        case -2: return .dislike
        default: return nil
        }
    }

    // -- Sequential mode helpers (есть активная реакция) --

    /// Вычислить непрерывный курсор на шкале реакций 0…3 из позиции драга.
    private func sequentialCursor(dx: CGFloat, startIndex: Int) -> CGFloat {
        let step = OverflowCardConfig.reactionStepSize
        let cursor = CGFloat(startIndex) + dx / step
        return max(0, min(CGFloat(reactionCount - 1), cursor))
    }

    /// Прогресс каждой реакции по курсору: 1 когда курсор точно на ней, 0 на расстоянии ≥1.
    private func progressFromCursor(_ cursor: CGFloat) -> [CGFloat] {
        (0..<reactionCount).map { i in
            max(0, 1 - abs(cursor - CGFloat(i)))
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        if !cardDragActive {
            cardDragActive = true
            reactionBeforeDrag = activeReaction
            lastDragNearestIndex = activeReaction?.rawValue ?? -1
            for i in 0..<reactionCount {
                progressBeforeDrag[i] = reactionProgress[i]
            }
            let w = OverflowCardConfig.cardWidth
            let h = max(cardLayoutHeight, 180)
            grabAnchor = UnitPoint(
                x: max(0.05, min(0.95, value.startLocation.x / w)),
                y: max(0.05, min(0.95, value.startLocation.y / h))
            )
        }

        let dx = value.translation.width
        let dy = value.translation.height

        if hypot(dx, dy) > OverflowCardConfig.minDragBeforeGrabFeedback, !dragGrabFeedbackStarted {
            dragGrabFeedbackStarted = true
            withAnimation(.easeOut(duration: OverflowCardConfig.grabAnimationDuration)) {
                cardInteractionScale = OverflowCardConfig.grabScale
            }
        }

        // Вычислить прогресс кнопок.
        let t1 = OverflowCardConfig.reactionThreshold1
        let absDx = abs(dx)

        if let startReaction = reactionBeforeDrag {
            // ── Sequential mode: курсор скользит по шкале 0…3 от текущей реакции.
            let cursor = sequentialCursor(dx: dx, startIndex: startReaction.rawValue)
            let targets = progressFromCursor(cursor)
            for i in 0..<reactionCount {
                reactionProgress[i] = targets[i]
            }

            // Хаптик при смене ближайшей реакции.
            let nearest = Int(round(cursor))
            if nearest != lastDragNearestIndex {
                thresholdHaptic()
                lastDragNearestIndex = nearest
            }
        } else {
            // ── Absolute mode: 2-зонная логика (нет активной реакции).
            let t2 = OverflowCardConfig.reactionThreshold2
            var targets: [CGFloat] = Array(repeating: 0, count: reactionCount)

            if dx > 0 {
                if absDx <= t1 {
                    targets[Reaction.like.rawValue] = absDx / t1
                } else {
                    let overflow = min(1, (absDx - t1) / (t2 - t1))
                    targets[Reaction.like.rawValue] = 1 - overflow
                    targets[Reaction.love.rawValue] = overflow
                }
            } else if dx < 0 {
                if absDx <= t1 {
                    targets[Reaction.neutral.rawValue] = absDx / t1
                } else {
                    let overflow = min(1, (absDx - t1) / (t2 - t1))
                    targets[Reaction.neutral.rawValue] = 1 - overflow
                    targets[Reaction.dislike.rawValue] = overflow
                }
            }

            let fadeOut = min(1, absDx / t1)
            for i in 0..<reactionCount {
                let saved = progressBeforeDrag[i]
                if targets[i] > 0 {
                    reactionProgress[i] = max(saved, targets[i])
                } else {
                    reactionProgress[i] = saved * (1 - fadeOut)
                }
            }

            // Хаптик при смене зоны.
            let zone = dragZone(for: dx)
            let zoneIndex = reactionForZone(zone)?.rawValue ?? -1
            if zoneIndex != lastDragNearestIndex {
                if zoneIndex != -1 { thresholdHaptic() }
                lastDragNearestIndex = zoneIndex
            }
        }

        // Вращение: точка захвата + плавный наклон в сторону движения (±5°).
        let tiltMax = 5.0
        let ax = Double(grabAnchor.x) - 0.5
        let ay = Double(grabAnchor.y) - 0.5
        let tiltDeg = max(-tiltMax, min(tiltMax, Double(dx) / Double(t1) * tiltMax))
        dragRotation = OverflowCardConfig.defaultRotation
            + OverflowCardConfig.rotationSensitivity * (ax * Double(dy) - ay * Double(dx))
            + tiltDeg
        dragOffset = CGSize(width: dx, height: dy * OverflowCardConfig.verticalDampening)
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        cardDragActive = false
        dragGrabFeedbackStarted = false

        let dx = value.translation.width

        withAnimation(.easeOut(duration: OverflowCardConfig.grabAnimationDuration)) {
            cardInteractionScale = 1
        }

        // Определить новую реакцию.
        var newReaction: Reaction?
        if let startReaction = reactionBeforeDrag {
            // Sequential: ближайшая реакция по курсору.
            let cursor = sequentialCursor(dx: dx, startIndex: startReaction.rawValue)
            newReaction = Reaction(rawValue: Int(round(cursor)))
        } else {
            // Absolute: по зоне.
            newReaction = reactionForZone(dragZone(for: dx))
        }

        if let r = newReaction, r != activeReaction {
            activeReaction = r
            bounceReaction(r)
        }

        // Карточка возвращается; кнопки анимируются в конечное состояние.
        withAnimation(.spring(response: OverflowCardConfig.returnSpringResponse,
                              dampingFraction: OverflowCardConfig.returnSpringDamping)) {
            dragOffset = .zero
            dragRotation = OverflowCardConfig.defaultRotation
            for i in 0..<reactionCount {
                reactionProgress[i] = (activeReaction?.rawValue == i) ? 1 : 0
            }
        }
    }

    // MARK: Open / Dismiss Animations

    private func runOpenAnimation(session: UInt64) {
        blurOpacity = 0; cardOpacity = 0; cardScale = OverflowMenuOpenConfig.initialCardScale
        closeButtonOpacity = 0
        dragOffset = .zero
        dragRotation = OverflowCardConfig.entryRotation
        grabAnchor = .center
        cardDragActive = false; cardInteractionScale = 1; dragGrabFeedbackStarted = false
        activeReaction = nil
        reactionProgress = Array(repeating: 0, count: reactionCount)
        reactionBounce = Array(repeating: 1, count: reactionCount)
        progressBeforeDrag = Array(repeating: 0, count: reactionCount)
        reactionBeforeDrag = nil
        lastDragNearestIndex = -1
        emojiButtonOpacity = Array(repeating: 0, count: reactionCount)
        emojiButtonOffsetY = Array(repeating: 10, count: reactionCount)

        let open = OverflowMenuOpenConfig.self
        withAnimation(.easeOut(duration: open.blurIn)) { blurOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + open.cardAndBottomDelay) {
            guard session == openAnimSession else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                cardOpacity = 1
                cardScale = 1
                dragRotation = OverflowCardConfig.defaultRotation
            }
            withAnimation(.easeOut(duration: 0.3)) {
                closeButtonOpacity = 1
            }
            // Staggered appearance for emoji buttons (like Share with friends)
            for index in Reaction.allCases.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(index)) {
                    guard session == openAnimSession else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        emojiButtonOpacity[index] = 1
                        emojiButtonOffsetY[index] = 0
                    }
                }
            }
        }
    }

    private func dismiss() {
        let d = OverflowMenuDismissConfig.self
        withAnimation(.easeIn(duration: d.contentOut)) {
            closeButtonOpacity = 0
            cardOpacity = 0; cardScale = OverflowMenuOpenConfig.initialCardScale
            emojiButtonOpacity = Array(repeating: 0, count: reactionCount)
            emojiButtonOffsetY = Array(repeating: 10, count: reactionCount)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d.contentOut) {
            withAnimation(.easeIn(duration: d.blurOut)) { blurOpacity = 0 }
        }
        overflowMenuState.scheduleRemovalAfterAnimation(d.contentOut + d.blurOut)
    }
}

// MARK: - Emoji Reaction Button

private struct OverflowEmojiButton: View {
    let emoji: String
    /// 0 = неактивное, 1 = активное.
    let progress: CGFloat
    var bounceScale: CGFloat = 1
    let onTap: () -> Void

    private let circleSize: CGFloat = 64

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(Double(progress) * 0.92))
                    .frame(width: circleSize, height: circleSize)
                Text(emoji)
                    .font(.system(size: 36))
            }
            .scaleEffect(bounceScale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OverflowMenuPreviewHost()
}

private struct OverflowMenuPreviewHost: View {
    @StateObject private var overflowMenuState = OverflowMenuState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let entity = overflowMenuState.presentedEntity {
                OverflowMenu(entity: entity)
                    .environmentObject(overflowMenuState)
                    .id(overflowMenuState.presentationID)
            }
        }
        .onAppear {
            overflowMenuState.present(
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
