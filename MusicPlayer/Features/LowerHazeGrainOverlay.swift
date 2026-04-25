import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Размер экрана для полноэкранного scrim (`OverflowMenu`, `ShareOverlay`). `GeometryReader` в `.background` даёт высоту без home indicator — зерно обрезалось снизу.
enum ModalOverlayScreenMetrics {
    static var width: CGFloat {
        #if os(iOS)
        UIScreen.main.bounds.width
        #else
        420
        #endif
    }
    static var height: CGFloat {
        #if os(iOS)
        UIScreen.main.bounds.height
        #else
        920
        #endif
    }
}

/// Зерно через `grainOverlaySoft`: только additive, без мультипликативного затемнения.
/// Плюс `blendMode(.screen)` — чёрная база не даёт серой пелены при `.opacity` (в отличие от обычного srcOver).
struct LowerHazeGrainOverlay: View {
    var width: CGFloat
    var height: CGFloat
    /// `true` — не обновлять Timeline (например, когда слой скрыт).
    var isPaused: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let grainC = Float((t * 0.035).truncatingRemainder(dividingBy: 1.0))
            let bw = max(width, 1)
            let bh = max(height, 1)
            Rectangle()
                .fill(Color.black)
                .frame(width: width, height: height)
                .colorEffect(
                    ShaderLibrary.grainOverlaySoft(
                        .float2(bw, bh),
                        .float(grainC)
                    )
                )
                .compositingGroup()
                .drawingGroup(opaque: false)
        }
        .frame(width: width, height: height)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

enum LowerHazeGrainLayerOpacity {
    static let offlinePrompt: CGFloat = 0.5
    static let playerSlide: CGFloat = 0.45
    static let newReleaseCard: CGFloat = 0.45
    /// Полноэкранный scrim: `OverflowMenu`, `ShareOverlay`.
    static let modalScrim: CGFloat = 0.35
}
