import SwiftUI

/// 3D наклон контента по pitch/roll из `GyroManager` (как «карточка» следует за устройством).
struct Gyro3DTiltModifier: ViewModifier {
    @ObservedObject var gyro: GyroManager

    /// pitch/roll в радианах (~±0.6); множитель даёт градусы наклона.
    var intensity: Double = 11

    /// Меньше — сильнее ощущение глубины (типично 0.75…0.95).
    var perspective: CGFloat = 0.88

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(gyro.pitch * intensity),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(-gyro.roll * intensity),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: perspective
            )
            .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.74), value: gyro.pitch)
            .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.74), value: gyro.roll)
    }
}

extension View {
    func gyroscope3DTilt(
        _ gyro: GyroManager,
        intensity: Double = 11,
        perspective: CGFloat = 0.88
    ) -> some View {
        modifier(Gyro3DTiltModifier(gyro: gyro, intensity: intensity, perspective: perspective))
    }
}
