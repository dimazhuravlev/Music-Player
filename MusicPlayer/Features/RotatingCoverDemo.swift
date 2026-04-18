import SwiftUI

/// Демо-компонент: круглый кавер с инерционным вращением при старте и остановке.
///
/// Механика инерции:
/// Каждый кадр текущая скорость (`currentSpeed`) приближается к целевой на 4%
/// от оставшейся разницы — это классический lerp (экспоненциальное сглаживание).
/// Работает одинаково для разгона (isPlaying = true → target = 60°/с)
/// и торможения (isPlaying = false → target = 0°/с).
struct RotatingCoverDemo: View {

    @Binding var isPlaying: Bool

    /// Имя asset'а обложки
    let coverImage: String

    @State private var rotation: Double = 0
    @State private var lastUpdateTime: Date = Date()
    @State private var currentSpeed: Double = 0

    /// Конечная скорость вращения, градусов в секунду
    private let targetSpeed: Double = 60

    /// Коэффициент lerp — доля сближения с целевой скоростью за один кадр.
    /// Увеличить (напр. 0.08) → быстрее разгон/торможение.
    /// Уменьшить (напр. 0.02) → медленнее, более «тяжёлый» маховик.
    private let lerpFactor: Double = 0.04

    var body: some View {
        TimelineView(.animation) { timeline in
            Image(coverImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
                .onChange(of: timeline.date) { _, newTime in
                    let delta = newTime.timeIntervalSince(lastUpdateTime)
                    lastUpdateTime = newTime

                    // Плавно тянемся к целевой скорости (0 или targetSpeed)
                    let target = isPlaying ? targetSpeed : 0
                    currentSpeed += (target - currentSpeed) * lerpFactor

                    rotation += currentSpeed * delta
                    rotation = rotation.truncatingRemainder(dividingBy: 360)
                }
        }
    }
}

#Preview {
    @Previewable @State var isPlaying = false

    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 24) {
            RotatingCoverDemo(isPlaying: $isPlaying, coverImage: "album")
            Button(isPlaying ? "Пауза" : "Играть") {
                isPlaying.toggle()
            }
            .foregroundColor(.white)
        }
    }
}
