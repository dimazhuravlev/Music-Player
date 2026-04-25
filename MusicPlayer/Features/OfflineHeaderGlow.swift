import SwiftUI

/// Свечение под верхним навбаром Offline-витрины. Использует общий `OfflineGlowBackground` (палитра/шейп шторки Offline) —
/// wobbly main + 3 акцентных wobbly-блоба. Зеркалит `OfflinePullGlow`: блобы выходят за верхний край экрана, силуэт читается под навбаром.
struct OfflineHeaderGlow: View {
    /// Толщина зоны под сейф-эрией (под навбаром), где силуэт ещё виден.
    private static let topInsetOffline: CGFloat = 60
    private static let navBarHeight: CGFloat = 56
    /// Доп. высота сверху — клякса/блобы могут выходить за верхний край (clipsToBounds=false).
    private static let topBleed: CGFloat = 96

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let safeTop = geo.safeAreaInsets.top
            let glowHeight = safeTop + Self.topInsetOffline + Self.navBarHeight
            let totalH = glowHeight + Self.topBleed

            OfflineGlowBackground(
                size: CGSize(width: w, height: totalH),
                isPresented: true,
                entranceProgress: 1,
                entranceExtraYFactor: 0,
                mainBlob: Self.mainBlobConfig(width: w, totalH: totalH),
                accents: Self.accentsConfig()
            )
            .frame(width: w, height: totalH)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    /// Wobbly клякса по ширине зоны. Центр сильно сдвинут ВВЕРХ — нижний край силуэта читается под навбаром, верх уходит за край экрана.
    private static func mainBlobConfig(width w: CGFloat, totalH: CGFloat) -> OfflineMainBlobConfig {
        OfflineMainBlobConfig(
            width: w * 2,
            height: totalH * 1.5,
            blurRadius: 36,
            offsetY: -totalH * 1.0,
            rotationPeriodSeconds: 0,
            opacityBreath: 0.7...0.85,
            opacityBreathPeriod: 6,
            phaseSpeed: 0.95,
            stretchToAspect: true,
            clipsToBounds: false
        )
    }

    /// Акценты компактные, дрейф в верхней зоне (зеркальный к bottom-glow).
    private static func accentsConfig() -> OfflineAccentBlobsConfig {
        OfflineAccentBlobsConfig(
            blob1Size: CGSize(width: 180, height: 150),
            blob2Size: CGSize(width: 200, height: 170),
            blob3Size: CGSize(width: 170, height: 130),
            blurRadius: 50,
            opacityMax: 0.55,
            opacityPeriod: 6.5,
            verticalRangeFactor: -0.85...(-0.42),
            horizontalMarginFactor: 0.18,
            horizontalMarginMin: 32,
            phaseSpeed: 0.7
        )
    }
}

#Preview {
    ZStack {
        Color.black
        OfflineHeaderGlow()
    }
}
