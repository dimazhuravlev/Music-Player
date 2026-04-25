import SwiftUI

/// Виджет-баннер «Offline Mode» на экране Downloads: заголовок/подзаголовок + тоггл,
/// фон — `OfflineGlowBackground` (палитра/wobbly-шейп шторки Offline), клип по rounded-rect.
struct OfflineWidget: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Offline Mode")
                    .font(.Headline5)
                    .foregroundStyle(Color.fill1)
                Text("No data used for downloads")
                    .font(.Text1)
                    .foregroundStyle(Color.offlineBannerSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            OfflineToggle(isOn: $isEnabled)
        }
        .padding(20)
        .background {
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                ZStack {
                    Color.white.opacity(0.08)
                    OfflineGlowBackground(
                        size: CGSize(width: w, height: h),
                        isPresented: true,
                        entranceProgress: 1,
                        entranceExtraYFactor: 0,
                        mainBlob: OfflineMainBlobConfig(
                            width: w * 1.6,
                            height: h * 2.2,
                            blurRadius: 24,
                            offsetY: h * 0.2,
                            rotationPeriodSeconds: 0,
                            opacityBreath: 0.15...0.25,
                            opacityBreathPeriod: 5.5,
                            phaseSpeed: 0.9,
                            stretchToAspect: true,
                            clipsToBounds: false
                        ),
                        accents: OfflineAccentBlobsConfig(
                            blob1Size: CGSize(width: 110, height: 90),
                            blob2Size: CGSize(width: 130, height: 100),
                            blob3Size: CGSize(width: 100, height: 80),
                            blurRadius: 32,
                            opacityMax: 0.12,
                            opacityPeriod: 5.5,
                            verticalRangeFactor: -0.12...0.18,
                            horizontalMarginFactor: 0.1,
                            horizontalMarginMin: 16,
                            phaseSpeed: 0.6
                        )
                    )
                    .frame(width: w, height: h)
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .inset(by: 0.33)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.66)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            // Тап по тогглу обрабатывается им самим (вложенный gesture выигрывает); тап по любой другой точке виджета — включает offline.
            guard !isEnabled else { return }
            isEnabled = true
        }
    }
}
