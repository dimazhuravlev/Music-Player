import SwiftUI

/// Offline flash: поднимающаяся заливка + фоновый блоб + 7 цветных блобов + белая изогнутая волна; синхронно с `coverProgress`.
///
/// **Нижняя дымка** — полноэкранный слой под шейдером (`ZStack`). Видна там, где пиксели шейдера прозрачны.
///
/// `exitProgress` — растворение оверлея. `waveProgress` / `waveProgressB` зарезервированы (передаём 0).
/// `blobColorSlots` — перестановка индексов палитры 0…6 для семи слотов блобов (задаётся при старте перехода).
/// `blobRadii` — радиусы гаусса для слотов b0…b6 в UV-метрике шейдера (случайные при каждом запуске).
/// `coloredBlobsOpacity` — общая непрозрачность семи цветных блобов (фон и белая волна не затрагиваются).
/// `redirectCoverProgress` — для шейдера / редиректа в MusicApp (не задаёт тайминг дымки).
struct OfflineFlashOverlay: View {
    var coverProgress: CGFloat
    var exitProgress: CGFloat
    var waveProgress: CGFloat = 0
    var waveProgressB: CGFloat = 0
    var isReversed: Bool = false
    /// Семь значений 0…6: какой оттенок палитры у слота b0…b6.
    var blobColorSlots: [CGFloat] = [0, 1, 2, 3, 4, 5, 6].map { CGFloat($0) }
    var blobRadii: [CGFloat] = Array(repeating: 0.25, count: 7)
    var coloredBlobsOpacity: CGFloat = 0.45
    var redirectCoverProgress: CGFloat = 0.55

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let slots = blobColorSlots.count == 7 ? blobColorSlots : [0, 1, 2, 3, 4, 5, 6].map { CGFloat($0) }
            let radii = blobRadii.count == 7 ? blobRadii : Array(repeating: 0.25, count: 7)
            let hazeOpacity = Self.lowerHazeOpacity(
                coverProgress: coverProgress,
                exitProgress: exitProgress,
                isReversed: isReversed
            )

            ZStack {
                Rectangle()
                    .fill(Self.lowerHazeFillColor)
                    .opacity(hazeOpacity)
                Rectangle()
                    .fill(Color.white)
                    .colorEffect(
                        ShaderLibrary.offlineFlash(
                            .float2(w, h),
                            .float(coverProgress),
                            .float(exitProgress),
                            .float(waveProgress),
                            .float(waveProgressB),
                            .float(isReversed ? 1.0 : 0.0),
                            .float(slots[0]),
                            .float(slots[1]),
                            .float(slots[2]),
                            .float(slots[3]),
                            .float(slots[4]),
                            .float(slots[5]),
                            .float(slots[6]),
                            .float(radii[0]),
                            .float(radii[1]),
                            .float(radii[2]),
                            .float(radii[3]),
                            .float(radii[4]),
                            .float(radii[5]),
                            .float(radii[6]),
                            .float(coloredBlobsOpacity),
                            .float(redirectCoverProgress)
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .compositingGroup()
        .drawingGroup(opaque: false)
    }
}

// MARK: - Нижняя дымка

extension OfflineFlashOverlay {
    /// `true` — яркий цвет и высокая opacity (проверка слоя). Потом выключить.
    fileprivate static let lowerHazeDebugProminent = true

    /// Начало непрозрачности дымки — линейная фаза `coverProgress` 0→1 (выше — короче «полный» зелёный до конца cover).
    fileprivate static let lowerHazeAppearCoverProgress: Double = 0.58

    /// Вход в offline: от этой доли `cover` до 1 снимаем только часть яркости (см. `lowerHazeCoverFadeOutEndFactor`), чтобы не было полной «полки» до конца блобов, но зелёный к финалу cover оставался виден — дальше гаснет `offlineFlashVisualOpacity` в MusicApp.
    fileprivate static let lowerHazeCoverFadeOutStart: Double = 0.82

    /// К концу фазы cover остаётся эта доля от пика (0…1); не 0 — иначе зелёного не видно перед финальным fade оверлея.
    fileprivate static let lowerHazeCoverFadeOutEndFactor: Double = 0.62

    fileprivate static var lowerHazeFillColor: Color {
        if lowerHazeDebugProminent {
            return Color(red: 0, green: 1, blue: 140.0 / 255.0)
        }
        return Color(red: 125 / 255, green: 0, blue: 228 / 255)
    }

    fileprivate static var lowerHazeMaxOpacity: CGFloat {
        0.6
    }

    /// Степень < 1 — зелёный слой дольше держится, затем мягче уходит; в паре с длительностью exit в MusicApp даёт плавный спад.
    fileprivate static let lowerHazeExitFadeEaseExponent: Double = 0.32

    fileprivate static func lowerHazeOpacity(
        coverProgress: CGFloat,
        exitProgress: CGFloat,
        isReversed: Bool
    ) -> CGFloat {
        let c = Double(min(1, max(0, coverProgress)))
        let e = Double(min(1, max(0, exitProgress)))
        let appear = lowerHazeAppearCoverProgress
        if c < appear { return 0 }
        let base = lowerHazeMaxOpacity

        if !isReversed {
            // Вход в offline: в хвосте cover слегка приглушаем зелёный (не до нуля), затем общий fade оверлея.
            let endFactor = min(max(lowerHazeCoverFadeOutEndFactor, 0.15), 1.0)
            if c < 1.0 - 1e-6 {
                let fadeStart = min(max(lowerHazeCoverFadeOutStart, appear + 0.02), 0.97)
                if c < fadeStart { return CGFloat(base) }
                let t = (c - fadeStart) / (1.0 - fadeStart)
                let factor = 1.0 - t * (1.0 - endFactor)
                return CGFloat(base * factor)
            }
            return CGFloat(base * endFactor)
        }

        // Обратная вспышка (выход): плато до конца cover, затем спад по exitProgress.
        if c < 1.0 - 1e-6 { return CGFloat(base) }
        let eased = pow(1.0 - e, lowerHazeExitFadeEaseExponent)
        return CGFloat(base * eased)
    }
}

/*
 MARK: See `OfflineFlash.metal` — движение и стаггер заданы в шейдере от `coverProgress`.
 */

// MARK: - Debug Previews

#Preview("Early") {
    ZStack {
        Color.black
        OfflineFlashOverlay(coverProgress: 0.2, exitProgress: 0, waveProgress: 0.15)
    }
}

#Preview("Mid seal") {
    ZStack {
        Color.black
        OfflineFlashOverlay(coverProgress: 0.55, exitProgress: 0, waveProgress: 0.72)
    }
}

#Preview("Exit") {
    ZStack {
        Color.black
        OfflineFlashOverlay(coverProgress: 1, exitProgress: 0.5, waveProgress: 1)
    }
}
