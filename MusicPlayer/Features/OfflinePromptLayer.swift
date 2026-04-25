import SwiftUI

private enum OfflinePromptEntrance {
    static let animationDuration: TimeInterval = 0.7
    /// Текст и кнопка: старт ниже на эти pt.
    static let contentOffsetY: CGFloat = 24
    static let contentBlurStart: CGFloat = 10
    /// Доля высоты экрана: доп. сдвиг блобов вниз при progress=0 (выезжают снизу).
    static let blobExtraYOffsetFactor: CGFloat = 0.36
    /// При скрытии: за эту долю хода `entranceProgress` 1→0 контент уже полностью уходит (блобы — на всю длительность). Меньше — быстрее.
    static let contentExitFadeFraction: CGFloat = 0.42

    /// Прогресс для заголовка/кнопки: при выходе быстрее, чем `p` у блобов.
    static func contentProgress(entranceProgress p: CGFloat, isExiting: Bool) -> CGFloat {
        if isExiting {
            let u = max(contentExitFadeFraction, 0.05)
            return 1 - min(1, (1 - p) / u)
        }
        return p
    }
}

/// Полноэкранный слой: блоб и зерно на весь экран (без обрезки лучей сверху); верхняя половина — тап закрывает; текст и кнопка снизу.
struct OfflinePromptLayer: View {
    /// Высота зоны «тап = закрыть» (верх экрана).
    static let contentRegionFraction: CGFloat = 0.5

    /// Ниже, чем раньше: через размытие блобов меньше «грязнит» насыщенность краёв.
    private static let scrimOpacity: CGFloat = 0.1

    var onDismiss: () -> Void
    var onGoOffline: () -> Void

    @State private var entranceProgress: CGFloat = 0
    @State private var isExiting = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let totalH = geo.size.height
            let topH = totalH * Self.contentRegionFraction
            let p = entranceProgress
            let contentP = OfflinePromptEntrance.contentProgress(entranceProgress: p, isExiting: isExiting)
            let timelineActive = p > 0.02

            ZStack {
                Color.black.opacity(Self.scrimOpacity * p)
                    .ignoresSafeArea()
                    .frame(width: w, height: totalH)

                OfflineGlowBackground(
                    size: CGSize(width: w, height: totalH),
                    isPresented: timelineActive,
                    entranceProgress: p,
                    entranceExtraYFactor: OfflinePromptEntrance.blobExtraYOffsetFactor,
                    mainBlob: Self.mainBlobConfig(in: CGSize(width: w, height: totalH)),
                    accents: Self.accentsConfig()
                )

                LowerHazeGrainOverlay(width: w, height: totalH, isPaused: !timelineActive)
                    .opacity(LowerHazeGrainLayerOpacity.offlinePrompt * p)
            }
            .frame(width: w, height: totalH)
            .overlay(alignment: .bottom) {
                VStack(spacing: 24) {
                    Text("Internet seems\nto be down")
                        .font(.Headline3)
                        .foregroundStyle(Color.fill1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 270)

                    Button(action: onGoOffline) {
                        Text("Go Offline")
                            .font(.Text1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 22)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isExiting)
                }
                .offset(y: OfflinePromptEntrance.contentOffsetY * (1 - contentP))
                .opacity(contentP)
                .blur(radius: OfflinePromptEntrance.contentBlurStart * (1 - contentP))
                .padding(.horizontal, 52)
                .padding(.bottom, geo.safeAreaInsets.bottom + 104)
            }
            .overlay(alignment: .top) {
                Color.clear
                    .frame(height: topH)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: dismissWithAnimation)
            }
        }
        .onAppear {
            isExiting = false
            entranceProgress = 0
            withAnimation(.smooth(duration: OfflinePromptEntrance.animationDuration)) {
                entranceProgress = 1
            }
        }
    }

    /// Обратная анимация появления, затем снятие слоя родителем.
    private func dismissWithAnimation() {
        guard !isExiting else { return }
        isExiting = true
        let d = OfflinePromptEntrance.animationDuration
        withAnimation(.smooth(duration: d)) {
            entranceProgress = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) {
            onDismiss()
        }
    }

    /// Полноэкранный prompt: огромная клякса, виден только её фрагмент через окно экрана. Размер подгоняется под экран
    /// формулой `fittedSize × userScale` — чтобы геометрия + wobble + blur не вылезали за рамки rotation.
    private static func mainBlobConfig(in size: CGSize) -> OfflineMainBlobConfig {
        let (fittedW, fittedH) = fittedSize(in: size, widthScale: 2.85, heightScale: 3.25, blurRadius: 48)
        let userScale: CGFloat = 7
        return OfflineMainBlobConfig(
            width: fittedW * userScale,
            height: fittedH * userScale,
            blurRadius: 48,
            offsetY: size.height * 0.68,
            rotationPeriodSeconds: 30,
            opacityBreath: 0.94...1.0,
            opacityBreathPeriod: 7,
            phaseSpeed: 0.85,
            stretchToAspect: false,
            clipsToBounds: true
        )
    }

    private static func accentsConfig() -> OfflineAccentBlobsConfig {
        OfflineAccentBlobsConfig(
            blob1Size: CGSize(width: 300, height: 300),
            blob2Size: CGSize(width: 320, height: 340),
            blob3Size: CGSize(width: 320, height: 230),
            blurRadius: 74,
            opacityMax: 0.88,
            opacityPeriod: 8,
            verticalRangeFactor: 0.06...0.48,
            horizontalMarginFactor: 0.12,
            horizontalMarginMin: 48
        )
    }

    /// Подгоняет размер кляксы под `(specW × specH)`, чтобы wobble + blur + поворот не вылезали за rotation-радиус.
    private static func fittedSize(in size: CGSize, widthScale: CGFloat, heightScale: CGFloat, blurRadius: CGFloat) -> (CGFloat, CGFloat) {
        let sw = max(size.width, 1)
        let sh = max(size.height, 1)
        let baseW = sw * widthScale
        let baseH = sh * heightScale
        let rGeom = min(baseW, baseH) * 0.5 * 1.4 // wobbleRadiusFactor
        let maxHalf = min(sw, sh) * 0.5 * 0.88 - 8 // rotationFit / edgeMargin
        guard maxHalf > blurRadius + 2 else {
            return (baseW * 0.22, baseH * 0.22)
        }
        let fitScale = min(1, (maxHalf - blurRadius) / max(rGeom, 1e-4))
        return (baseW * fitScale, baseH * fitScale)
    }
}

#Preview {
    #if canImport(UIKit)
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        OfflinePromptLayer(
            onDismiss: {},
            onGoOffline: {}
        )
        .ignoresSafeArea()
    }
    #else
    Color.black
    #endif
}
