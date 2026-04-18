import SwiftUI

/// Мягкое пятно под таббаром Offline: скруглённая «капсула» с градиентом, поворот и сильный blur (по духу макета).
/// `intensity` 0…1 — синхронизируется с затуханием полноэкранной вспышки.
struct OfflineHeaderGlow: View {
    var intensity: Double

    /// Макет ~430pt по ширине; координаты и размеры масштабируются от `w`.
    private let designWidth: CGFloat = 430
    private let designHeight: CGFloat = 932

    private var accentA: Color { Color(red: 0.64, green: 0.2, blue: 1) }
    private var accentB: Color { Color(red: 0.82, green: 0.15, blue: 1) }

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let sx = w / designWidth
            let sy = h / designHeight

            let blobW = 433.38614 * sx
            let blobH = 171.52238 * sx
            let centerX = w / 2
            let centerY = 6.0314 * sy + geo.safeAreaInsets.top * 0.35 + 30 - 52
            let cornerR = min(blobW, blobH) / 2
            // Сильный blur на чёрном почти гасит слой — держим ниже макетных 70, чтобы пятно читалось
            let blurR = min(120, max(100, 110 * sx))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: accentA.opacity(0.95 * intensity), location: 0),
                                .init(color: accentB.opacity(0.82 * intensity), location: 1)
                            ],
                            startPoint: UnitPoint(x: 1, y: 0.63),
                            endPoint: UnitPoint(x: 0, y: 0.37)
                        )
                    )
                    .frame(width: blobW, height: blobH)
                    .blur(radius: blurR)
                    .blendMode(.plusLighter)
                    .position(x: centerX, y: centerY)

                // Второй, более резкий слой — ядро свечения (лёгкий blur)
                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: accentA.opacity(0.42 * intensity), location: 0),
                                .init(color: accentB.opacity(0.28 * intensity), location: 1)
                            ],
                            startPoint: UnitPoint(x: 1, y: 0.63),
                            endPoint: UnitPoint(x: 0, y: 0.37)
                        )
                    )
                    .frame(width: blobW * 0.92, height: blobH * 0.88)
                    .blur(radius: min(52, 44 * sx))
                    .blendMode(.plusLighter)
                    .position(x: centerX, y: centerY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    ZStack {
        Color.black
        OfflineHeaderGlow(intensity: 1)
    }
}
