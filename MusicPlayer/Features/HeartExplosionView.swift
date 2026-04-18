import SwiftUI

struct HeartExplosionView: View {
    private let heartCount = Int.random(in: 20...30)              // Кол-во сердечек
    private let appearanceRadius: ClosedRange<CGFloat> = 50...80  // Радиус появления вокруг кнопки
    private let explosionRadius: ClosedRange<CGFloat> = 20...100  // Дальность разлёта
    private let heartSize: ClosedRange<CGFloat> = 24...24         // Размер сердечек
    private let rotationAmount: ClosedRange<Double> = 45...90     // Вращение при полёте

    // Тайминги
    private let animationDuration: Double = 1                      // Общая длительность
    private let movementDuration: Double = 0.4                     // Длительность полёта
    private let appearDelayRange: ClosedRange<Double> = 0...0.2    // Задержка перед появлением
    private let disappearDelayRange: ClosedRange<Double> = 0...0.3 // Задержка перед исчезновением

    // Свойства
    let centerPosition: CGPoint // Центр разлёта (позиция кнопки лайка)
    @State private var hearts: [HeartParticle] = []

    struct HeartParticle: Identifiable {
        let id = UUID()
        var startPosition: CGSize
        var endPosition: CGSize
        var size: CGFloat
        var opacity: Double
        var blur: Double
        var rotation: Double
        var appearDelay: Double
        var disappearDelay: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(hearts) { heart in
                Image("like-active")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.fill1)
                    .frame(width: heart.size, height: heart.size)
                    .opacity(heart.opacity)
                    .rotationEffect(.degrees(heart.rotation))
                    .blur(radius: heart.blur)
                    .position(centerPosition)
                    .offset(heart.startPosition)
                    .animation(.smooth(duration: movementDuration), value: heart.startPosition)
                    .animation(.smooth(duration: animationDuration), value: heart.rotation)
                    .animation(.smooth(duration: animationDuration), value: heart.size)
                    .animation(.smooth(duration: animationDuration), value: heart.blur)
            }
        }
        .zIndex(-1000)
        .onAppear {
            startExplosion()
        }
    }
    
    private func startExplosion() {
        createHearts()
        animateHearts()
    }
    
    private func createHearts() {
        hearts = (0..<heartCount).map { _ in
            let endAngle = Double.random(in: 0...(2 * .pi))
            let explodeRadius = CGFloat.random(in: explosionRadius)

            // Рандомное смещение для хаотичности
            let randomOffsetX = CGFloat.random(in: -30...30)
            let randomOffsetY = CGFloat.random(in: -30...30)
            
            return HeartParticle(
                startPosition: CGSize.zero, // Старт из центра кнопки
                endPosition: CGSize(
                    width: cos(endAngle) * explodeRadius + randomOffsetX,
                    height: sin(endAngle) * explodeRadius + randomOffsetY
                ),
                size: CGFloat.random(in: heartSize),
                opacity: 0.0,
                blur: 0.0,
                rotation: Double.random(in: -180...180),
                appearDelay: Double.random(in: appearDelayRange),
                disappearDelay: Double.random(in: disappearDelayRange)
            )
        }
    }
    
    private func animateHearts() {
        // Появление и полёт
        hearts.indices.forEach { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + hearts[index].appearDelay) {
                hearts[index].opacity = 0.3
                hearts[index].startPosition = hearts[index].endPosition
                hearts[index].rotation += Double.random(in: rotationAmount)
            }
        }

        // Исчезновение после полёта
        hearts.indices.forEach { index in
            DispatchQueue.main.asyncAfter(deadline: .now() + hearts[index].appearDelay + movementDuration + hearts[index].disappearDelay) {
                hearts[index].opacity = 0.0
                hearts[index].size = 8
                hearts[index].blur = 12
            }
        }
    }
}