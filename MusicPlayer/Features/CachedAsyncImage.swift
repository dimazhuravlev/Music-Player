import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let assetName: String
    var contentMode: ContentMode = .fill

    /// Holds the image loaded asynchronously (only used when not in cache yet).
    @State private var asyncImage: UIImage?

    var body: some View {
        content
            .task(id: url) {
                asyncImage = nil
                asyncImage = await ImageLoader.load(url: url)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image = displayedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.08))
        }
    }

    /// Reads synchronously from NSCache first so the correct image is available
    /// in the same SwiftUI render pass — no 1-frame flash when the URL changes.
    private var displayedImage: UIImage? {
        if let url, let cached = ImageLoader.cache.object(forKey: url as NSURL) {
            return cached
        }
        return asyncImage
    }
}

// MARK: - Image Loader

final class ImageLoader {
    static let cache = NSCache<NSURL, UIImage>().configured {
        $0.countLimit = 200
        $0.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    static let topHalfColorCache    = NSCache<NSURL, UIColor>()
    static let bottomHalfColorCache = NSCache<NSURL, UIColor>()

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
        return URLSession(configuration: config)
    }()

    static func load(url: URL?) async -> UIImage? {
        guard let url else { return nil }
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let (data, _) = try? await session.data(from: url),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL, cost: data.count)
        return image
    }

    /// Returns average colours from the visual top and bottom halves of the artist image.
    /// - Returns: `(topHalf, bottomHalf)` — colours from the upper and lower regions of the photo.
    static func averageColorPair(url: URL?) async -> (topHalf: Color, bottomHalf: Color) {
        guard let url else { return (.black, .black) }
        if let t = topHalfColorCache.object(forKey: url as NSURL),
           let b = bottomHalfColorCache.object(forKey: url as NSURL) {
            return (Color(t), Color(b))
        }
        guard let image = await load(url: url) else { return (.black, .black) }
        // CIImage uses y-up coordinates, so visual top = high y values.
        let w = image.size.width, h = image.size.height
        let topAvg    = (image.averageColor(ciRegion: CGRect(x: 0, y: h / 2, width: w, height: h / 2)) ?? .black)
            .darkened(by: 0.3)
        let bottomAvg = image.averageColor(ciRegion: CGRect(x: 0, y: 0, width: w, height: h / 2)) ?? .black
        topHalfColorCache.setObject(topAvg,    forKey: url as NSURL)
        bottomHalfColorCache.setObject(bottomAvg, forKey: url as NSURL)
        return (Color(topAvg), Color(bottomAvg))
    }

    static func preload(_ urls: [URL?]) {
        for case let url? in urls {
            guard cache.object(forKey: url as NSURL) == nil else { continue }
            Task.detached(priority: .utility) {
                guard let (data, _) = try? await session.data(from: url),
                      let image = UIImage(data: data) else { return }
                cache.setObject(image, forKey: url as NSURL, cost: data.count)
            }
        }
    }
}

// MARK: - UIImage average colour

private extension UIImage {
    /// Calculates the average colour for the given CI-coordinate region using CIAreaAverage.
    /// Pass `nil` to average the full image.
    func averageColor(ciRegion: CGRect? = nil) -> UIColor? {
        guard let input = CIImage(image: self) else { return nil }
        let region = ciRegion ?? input.extent
        let extentVector = CIVector(x: region.origin.x, y: region.origin.y,
                                    z: region.size.width,  w: region.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: input,
                                                 kCIInputExtentKey: extentVector]),
              let output = filter.outputImage else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext(options: [.workingColorSpace: kCFNull as Any])
        ctx.render(output, toBitmap: &pixel, rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8, colorSpace: nil)
        return UIColor(red:   CGFloat(pixel[0]) / 255,
                       green: CGFloat(pixel[1]) / 255,
                       blue:  CGFloat(pixel[2]) / 255,
                       alpha: 1)
    }
}

private extension UIColor {
    /// Returns a copy of the colour with brightness multiplied by `(1 - factor)`.
    func darkened(by factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, b * (1 - factor)), alpha: a)
    }
}

private extension NSCache<NSURL, UIImage> {
    func configured(_ block: (NSCache) -> Void) -> NSCache {
        block(self)
        return self
    }
}
