import SwiftUI

/// Displays the stacked pair of favorite covers for the Collection screen.
struct FavoriteCard: View {
    let identifier: Int
    let title: String
    let previousCover: String?
    let latestCover: String?
    let isPressed: Bool
    var instantPressedLayout: Bool = false
    var previousCoverURL: URL? = nil
    var latestCoverURL: URL? = nil

    private let leftTransform: CoverTransform
    private let rightTransform: CoverTransform
    private let isLeftOnTop: Bool

    private static let defaultPrevious = "album"
    private static let defaultLatest = "album"

    init(identifier: Int, title: String, previousCover: String?, latestCover: String?, isPressed: Bool = false, instantPressedLayout: Bool = false, previousCoverURL: URL? = nil, latestCoverURL: URL? = nil) {
        self.identifier = identifier
        self.title = title
        self.previousCover = previousCover
        self.latestCover = latestCover
        self.isPressed = isPressed
        self.instantPressedLayout = instantPressedLayout
        self.previousCoverURL = previousCoverURL
        self.latestCoverURL = latestCoverURL
        
        let leftCover = previousCover ?? FavoriteCard.defaultPrevious
        let rightCover = latestCover ?? FavoriteCard.defaultLatest
        var generator = SeededGenerator(seed: CoverTransform.seed(for: identifier, leftCover: leftCover, rightCover: rightCover))
        self.leftTransform = .random(for: .left, using: &generator)
        self.rightTransform = .random(for: .right, using: &generator)
        self.isLeftOnTop = Bool.random(using: &generator)
    }
    
    var body: some View {
        let leftCover = previousCover ?? FavoriteCard.defaultPrevious
        let rightCover = latestCover ?? FavoriteCard.defaultLatest
        
        let leftRotation = leftTransform.rotation + (isPressed ? -4 : 0)
        let rightRotation = rightTransform.rotation + (isPressed ? 4 : 0)
        let leftX = leftTransform.xOffset + (isPressed ? -6 : 0)
        let rightX = rightTransform.xOffset + (isPressed ? 6 : 0)
        let leftY = leftTransform.yOffset + (isPressed ? 2 : 0)
        let rightY = rightTransform.yOffset + (isPressed ? -2 : 0)
        
        let spacing: CGFloat = isPressed ? 24 : 16
        
        VStack(spacing: spacing) {
            ZStack {
                FavoriteCoverCard(
                    coverName: leftCover,
                    rotation: leftRotation,
                    xOffset: leftX,
                    yOffset: leftY,
                    coverURL: previousCoverURL
                )
                .zIndex(isLeftOnTop ? 1 : 0)

                FavoriteCoverCard(
                    coverName: rightCover,
                    rotation: rightRotation,
                    xOffset: rightX,
                    yOffset: rightY,
                    coverURL: latestCoverURL
                )
                .zIndex(isLeftOnTop ? 0 : 1)
            }
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .frame(maxWidth: .infinity)
            .animation(instantPressedLayout ? nil : .smooth(duration: 0.25), value: isPressed)
            
            Text(title)
                .font(.Text1)
                .foregroundStyle(.white)
        }
        .animation(instantPressedLayout ? nil : .smooth(duration: 0.25), value: spacing)
    }
}

private struct FavoriteCoverCard: View {
    let coverName: String
    let rotation: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    var coverURL: URL? = nil
    private let size: CGFloat = 80

    var body: some View {
        CachedAsyncImage(url: coverURL, assetName: coverName)
            .frame(width: size, height: size)
            .clipped()
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
            )
            .cornerRadius(10)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 10)
            .animation(.smooth(duration: 0.25), value: coverName)
    }
}

private struct CoverTransform {
    enum Position {
        case left
        case right
    }
    
    let rotation: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    
    static func random(for position: Position, using generator: inout some RandomNumberGenerator) -> CoverTransform {
        switch position {
        case .left:
            return CoverTransform(
                rotation: Double.random(in: -18 ... -6, using: &generator),
                xOffset: CGFloat.random(in: -30 ... -14, using: &generator),
                yOffset: CGFloat.random(in: -8 ... 8, using: &generator)
            )
        case .right:
            return CoverTransform(
                rotation: Double.random(in: 6 ... 18, using: &generator),
                xOffset: CGFloat.random(in: 14 ... 30, using: &generator),
                yOffset: CGFloat.random(in: -8 ... 8, using: &generator)
            )
        }
    }
    
    static func seed(for identifier: Int, leftCover: String, rightCover: String) -> UInt64 {
        var hash: UInt64 = 0x9E3779B97F4A7C15
        func mix(byte: UInt8) {
            hash ^= UInt64(byte)
            hash = hash &* 0x9E3779B97F4A7C15
            hash ^= hash >> 33
        }
        
        var id = UInt64(bitPattern: Int64(identifier))
        for _ in 0..<8 {
            mix(byte: UInt8(truncatingIfNeeded: id))
            id >>= 8
        }
        
        for byte in leftCover.utf8 { mix(byte: byte) }
        for byte in rightCover.utf8 { mix(byte: byte) }
        
        return hash
    }
}

