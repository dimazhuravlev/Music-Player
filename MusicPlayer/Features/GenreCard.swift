import SwiftUI

struct GenreCard: View {
    let index: Int
    let isSelected: Bool
    let isActive: Bool
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    @EnvironmentObject private var gyroManager: GyroManager
    
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
                    Text(descriptionText)
                        .font(.Text1)
                        .foregroundStyle(isSelected ? Color.black.opacity(0.5) : Color.subtitle)
                        .lineSpacing(2)
                }
                .padding(16)
                
                // Bubbles (artist avatars)
                ZStack {
                    let bubbleLayout = BubbleLayout(index: index)
                    let placed = bubbleLayout.placedBubbles(in: size, bubbles: bubbles)
                    ForEach(0..<placed.count, id: \.self) { i in
                        let item = placed[i]
                        let parallaxOffset = ParallaxEffect.offset(
                            roll: gyroManager.roll,
                            pitch: gyroManager.pitch,
                            diameter: item.diameter,
                            isActive: isActive
                        )
                        let clampedPosition = ParallaxEffect.clampedPosition(
                            original: item.center,
                            offset: parallaxOffset,
                            diameter: item.diameter,
                            in: size
                        )
                        avatar(imageName: item.imageName, diameter: item.diameter, imageURL: item.imageURL)
                            .position(x: clampedPosition.x, y: clampedPosition.y)
                            .animation(.smooth(duration: 0.25), value: gyroManager.roll)
                            .animation(.smooth(duration: 0.25), value: gyroManager.pitch)
                    }
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.smooth(duration: 0.4), value: isSelected)
            .animation(.smooth(duration: 0.2), value: isPressed)
            .onTapGesture {
                // Don't allow selection for Artist Selection cards
                guard genreDefinition.genre != "Artist Selection" else { return }
                
                isPressed = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Content

private extension GenreCard {
    var title: String {
        return genreDefinition.cardTitle
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
        let pool = BubbleLayout.allArtistImageNames
        guard !pool.isEmpty else { return [] }

        var result: [String] = []
        if genreDefinition.genre != "Artist Selection" {
            for artist in genreDefinition.artists {
                if let asset = Self.resolvedAssetName(forArtist: artist, artistPool: pool),
                   !result.contains(asset) {
                    result.append(asset)
                }
                if result.count >= 10 { break }
            }
        }

        var rng = SeededGenerator(seed: UInt64(index * 1315423911 + 0xD1E5C0DE))
        var rest = pool.filter { !result.contains($0) }
        for i in stride(from: rest.count - 1, to: 0, by: -1) {
            let j = Int.random(in: 0...i, using: &rng)
            rest.swapAt(i, j)
        }
        for asset in rest where result.count < 10 {
            result.append(asset)
        }

        while result.count < 10 {
            result.append(pool[result.count % pool.count])
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
            let newX = Swift.max(0.08, Swift.min(0.92, base.x + xOffset))
            let newY = Swift.max(0.32, Swift.min(0.96, base.y + yOffset))
            specs[idx] = BubbleSpec(imageName: base.imageName, x: newX, y: newY, size: base.size)
        }
        return specs
    }
    
    func avatar(imageName: String, diameter: CGFloat, imageURL: URL? = nil) -> some View {
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
            CachedAsyncImage(url: imageURL, assetName: imageName)
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    /// Album (or other) bundled images keyed by normalized artist name from `GenreCatalog`.
    private static let wizardArtistOverrideAssets: [String: String] = [
        "atthedrivein": "relationshipofcommand",
        "joydivision": "closer-joy-division",
        "mybloodyvalentine": "loveless",
        "radiohead": "in rainbows",
        "thesmiths": "the-queen-is-dead",
        "blur": "blur",
        "blackflag": "mywar",
        "minorthreat": "minor-threat",
        "ritesofspring": "rites-of-spring",
        "themarsvolta": "amputechture",
        "boardsofcanada": "boardsofcanada",
        "cocteautwins": "garlands",
    ]

    private static func normalizedAssetKey(_ name: String) -> String {
        name.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }
            .joined()
    }

    private static func matchingArtistAsset(for artist: String, in pool: [String]) -> String? {
        let key = normalizedAssetKey(artist)
        return pool.first { normalizedAssetKey($0) == key }
    }

    private static func resolvedAssetName(forArtist artist: String, artistPool: [String]) -> String? {
        if let match = matchingArtistAsset(for: artist, in: artistPool) { return match }
        let key = normalizedAssetKey(artist)
        return wizardArtistOverrideAssets[key]
    }
}
