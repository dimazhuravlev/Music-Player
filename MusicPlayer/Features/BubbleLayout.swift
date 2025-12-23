import SwiftUI

// MARK: - Models

struct PlacedBubble {
    let imageName: String
    let center: CGPoint
    let diameter: CGFloat
}

struct BubbleSpec {
    let imageName: String
    let x: CGFloat   // relative 0..1
    let y: CGFloat   // relative 0..1
    let size: CGFloat // relative to min(width, height)
}

// MARK: - BubbleLayout

struct BubbleLayout {
    let index: Int
    
    /// All artist image names from Assets.xcassets/artists
    static let allArtistImageNames: [String] = [
        "1D8A8975e cropped",
        "Abd El Basset Hamouda",
        "Angham",
        "Bashaar Al Jawad",
        "Bosnian Rainbows",
        "Bruno Mars",
        "Fahad Bin Fasla",
        "Hosam Habib (1)",
        "Kadim Al Saher",
        "Main Yandex Disk",
        "Main from Yandex Disk",
        "Mouhamed Mounir",
        "RIDE",
        "Rahma Riad",
        "Rashed",
        "Rgaheb Alama",
        "Ruby from Yandex Disk",
        "Sabrina Carpenter Image",
        "Saif Nabeel",
        "Siilawy",
        "Tamer Hosny",
        "The Jesus and Mary Chain",
        "Tul8te",
        "Weeknd Oct 9 2021",
        "Wegz 1",
        "Wegz 2",
        "benson boone",
        "clairo",
        "dua lipa",
        "fugazi",
        "marwan pablo",
        "my bloody valentine",
        "pixies",
        "saint levant",
        "saint levant 1",
        "sons of kemet",
        "teddy swims",
        "tul8et",
        "Wegz 3"
    ]
    
    /// Compute non-overlapping positions for bubbles, avoiding the title/description area
    func placedBubbles(in containerSize: CGSize, bubbles: [BubbleSpec], textAreaHeightRatio: CGFloat = 0.28) -> [PlacedBubble] {
        let margin: CGFloat = 10
        let minSide = min(containerSize.width, containerSize.height)
        let specs = bubbles.sorted { $0.size > $1.size }
        var placed: [PlacedBubble] = []
        
        // Reserve top-left area for text
        let textPadding: CGFloat = 16
        let textRect = CGRect(
            origin: CGPoint(x: 0, y: textPadding),
            size: CGSize(width: containerSize.width, height: containerSize.height * textAreaHeightRatio)
        )
        let minYForBubbles = textRect.maxY + margin
        
        var rng = SeededGenerator(seed: UInt64(0xD1E5C0DE ^ UInt64(index &* 1315423911)))
        
        for spec in specs {
            var diameter = max(10, minSide * spec.size)
            let base = CGPoint(x: spec.x * containerSize.width, y: spec.y * containerSize.height)
            var center: CGPoint? = nil
            
            // Try spiral candidates around the base, reducing size if needed
            for reduce in 0..<4 {
                let attemptDiameter = diameter * CGFloat(pow(0.92, Double(reduce)))
                if let c = findPlacement(
                    base: base,
                    diameter: attemptDiameter,
                    containerSize: containerSize,
                    textRect: textRect,
                    placed: placed,
                    margin: margin,
                    minY: minYForBubbles,
                    rng: &rng
                ) {
                    center = c
                    diameter = attemptDiameter
                    break
                }
            }
            
            // Fallback grid scan if spiral failed (try with progressive size reduction)
            if center == nil {
                for reduce in 0..<6 {
                    let attemptDiameter = diameter * CGFloat(pow(0.9, Double(reduce)))
                    if let c = fallbackGrid(
                        diameter: attemptDiameter,
                        containerSize: containerSize,
                        textRect: textRect,
                        placed: placed,
                        margin: margin,
                        minY: minYForBubbles
                    ) {
                        center = c
                        diameter = attemptDiameter
                        break
                    }
                }
            }
            
            // As a last resort, place very small at bottom-right safe corner
            if center == nil {
                let tiny = max(8, minSide * 0.12)
                let radius = tiny / 2
                let x = containerSize.width - radius - margin
                let y = max(minYForBubbles + radius, containerSize.height - radius - margin)
                if !circleIntersectsRect(center: CGPoint(x: x, y: y), radius: radius + margin, rect: textRect) {
                    center = CGPoint(x: x, y: y)
                    diameter = tiny
                }
            }
            
            if let c = center {
                placed.append(PlacedBubble(imageName: spec.imageName, center: c, diameter: diameter))
            }
        }
        
        return placed
    }
    
    // MARK: - Private Helpers
    
