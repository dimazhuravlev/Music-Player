import simd

// Swift mirror of the C struct in Shaders/Shared.h.
// Field order and types must stay in lockstep with the header for Metal-side reads to align.
struct Uniforms {
    var time: Float = 0
    var audio4: Float = 0
    var audio5: Float = 0

    var offset: simd_float2 = .zero
    var interactionPoint: simd_float2 = .zero
    var interaction: Float = 0

    var reactTop: Float = 0
    var reactMiddle: Float = 0
    var reactBottom: Float = 0

    var topOpacity: Float = 0
    var middleOpacity: Float = 0
    var bottomOpacity: Float = 0

    var sparkStrength: Float = 0
    var scale: Float = 0
}
