import SwiftUI

struct GenreCard: View {
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(
                        color: isSelected ? Color.white.opacity(0.5) : Color.clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: 0
                    )
                
                // Title + Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.Headline3)
                        .foregroundStyle(isSelected ? .black : .white)
                        .lineSpacing(-16)
                    Text(descriptionText)
                        .font(.Text1)
                        .foregroundStyle(isSelected ? Color.black.opacity(0.5) : Color.subtitle)
                        .lineSpacing(2)
                }
                .padding(16)
                
                // Bubbles (artist avatars)
                ZStack {
                    let placed = placedBubbles(in: size)
                    ForEach(0..<placed.count, id: \.self) { i in
                        let item = placed[i]
                        avatar(imageName: item.imageName, diameter: item.diameter)
                            .position(x: item.center.x, y: item.center.y)
                    }
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onTapGesture {
                // Don't allow selection for Artist Selection cards
                guard genreDefinition.genre != "Artist Selection" else { return }
                
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
        }
    }
}

// MARK: - Model

private struct BubbleSpec {
    let imageName: String
    let x: CGFloat   // relative 0..1
    let y: CGFloat   // relative 0..1
    let size: CGFloat // relative to min(width, height)
}

private struct PlacedBubble {
    let imageName: String
    let center: CGPoint
    let diameter: CGFloat
}

// MARK: - Content

private extension GenreCard {
    var title: String {
        genreDefinition.cardTitle
    }
    
    var descriptionText: String {
        let artists = genreDefinition.artists
        if artists.isEmpty {
            if genreDefinition.genre == "Artist Selection" {
                return "The more you pick, the better your recommendations"
            }
            return "Discover \(genreDefinition.genre)"
        }
        let primaryArtists = artists.prefix(4)
        let artistList = primaryArtists.joined(separator: ", ")
        return "\(artistList) and other \(genreDefinition.genre)"
    }
    
    var genreDefinition: GenreDefinition {
        let catalog = GenreCatalog.shared
        let definitions = catalog.entries
        guard !definitions.isEmpty else { return catalog.fallback }
        return definitions[index % definitions.count]
    }
    