    /// Spiral search around a base point with random phase
    private func findPlacement(
        base: CGPoint,
        diameter: CGFloat,
        containerSize: CGSize,
        textRect: CGRect,
        placed: [PlacedBubble],
        margin: CGFloat,
        minY: CGFloat,
        rng: inout SeededGenerator
    ) -> CGPoint? {
        let radius = diameter / 2
        let maxR = min(containerSize.width, containerSize.height) * 0.6
        let phase = Double.random(in: 0..<Double.pi * 2, using: &rng)
        var t: Double = 0
        
        while t < 1.0 {
            let r = Double(t) * Double(maxR)
            let a = phase + r * 0.08
            var x = base.x + CGFloat(cos(a) * r)
            var y = base.y + CGFloat(sin(a) * r)
            
            let minXAllowed = radius + margin
            let maxXAllowed = containerSize.width - radius - margin
            if minXAllowed > maxXAllowed { return nil }
            x = clamp(x, min: minXAllowed, max: maxXAllowed)
            
            let minYAllowed = max(radius + margin, minY + radius)
            let maxYAllowed = containerSize.height - radius - margin
            if minYAllowed > maxYAllowed { return nil }
            y = clamp(y, min: minYAllowed, max: maxYAllowed)
            
            let c = CGPoint(x: x, y: y)
            if !circleIntersectsRect(center: c, radius: radius + margin, rect: textRect),
               !overlapsAny(center: c, radius: radius + margin, placed: placed) {
                return c
            }
            
            t += 0.03
        }
        
        return nil
    }
    
    /// Coarse grid fallback to guarantee a placement
    private func fallbackGrid(
        diameter: CGFloat,
        containerSize: CGSize,
        textRect: CGRect,
        placed: [PlacedBubble],
        margin: CGFloat,
        minY: CGFloat
    ) -> CGPoint? {
        let radius = diameter / 2
        let cols = 8
        let rows = 8
        let stepX = (containerSize.width - 2 * (radius + margin)) / CGFloat(cols - 1)
        let stepY = (containerSize.height - 2 * (radius + margin)) / CGFloat(rows - 1)
        let minYAllowed = max(radius + margin, minY + radius)
        let maxYAllowed = containerSize.height - radius - margin
        
        if stepX <= 0 || stepY <= 0 || minYAllowed > maxYAllowed { return nil }
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = radius + margin + CGFloat(col) * stepX
                let y = radius + margin + CGFloat(row) * stepY
                
                if y < minYAllowed || y > maxYAllowed { continue }
                
                let c = CGPoint(x: x, y: y)
                if circleIntersectsRect(center: c, radius: radius + margin, rect: textRect) { continue }
                if overlapsAny(center: c, radius: radius + margin, placed: placed) { continue }
                
                return c
            }
        }
        
        return nil
    }
    
    private func overlapsAny(center: CGPoint, radius: CGFloat, placed: [PlacedBubble]) -> Bool {
        for p in placed {
            let required = (p.diameter / 2) + radius
            let dx = p.center.x - center.x
            let dy = p.center.y - center.y
            if (dx * dx + dy * dy) < required * required { return true }
        }
        return false
    }
    
    private func circleIntersectsRect(center: CGPoint, radius: CGFloat, rect: CGRect) -> Bool {
        let closestX = max(rect.minX, min(center.x, rect.maxX))
        let closestY = max(rect.minY, min(center.y, rect.maxY))
        let dx = center.x - closestX
        let dy = center.y - closestY
        return (dx * dx + dy * dy) <= radius * radius
    }
    
    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}

// MARK: - ParallaxEffect

struct ParallaxEffect {
    /// Calculate parallax offset based on device orientation (gyro data)
    static func offset(roll: Double, pitch: Double, diameter: CGFloat, isActive: Bool) -> CGPoint {
        guard isActive else { return .zero }
        
        // Calculate scale based on diameter with balanced falloff for visible movement across all sizes
        let maxDiameter: CGFloat = 120 // Approximate maximum avatar diameter
        let normalizedDiameter = diameter / maxDiameter
        // Use gentler curve so medium/large avatars also move visibly (40-60% of small avatars)
        let scale = clamp(pow(1.0 - normalizedDiameter, 1.8), min: 0.4, max: 1.0)
        
        let xOffset = roll * 40 * scale
        let yOffset = pitch * 40 * scale
        
        return CGPoint(x: xOffset, y: yOffset)
    }
    
    /// Clamp avatar position to keep it fully visible within container bounds
    static func clampedPosition(
        original originalCenter: CGPoint,
        offset: CGPoint,
        diameter: CGFloat,
        in containerSize: CGSize
    ) -> CGPoint {
        let radius = diameter / 2
        let margin: CGFloat = 8 // Small margin from card edges
        
        // Calculate new position with offset
        let newX = originalCenter.x + offset.x
        let newY = originalCenter.y + offset.y
        
        // Clamp X position to keep avatar fully visible
        let minX = radius + margin
        let maxX = containerSize.width - radius - margin
        let clampedX = clamp(newX, min: minX, max: maxX)
        
        // Clamp Y position to keep avatar fully visible
        let minY = radius + margin
        let maxY = containerSize.height - radius - margin
        let clampedY = clamp(newY, min: minY, max: maxY)
        
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}

// MARK: - Deterministic RNG

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0xdeadbeef : seed
    }
    
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

