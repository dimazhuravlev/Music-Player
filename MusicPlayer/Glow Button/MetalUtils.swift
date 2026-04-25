import Metal
import MetalPerformanceShaders
import simd

public class MetalContext {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let library: MTLLibrary
    public let isNewDevice: Bool

    public init(metalDevice: MTLDevice) {
        self.device = metalDevice
        self.commandQueue = metalDevice.makeCommandQueue()!
        
        if let customLibraryURL = Bundle.main.url(forResource: "custom", withExtension: "metallib") {
            do {
                self.library = try device.makeLibrary(URL: customLibraryURL)
            } catch {
                print("Failed to load custom.metallib, falling back to default: \(error)")
                self.library = device.makeDefaultLibrary()!
            }
        } else {
            print("custom.metallib not found, using default library")
            self.library = device.makeDefaultLibrary()!
        }
        
        self.isNewDevice = device.supportsFamily(.apple4)
    }

    public func makeComputePipelineState(_ functionName: String) -> MTLComputePipelineState {
        let function = library.makeFunction(name: functionName)!
        return try! device.makeComputePipelineState(function: function)
    }

    public func makeComputePipelineStateWithBlend(_ functionName: String) -> MTLComputePipelineState {
        let function = library.makeFunction(name: functionName)!
        return try! device.makeComputePipelineState(function: function)
    }

    public func makeRenderPipelineState(
        _ vertexName: String,
        _ fragmentName: String,
        pixelFormat: MTLPixelFormat = .bgra8Unorm,
        blendOperation: MTLBlendOperation? = nil
    ) -> MTLRenderPipelineState {
        let vertex = library.makeFunction(name: vertexName)
        let fragment = library.makeFunction(name: fragmentName)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        if let blendOperation {
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = blendOperation
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        }
        
        return try! device.makeRenderPipelineState(descriptor: descriptor)
    }

    public func makeScreenBlendRenderPipelineState(
        pixelFormat: MTLPixelFormat = .bgra8Unorm
    ) -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .oneMinusDestinationColor
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .oneMinusDestinationAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        
        return try! device.makeRenderPipelineState(descriptor: descriptor)
    }

    public func makeTexture(size: CGSize, format: MTLPixelFormat) -> MTLTexture {
        let desc = MTLTextureDescriptor()
        desc.width = Int(size.width)
        desc.height = Int(size.height)
        desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        desc.storageMode = .private
        desc.pixelFormat = format

        return device.makeTexture(descriptor: desc)!
    }
}

extension MTLComputeCommandEncoder {
    public func dispatch(ctx: MetalContext, size: MTLSize, pso: MTLComputePipelineState) {
        let width = pso.threadExecutionWidth
        let height = pso.maxTotalThreadsPerThreadgroup / width
        let threadsPerGroup = MTLSizeMake(width, height, 1)

        if ctx.isNewDevice {
            self.dispatchThreads(size, threadsPerThreadgroup: threadsPerGroup)
        } else {
            let threadGroupCount = MTLSize(
                width: (size.width + width - 1) / width,
                height: (size.height + height - 1) / height,
                depth: 1)
            self.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadsPerGroup)
        }
    }

    public func dispatch1d(ctx: MetalContext, count: Int) {
        let threadsPerGroup = MTLSizeMake(1, 1, 1)
        let threadsPerGrid = MTLSizeMake(count, 1, 1)
        
        if ctx.isNewDevice {
            self.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        } else {
            let threadGroupSize = MTLSize(width: count, height: 1, depth: 1)
            let threadGroupCount = MTLSize(
                width: (count + threadGroupSize.width - 1) / threadGroupSize.width,
                height: 1,
                depth: 1)
            self.dispatchThreadgroups(
                threadGroupCount,
                threadsPerThreadgroup: threadGroupSize
            )
        }
    }
}

extension MTLTexture {
    public var size: MTLSize {
        return MTLSize(width: Int(self.width), height: Int(self.height), depth: Int(self.depth))
    }
}

extension MTLCommandBuffer {
    public func blit(_ src: MTLTexture, _ dst: MTLTexture) {
        if let blitEncoder = self.makeBlitCommandEncoder() {
            blitEncoder.copy(
                from: src,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: src.size,
                to: dst,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
            blitEncoder.endEncoding()
        }
    }

    public func applyMPS(
        _ kernel: MPSBinaryImageKernel, _ src: MTLTexture, _ dst: MTLTexture, _ tmp: MTLTexture
    ) {
        kernel.encode(
            commandBuffer: self, primaryTexture: src, secondaryTexture: dst, destinationTexture: tmp
        )
        blit(tmp, dst)
    }

    public func clear(_ t: MTLTexture, withClearColor clearColor: MTLClearColor? = nil) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = t
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor ?? MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        if let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.endEncoding()
        }
    }
}

public class TextureSet {
    public var ping: MTLTexture
    public var pong: MTLTexture

    public init(ctx: MetalContext, size: CGSize, format: MTLPixelFormat) {
        ping = ctx.makeTexture(
            size: size,
            format: format
        )
        pong = ctx.makeTexture(
            size: size,
            format: format
        )
    }

    public func swap() {
        (ping, pong) = (pong, ping)
    }
}