    var artistImageNames: [String] {
        // All artist assets from Assets.xcassets/artists
        let all = [
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
        
        // Use deterministic random selection based on card index
        var result: [String] = []
        if all.isEmpty { return result }
        
        // Create a seeded random number generator for this card
        var rng = SeededGenerator(seed: UInt64(index * 1315423911 + 0xD1E5C0DE))
        
        // Shuffle the array deterministically for this card
        var shuffled = all
        for i in stride(from: shuffled.count - 1, to: 0, by: -1) {
            let j = Int.random(in: 0...i, using: &rng)
            shuffled.swapAt(i, j)
        }
        
        // Take first 10 unique artists
        for i in 0..<min(10, shuffled.count) {
            result.append(shuffled[i])
        }
        
        return result
    }
    
    var bubbles: [BubbleSpec] {
        // Ten pre-defined relative positions and sizes, rotated by index for variation
        var specs: [BubbleSpec] = [
            BubbleSpec(imageName: artistImageNames[0], x: 0.18, y: 0.62, size: 0.32),
            BubbleSpec(imageName: artistImageNames[1], x: 0.38, y: 0.38, size: 0.26),
            BubbleSpec(imageName: artistImageNames[2], x: 0.68, y: 0.47, size: 0.28),
            BubbleSpec(imageName: artistImageNames[3], x: 0.86, y: 0.70, size: 0.42),
            BubbleSpec(imageName: artistImageNames[4], x: 0.58, y: 0.80, size: 0.30),
            BubbleSpec(imageName: artistImageNames[5], x: 0.84, y: 0.36, size: 0.22),
            BubbleSpec(imageName: artistImageNames[6 % artistImageNames.count], x: 0.48, y: 0.62, size: 0.18),
            BubbleSpec(imageName: artistImageNames[7 % artistImageNames.count], x: 0.30, y: 0.84, size: 0.22),
            BubbleSpec(imageName: artistImageNames[8 % artistImageNames.count], x: 0.28, y: 0.44, size: 0.20),
            BubbleSpec(imageName: artistImageNames[9 % artistImageNames.count], x: 0.64, y: 0.18, size: 0.22)
        ]
        // Deterministic rotation by index
        let shift = index % max(1, specs.count)
        if shift > 0 {
            let head = specs.prefix(shift)
            specs.removeFirst(shift)
            specs.append(contentsOf: head)
        }
        // Deterministic offsets to ensure each card has a distinct arrangement
        let amplitudeX: CGFloat = 0.11
        let amplitudeY: CGFloat = 0.18
        for idx in specs.indices {
            let base = specs[idx]
            let phase = CGFloat(index * 37 + idx * 53)
            let radians = phase * .pi / 180
            let xOffset = sin(radians) * amplitudeX
            let yOffset = cos(radians * 1.21) * amplitudeY
            let newX = clamp(base.x + xOffset, min: 0.08, max: 0.92)
            let newY = clamp(base.y + yOffset, min: 0.32, max: 0.96)
            specs[idx] = BubbleSpec(imageName: base.imageName, x: newX, y: newY, size: base.size)
        }
        return specs
    }
    
    func avatar(imageName: String, diameter: CGFloat) -> some View {
        Group {
            if genreDefinition.genre == "Artist Selection" {
                // Show plus icon for artist selection card
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: diameter, height: diameter)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
            // Show artist photo for regular cards
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        // .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    // Compute non-overlapping positions for bubbles, avoiding the title/description area
    func placedBubbles(in containerSize: CGSize) -> [PlacedBubble] {
        let margin: CGFloat = 10
        let minSide = min(containerSize.width, containerSize.height)
        let specs = bubbles.sorted { $0.size > $1.size }
        var placed: [PlacedBubble] = []
        
        // Reserve top-left area for text
        let textPadding: CGFloat = 16
        let textRect = CGRect(
            origin: CGPoint(x: 0, y: textPadding),
            size: CGSize(width: containerSize.width,
                         height: containerSize.height * 0.28)
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
                if let c = findPlacement(base: base,
                                         diameter: attemptDiameter,
                                         containerSize: containerSize,
                                         textRect: textRect,
                                         placed: placed,
                                         margin: margin,
                                         minY: minYForBubbles,
                                         rng: &rng) {
                    center = c
                    diameter = attemptDiameter
                    break
                }
            }
            
            // Fallback grid scan if spiral failed (try with progressive size reduction)
            if center == nil {
                for reduce in 0..<6 {
                    let attemptDiameter = diameter * CGFloat(pow(0.9, Double(reduce)))
                    if let c = fallbackGrid(diameter: attemptDiameter,
                                            containerSize: containerSize,
                                            textRect: textRect,
                                            placed: placed,
                                            margin: margin,
                                            minY: minYForBubbles) {
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
    
    func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat { Swift.max(min, Swift.min(max, value)) }
    
    // Spiral search around a base point with random phase
    func findPlacement(base: CGPoint,
                       diameter: CGFloat,
                       containerSize: CGSize,
                       textRect: CGRect,
                       placed: [PlacedBubble],
                       margin: CGFloat,
                       minY: CGFloat,
                       rng: inout SeededGenerator) -> CGPoint? {
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
            if circleIntersectsRect(center: c, radius: radius + margin, rect: textRect) == false,
               overlapsAny(center: c, radius: radius + margin, placed: placed) == false {
                return c
            }
            t += 0.03
        }
        return nil
    }
    
    func overlapsAny(center: CGPoint, radius: CGFloat, placed: [PlacedBubble]) -> Bool {
        for p in placed {
            let required = (p.diameter / 2) + radius
            let dx = p.center.x - center.x
            let dy = p.center.y - center.y
            if (dx * dx + dy * dy) < required * required { return true }
        }
        return false
    }
    
    // Coarse grid fallback to guarantee a placement
    func fallbackGrid(diameter: CGFloat,
                      containerSize: CGSize,
                      textRect: CGRect,
                      placed: [PlacedBubble],
                      margin: CGFloat,
                      minY: CGFloat) -> CGPoint? {
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
    
    func circleIntersectsRect(center: CGPoint, radius: CGFloat, rect: CGRect) -> Bool {
        let closestX = max(rect.minX, min(center.x, rect.maxX))
        let closestY = max(rect.minY, min(center.y, rect.maxY))
        let dx = center.x - closestX
        let dy = center.y - closestY
        return (dx * dx + dy * dy) <= radius * radius
    }
}

// MARK: - Deterministic RNG

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        self.state = seed == 0 ? 0xdeadbeef : seed
    }
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}


