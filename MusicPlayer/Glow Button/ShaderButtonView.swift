import SwiftUI
import Metal
import simd

struct ShaderButtonView: UIViewRepresentable {
    private let ctx: MetalContext
    
    private var interaction: Float = 0.5
    private var reactTop: Float = 0.3
    private var reactMiddle: Float = 0.3
    private var reactBottom: Float = 0.3
    private var audio4: Float = 0.5
    private var audio5: Float = 0.5
    private var timeMultiplier: Float = 1.0
    private var initialTime: Float = 0.0
    private var offset: simd_float2 = simd_float2(0, 0)
    private var interactionPoint: simd_float2 = simd_float2(0, 0)
    private var topOpacity: Float = 0.15
    private var middleOpacity: Float = 0.15
    private var bottomOpacity: Float = 0.15
    private var sparkStrength: Float = 0.0
    private var scale: Float = 1.0
    
    init(device: MTLDevice = MTLCreateSystemDefaultDevice()!, initialTime: Float = 0.0) {
        self.ctx = MetalContext(metalDevice: device)
        self.initialTime = initialTime
    }
    
    func makeUIView(context: Context) -> ShaderButtonBackgroundView {
        let view = ShaderButtonBackgroundView(ctx: ctx)
        
        // Установить начальное время для шейдера
        view.uniforms.time = initialTime
        
        updateUniforms(view)
        return view
    }
    
    func updateUIView(_ uiView: ShaderButtonBackgroundView, context: Context) {
        updateUniforms(uiView)
    }
    
    private func updateUniforms(_ view: ShaderButtonBackgroundView) {
        view.uniforms.interaction = interaction
        view.uniforms.reactTop = reactTop
        view.uniforms.reactMiddle = reactMiddle
        view.uniforms.reactBottom = reactBottom
        view.uniforms.audio4 = audio4
        view.uniforms.audio5 = audio5
        view.timeMultiplier = timeMultiplier
        view.uniforms.offset = offset
        view.uniforms.interactionPoint = interactionPoint
        view.uniforms.topOpacity = topOpacity
        view.uniforms.middleOpacity = middleOpacity
        view.uniforms.bottomOpacity = bottomOpacity
        view.uniforms.sparkStrength = sparkStrength
        view.uniforms.scale = scale
    }
}

extension ShaderButtonView {
    func interaction(_ value: Float) -> ShaderButtonView {
        var view = self
        view.interaction = value
        return view
    }
    
    func reactTop(_ value: Float) -> ShaderButtonView {
        var view = self
        view.reactTop = value
        return view
    }
    
    func reactMiddle(_ value: Float) -> ShaderButtonView {
        var view = self
        view.reactMiddle = value
        return view
    }
    
    func reactBottom(_ value: Float) -> ShaderButtonView {
        var view = self
        view.reactBottom = value
        return view
    }
    
    func audio(_ value1: Float, _ value2: Float) -> ShaderButtonView {
        var view = self
        view.audio4 = value1
        view.audio5 = value2
        return view
    }
    
    func timeMultiplier(_ value: Float) -> ShaderButtonView {
        var view = self
        view.timeMultiplier = value
        return view
    }
    
    func offset(x: Float, y: Float) -> ShaderButtonView {
        var view = self
        view.offset = simd_float2(x, y)
        return view
    }
    
    func interactionAt(x: Float, y: Float) -> ShaderButtonView {
        var view = self
        view.interactionPoint = simd_float2(x, y)
        return view
    }
    
    func topOpacity(_ value: Float) -> ShaderButtonView {
        var view = self
        view.topOpacity = value
        return view
    }
    
    func middleOpacity(_ value: Float) -> ShaderButtonView {
        var view = self
        view.middleOpacity = value
        return view
    }
    
    func bottomOpacity(_ value: Float) -> ShaderButtonView {
        var view = self
        view.bottomOpacity = value
        return view
    }
    
    func opacity(_ topValue: Float, _ middleValue: Float, _ bottomValue: Float) -> ShaderButtonView {
        var view = self
        view.topOpacity = topValue
        view.middleOpacity = middleValue 
        view.bottomOpacity = bottomValue
        return view
    }
    
    func randomize(seed: Int? = nil) -> ShaderButtonView {
        let seed = seed ?? Int.random(in: 0...1000)
        var view = self
        
        view.reactTop = Float(0.2 + Double(seed % 10) * 0.05)
        view.reactMiddle = Float(0.3 + Double(seed % 15) * 0.04)
        view.reactBottom = Float(0.4 + Double(seed % 8) * 0.06)
        view.audio4 = Float(0.5 + Double(seed % 5) * 0.1)
        view.audio5 = Float(0.5 + Double(seed % 7) * 0.08)
        view.timeMultiplier = Float.random(in: 0.5...2.0)
        
        return view
    }
    
    func sparkStrength(_ value: Float) -> ShaderButtonView {
        var view = self
        view.sparkStrength = value
        return view
    }
    
    func scale(_ value: Float) -> ShaderButtonView {
        var view = self
        view.scale = value
        return view
    }
} 
