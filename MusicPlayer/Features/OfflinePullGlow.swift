import SwiftUI

/// Свечение под мини при оттяге Downloads (`downloadsPullChromeProgress`). Общий для `BottomBarV2` и legacy `BottomBar`.
/// Использует общий `OfflineGlowBackground` (палитра/шейп шторки Offline) — wobbly main + 3 акцентных wobbly-блоба в палитре `cBlob4/5/6`.
struct OfflinePullGlow: View {
    var progress: CGFloat
    var safeBottom: CGFloat

    /// Синхронно с `BottomBarV2.figmaMiniBottomInsetOffline` + `miniPlayerBarHeight`.
    private static let miniBottomInsetOffline: CGFloat = 60
    private static let miniPlayerBarHeight: CGFloat = 56
    /// Доп. высота снизу — клякса/блобы могут выходить за нижний край (clipsToBounds=false).
    private static let bottomBleed: CGFloat = 96
    /// Доля glowHeight: чуть приподнимаем при p=1 (визуальный «проявок» над зоной мини).
    private static let progressLift: CGFloat = 24
    /// Доля высоты для entrance: при p=0 блобы уходят вниз на эту долю h (ниже screen-edge).
    private static let entranceExtraYFactor: CGFloat = 0.5

    private static func glowHeight(safeBottom: CGFloat) -> CGFloat {
        safeBottom + miniBottomInsetOffline + miniPlayerBarHeight
    }

    var body: some View {
        let p = min(1, max(0, progress))
        let glowHeight = Self.glowHeight(safeBottom: safeBottom)
        let totalH = glowHeight + Self.bottomBleed

        GeometryReader { geo in
            let w = geo.size.width
            let size = CGSize(width: w, height: totalH)

            OfflineGlowBackground(
                size: size,
                isPresented: p > 0.001,
                entranceProgress: p,
                entranceExtraYFactor: Self.entranceExtraYFactor,
                mainBlob: Self.mainBlobConfig(width: w, totalH: totalH),
                accents: Self.accentsConfig()
            )
            .frame(width: w, height: totalH)
            .offset(y: -Self.progressLift * p)
        }
        .frame(height: totalH)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }

    /// Wobbly клякса по ширине зоны, центр — слегка ниже середины (силуэт читается над мини, не клипается сверху).
    private static func mainBlobConfig(width w: CGFloat, totalH: CGFloat) -> OfflineMainBlobConfig {
        OfflineMainBlobConfig(
            width: w * 2,
            height: totalH * 1.5,
            blurRadius: 36,
            offsetY: totalH * 0.6,
            rotationPeriodSeconds: 0,
            opacityBreath: 0.85...1.0,
            opacityBreathPeriod: 6,
            phaseSpeed: 0.95,
            stretchToAspect: true,
            clipsToBounds: false
        )
    }

    /// Акценты компактные, дрейф в нижней зоне (под мини), blur меньше — силуэты читаются.
    private static func accentsConfig() -> OfflineAccentBlobsConfig {
        OfflineAccentBlobsConfig(
            blob1Size: CGSize(width: 180, height: 150),
            blob2Size: CGSize(width: 200, height: 170),
            blob3Size: CGSize(width: 170, height: 130),
            blurRadius: 50,
            opacityMax: 0.65,
            opacityPeriod: 6.5,
            verticalRangeFactor: 0.0...0.42,
            horizontalMarginFactor: 0.18,
            horizontalMarginMin: 32,
            phaseSpeed: 0.7
        )
    }
}
