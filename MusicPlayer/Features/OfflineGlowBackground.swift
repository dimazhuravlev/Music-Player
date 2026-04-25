import SwiftUI

/// Палитра блобов (1:1 с `OfflineFlash.metal`).
enum OfflineBlobPalette {
    /// Центр радиального градиента основной кляксы (`cBg`).
    static let mainCenter = Color(red: 163.0 / 255.0, green: 50.0 / 255.0, blue: 1.0)
    /// Край градиента (`cBlob0`).
    static let mainEdge = Color(red: 87.0 / 255.0, green: 0, blue: 181.0 / 255.0)
    /// `cBlob4`.
    static let accent1 = Color(red: 233.0 / 255.0, green: 0, blue: 31.0 / 255.0)
    /// `cBlob5`.
    static let accent2 = Color.white
    /// `cBlob6`.
    static let accent3 = Color(red: 1.0, green: 106.0 / 255.0, blue: 0)
}

/// Неровная клякса: радиус от угла + сумма синусов с tanh-ограничением.
/// `useRectAspect=true` — растягивается под пропорции rect (для широких компактных кейсов);
/// `false` — фиксированный aspect 1.24/0.78 от `min(w,h)/2` (легаси-mode для prompt'а).
struct WobblyBlobShape: Shape {
    var phase: CGFloat
    var useRectAspect: Bool = false

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r0 = min(rect.width, rect.height) * 0.5
        let halfW = rect.width * 0.5
        let halfH = rect.height * 0.5
        let steps = 288
        var path = Path()
        for i in 0...steps {
            let ang = CGFloat(i) / CGFloat(steps) * 2 * .pi
            let raw: CGFloat =
                0.18 * sin(ang * 2 + phase * 0.48)
                + 0.21 * sin(ang * 3 + phase * 0.72)
                + 0.18 * sin(ang * 4 - phase * 0.88)
                + 0.17 * sin(ang * 5 + phase * 1.08)
                + 0.15 * sin(ang * 6 - phase * 0.92)
                + 0.11 * sin(ang * 8 + phase * 0.58)
                + 0.082 * sin(ang * 10 - phase * 0.45)
                + 0.055 * sin(ang * 13 + phase * 0.36)
                + 0.036 * sin(ang * 17 - phase * 0.28)
            let k = 1 + CGFloat(tanh(Double(raw * 0.88))) * 0.5
            let x: CGFloat
            let y: CGFloat
            if useRectAspect {
                x = cx + cos(ang) * halfW * k
                y = cy + sin(ang) * halfH * k
            } else {
                x = cx + r0 * k * cos(ang) * 1.24
                y = cy + r0 * k * sin(ang) * 0.78
            }
            i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}

/// Конфиг основной кляксы.
struct OfflineMainBlobConfig {
    var width: CGFloat
    var height: CGFloat
    var blurRadius: CGFloat
    /// Сдвиг центра по Y от центра области (положительный — вниз).
    var offsetY: CGFloat
    /// Период полного оборота, сек. `0` — без вращения.
    var rotationPeriodSeconds: Double = 0
    /// Диапазон «дыхания» opacity (синус).
    var opacityBreath: ClosedRange<CGFloat> = 0.9...1.0
    var opacityBreathPeriod: Double = 6
    /// Скорость фазы wobble (фаза = `t * phaseSpeed`).
    var phaseSpeed: Double = 0.9
    /// `true` — клякса заполняет rect (halfW × halfH); `false` — фикс. aspect от `min(w,h)/2`.
    var stretchToAspect: Bool = true
    /// Обрезать по area-frame.
    var clipsToBounds: Bool = false
}

/// Конфиг трёх дрейфующих акцентных блобов (red/white/orange).
struct OfflineAccentBlobsConfig {
    var blob1Size: CGSize
    var blob2Size: CGSize
    var blob3Size: CGSize
    var blurRadius: CGFloat
    /// Пик opacity каждого блоба (модулируется синусом 0…opacityMax).
    var opacityMax: CGFloat
    var opacityPeriod: Double
    /// Y-зона дрейфа как доля h от центра области (`>0` — вниз, `<0` — вверх).
    var verticalRangeFactor: ClosedRange<CGFloat>
    /// Горизонтальный отступ от края = `max(w * factor, min)`.
    var horizontalMarginFactor: CGFloat = 0.12
    var horizontalMarginMin: CGFloat = 32
    /// Скорость фазы wobble (фаза = `t * phaseSpeed + offset_i`).
    var phaseSpeed: Double = 0.7
}

/// Облако блобов: основная wobbly-клякса + 3 акцентных.
/// Вход управляется `entranceProgress` (0…1): opacity слоя + Y-сдвиг блобов вниз при 0.
struct OfflineGlowBackground: View {
    var size: CGSize
    var isPresented: Bool
    var entranceProgress: CGFloat
    /// Доля h: доп. Y-сдвиг блобов вниз при `entranceProgress = 0`.
    var entranceExtraYFactor: CGFloat = 0
    var mainBlob: OfflineMainBlobConfig
    var accents: OfflineAccentBlobsConfig

