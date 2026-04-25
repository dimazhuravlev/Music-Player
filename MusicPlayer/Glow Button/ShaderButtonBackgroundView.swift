import CoreMotion
import MetalKit
import MetalPerformanceShaders
import simd

public class ShaderButtonBackgroundView: MTKView, MTKViewDelegate {
    let ctx: MetalContext
    var gradientPSO: MTLComputePipelineState!
    var uniforms: Uniforms
    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()
    var timeMultiplier: Float = 1.0

    required init(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }
    
    public init(ctx: MetalContext) {
        self.ctx = ctx
        self.lastFrameTime = CACurrentMediaTime()
        
        self.uniforms = Uniforms()
        uniforms.time = 0
        
        super.init(frame: .zero, device: ctx.device)

        self.gradientPSO = ctx.makeComputePipelineState("shaderMain")

        self.delegate = self
        self.framebufferOnly = false

        self.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        self.isOpaque = false

        self.colorPixelFormat = .bgra8Unorm

        // MTKView's framebufferOnly should propagate, but on some configurations the
        // CAMetalLayer keeps optimised flags that omit .shaderWrite — set both explicitly.
        if let metalLayer = self.layer as? CAMetalLayer {
            metalLayer.framebufferOnly = false
        }
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func update() {
        let currentTime = CACurrentMediaTime()
        let timeDelta = currentTime - lastFrameTime
        lastFrameTime = currentTime

        uniforms.time += Float(timeDelta) * timeMultiplier
        
        setupDefaultValues()
    }
    
    private func setupDefaultValues() {
        if uniforms.interaction == 0 {
            uniforms.interaction = 0.5
        }
        
        if uniforms.offset.x == 0 && uniforms.offset.y == 0 {
            uniforms.offset = simd_float2(0.0, 0.0)
        }
    }

    public func draw(in view: MTKView) {
        update()

        let buf = ctx.commandQueue.makeCommandBuffer()!
        let drawable = view.currentDrawable!

        buf.clear(drawable.texture, withClearColor: MTLClearColorMake(0, 0, 0, 0))
        
        let gradientCommand = buf.makeComputeCommandEncoder()!
        gradientCommand.setComputePipelineState(gradientPSO)
        gradientCommand.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        gradientCommand.setTexture(drawable.texture, index: 0)
        gradientCommand.dispatch(ctx: ctx, size: drawable.texture.size, pso: gradientPSO)
        gradientCommand.endEncoding()

        buf.present(drawable)
        buf.commit()
    }

    public func makeTexture(size: CGSize) -> MTLTexture {
        return ctx.makeTexture(size: size, format: self.colorPixelFormat)
    }
}
