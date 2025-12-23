import SwiftUI
import CoreMotion

class GyroManager: ObservableObject {
    private let motion = CMMotionManager()
    @Published var roll = 0.0
    @Published var pitch = 0.0
    @Published var yaw = 0.0
    @Published var basePitch: Double?
    @Published var baseRoll: Double?
    
    init() {
        motion.deviceMotionUpdateInterval = 0.05
        
        guard motion.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { data, error in
            guard let attitude = data?.attitude else { return }
            
            // Auto-calibration: capture initial orientation as neutral position
            if self.basePitch == nil {
                self.basePitch = attitude.pitch
            }
            if self.baseRoll == nil {
                self.baseRoll = attitude.roll
            }
            
            // Compute relative values from baseline
            let rawPitch = attitude.pitch - (self.basePitch ?? 0)
            let rawRoll = attitude.roll - (self.baseRoll ?? 0)
            
            // Clamp rotation to prevent extreme distortion (0.6 radians ≈ 34°)
            let clampedPitch = max(min(rawPitch, 0.6), -0.6)
            let clampedRoll = max(min(rawRoll, 0.6), -0.6)
            
            self.pitch = clampedPitch
            self.roll = clampedRoll
            self.yaw = attitude.yaw
        }
    }
    
    deinit {
        motion.stopDeviceMotionUpdates()
    }
}