    var body: some View {
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPresented)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let extraY = (1 - entranceProgress) * h * entranceExtraYFactor
            ZStack {
                mainBlobView(t: t, w: w, h: h, extraY: extraY)
                accentBlobsView(t: t, w: w, h: h, extraY: extraY)
            }
            .opacity(Double(entranceProgress))
            .frame(width: w, height: h)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func mainBlobView(t: TimeInterval, w: CGFloat, h: CGFloat, extraY: CGFloat) -> some View {
        let cfg = mainBlob
        let rotationDeg = cfg.rotationPeriodSeconds > 0 ? t * (360.0 / cfg.rotationPeriodSeconds) : 0
        let breath = breathOpacity(range: cfg.opacityBreath, period: cfg.opacityBreathPeriod, t: t)
        let radius = max(cfg.width, cfg.height) * 0.52
        let view = WobblyBlobShape(phase: CGFloat(t * cfg.phaseSpeed), useRectAspect: cfg.stretchToAspect)
            .fill(
                RadialGradient(
                    colors: [OfflineBlobPalette.mainCenter, OfflineBlobPalette.mainEdge],
                    center: UnitPoint(x: 0.5, y: 0.44),
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: cfg.width, height: cfg.height)
            .blur(radius: cfg.blurRadius)
            .rotationEffect(.degrees(rotationDeg))
            .offset(y: cfg.offsetY + extraY)
            .frame(width: w, height: h)
            .opacity(breath)
        if cfg.clipsToBounds {
            view.clipped()
        } else {
            view
        }
    }

    private func accentBlobsView(t: TimeInterval, w: CGFloat, h: CGFloat, extraY: CGFloat) -> some View {
        let marginX = max(w * accents.horizontalMarginFactor, accents.horizontalMarginMin)
        let xAmp = max(w * 0.5 - marginX, 40)
        let r = accents.verticalRangeFactor
        let yMid = (r.lowerBound + r.upperBound) * 0.5 * h
        let yAmp = (r.upperBound - r.lowerBound) * 0.5 * h
        let positions = accentDriftPositions(t: t, w: w, h: h, xAmp: xAmp, yMid: yMid, yAmp: yAmp)

        // Опорные параметры на каждый из 3 блобов: цвет, размер, фазы opacity и wobble.
        let phase0: Double = 0.55
        let opacityPhases = [phase0, phase0 + .pi + 0.41, phase0 + 2 * .pi / 3 + 0.19]
        let wobblePhases: [Double] = [0, 2.1, 4.3]
        let colors = [OfflineBlobPalette.accent1, OfflineBlobPalette.accent2, OfflineBlobPalette.accent3]
        let sizes = [accents.blob1Size, accents.blob2Size, accents.blob3Size]

        return ZStack {
            ForEach(0..<3, id: \.self) { i in
                let pos = positions[i]
                accentBlob(
                    t: t,
                    color: colors[i],
                    size: sizes[i],
                    offset: CGSize(width: pos.x, height: pos.y + extraY),
                    opacityPhase: opacityPhases[i],
                    wobblePhaseOffset: wobblePhases[i]
                )
            }
        }
    }

    /// Lissajous-подобный дрейф: разные частоты/фазы для трёх блобов — траектории не совпадают.
    private func accentDriftPositions(t: TimeInterval, w: CGFloat, h: CGFloat,
                                      xAmp: CGFloat, yMid: CGFloat, yAmp: CGFloat) -> [(x: CGFloat, y: CGFloat)] {
        let u1 = t * 0.42 + 0.35, v1 = t * 0.37 + 1.05
        let u2 = t * 0.36 + 2.15, v2 = t * 0.44 + 0.4
        let u3 = t * 0.4 + 1.25, v3 = t * 0.32 + 2.9
        return [
            (sin(u1) * xAmp + cos(v1 * 0.62) * (w * 0.06),
             sin(u1 * 0.71 + 0.8) * yAmp + yMid + cos(v1 * 0.45) * (h * 0.04)),
            (cos(u2) * xAmp * 0.96 + sin(v2 * 0.58) * (w * 0.07),
             cos(v2 * 0.76 + 0.2) * yAmp + yMid * 0.92 + sin(u2 * 0.5) * (h * 0.05)),
            (sin(u3 * 0.88) * xAmp * 0.91 + cos(v3 * 0.55) * (w * 0.065),
             sin(v3 * 0.63 + 0.55) * yAmp + yMid * 0.94 + cos(u3 * 0.48) * (h * 0.048))
        ]
    }

    private func accentBlob(t: TimeInterval, color: Color, size: CGSize,
                            offset: CGSize, opacityPhase: Double, wobblePhaseOffset: Double) -> some View {
        let shapePhase = CGFloat(t * accents.phaseSpeed + wobblePhaseOffset)
        let opacity = accents.opacityMax * 0.5 * CGFloat(1 + sin(2 * .pi * t / accents.opacityPeriod + opacityPhase))
        return WobblyBlobShape(phase: shapePhase, useRectAspect: true)
            .fill(color)
            .frame(width: size.width, height: size.height)
            .blur(radius: accents.blurRadius)
            .offset(offset)
            .opacity(opacity)
    }

    private func breathOpacity(range: ClosedRange<CGFloat>, period: Double, t: TimeInterval) -> CGFloat {
        let mid = (range.lowerBound + range.upperBound) * 0.5
        let amp = (range.upperBound - range.lowerBound) * 0.5
        return mid + amp * CGFloat(sin(2 * .pi * t / period))
    }
}
