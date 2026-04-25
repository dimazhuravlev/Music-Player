import SwiftUI
import CoreMotion

/// Один экземпляр на приложение: несколько `CMMotionManager` ломают обновления на устройстве.
final class GyroManager: ObservableObject {
    static let shared = GyroManager()

    private let motion = CMMotionManager()
    private var demoDisplayLink: CADisplayLink?
    private var demoStart: CFTimeInterval = 0

    @Published private(set) var roll = 0.0
    @Published private(set) var pitch = 0.0
    @Published private(set) var yaw = 0.0
    @Published private(set) var basePitch: Double?
    @Published private(set) var baseRoll: Double?

    /// Для отладки: симулятор крутит демо, на девайсе — реальный сенсор.
    @Published private(set) var isUsingSimulatorDemo = false

    private init() {
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.accelerometerUpdateInterval = 1.0 / 60.0

        if motion.isDeviceMotionAvailable {
            startDeviceMotion()
        } else if isRunningOnSimulator {
            startSimulatorDemoTilt()
        } else if motion.isAccelerometerAvailable {
            startAccelerometerTilt()
        } else {
            startSimulatorDemoTilt()
        }
    }

    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private func startDeviceMotion() {
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let md = data else { return }

            let attitude = md.attitude
            if self.basePitch == nil { self.basePitch = attitude.pitch }
            if self.baseRoll == nil { self.baseRoll = attitude.roll }

            let rawPitch = attitude.pitch - (self.basePitch ?? 0)
            let rawRoll = attitude.roll - (self.baseRoll ?? 0)
            let clampedPitch = max(min(rawPitch, 0.6), -0.6)
            let clampedRoll = max(min(rawRoll, 0.6), -0.6)

            self.pitch = clampedPitch
            self.roll = clampedRoll
            self.yaw = attitude.yaw
        }
    }

    /// Наклон из гравитации, если нет fused device motion (редко на девайсе).
    private func startAccelerometerTilt() {
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let a = data?.acceleration else { return }
            let gPitch = atan2(-a.x, sqrt(a.y * a.y + a.z * a.z))
            let gRoll = atan2(a.y, a.z)

            if self.basePitch == nil { self.basePitch = gPitch }
            if self.baseRoll == nil { self.baseRoll = gRoll }

            let rawPitch = gPitch - (self.basePitch ?? 0)
            let rawRoll = gRoll - (self.baseRoll ?? 0)
            self.pitch = max(min(rawPitch, 0.6), -0.6)
            self.roll = max(min(rawRoll, 0.6), -0.6)
        }
    }

    private func startSimulatorDemoTilt() {
        isUsingSimulatorDemo = true
        demoStart = CACurrentMediaTime()
        let link = CADisplayLink(target: DisplayLinkTarget { [weak self] in
            self?.tickSimulatorDemo()
        }, selector: #selector(DisplayLinkTarget.tick))
        link.add(to: .main, forMode: .common)
        demoDisplayLink = link
    }

    private func tickSimulatorDemo() {
        let t = CACurrentMediaTime() - demoStart
        pitch = sin(t * 0.9) * 0.18
        roll = cos(t * 0.65) * 0.14
    }

    deinit {
        motion.stopDeviceMotionUpdates()
        motion.stopAccelerometerUpdates()
        demoDisplayLink?.invalidate()
    }
}

// MARK: - CADisplayLink helper (target must be NSObject)

private final class DisplayLinkTarget: NSObject {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func tick() {
        handler()
    }
}
