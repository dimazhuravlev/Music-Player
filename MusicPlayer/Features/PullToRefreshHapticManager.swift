import SwiftUI
import CoreHaptics
import UIKit

class PullToRefreshHapticManager: ObservableObject {
    let hapticStopDistance: CGFloat = 160 // Расстояние, на котором срабатывает рефреш
    let hapticStepDistance: CGFloat = 1 // Срабатывание хаптика каждые 1px
    
    private var hapticEngine: CHHapticEngine?
    @Published var hasTriggeredFinalHaptic = false
    private var lastHapticTriggerDistance: CGFloat = 0
    
    init() {
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }
    
    func handlePullDistance(_ pullDistance: CGFloat) {
        // Остановить хаптик, если расстояние превышает порог остановки
        if pullDistance >= hapticStopDistance {
            stopHaptic()
            // Запустить финальный хаптик в конце оттяга
            if !hasTriggeredFinalHaptic {
                triggerFinalHaptic()
                hasTriggeredFinalHaptic = true
            }
        } else {
            if hasTriggeredFinalHaptic {
                hasTriggeredFinalHaptic = false
            }
            
            // Запускать дискретный хаптик на каждом шаге (при движении вниз и возврате вверх)
            let currentStep = floor(pullDistance / hapticStepDistance)
            let lastStep = floor(lastHapticTriggerDistance / hapticStepDistance)
            
            if currentStep != lastStep {
                // Запустить хаптик как при движении вниз, так и при возврате вверх
                triggerDiscreteHaptic(at: pullDistance)
                lastHapticTriggerDistance = pullDistance
            }
        }
    }
    
    func reset() {
        stopHaptic()
        hasTriggeredFinalHaptic = false
        lastHapticTriggerDistance = 0
    }
    
    private func triggerDiscreteHaptic(at pullDistance: CGFloat) {
        guard let hapticEngine = hapticEngine,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        
        // Нормализовать расстояние до диапазона 0...1 (до hapticStopDistance)
        let normalized = min(max(pullDistance / hapticStopDistance, 0), 1)
        
        // Интенсивность постепенно увеличивается от 0.1 до 0.3 при оттяге
        let intensity = Float(0.1 + (normalized * 0.3))
        
        // Дискретное событие хаптика
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            
            try player.start(atTime: 0)
        } catch {
            print("Failed to create or play haptic: \(error)")
        }
    }
    
    private func stopHaptic() {
    }
    
    /// Финальный хаптик при достижении порога остановки
    private func triggerFinalHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

