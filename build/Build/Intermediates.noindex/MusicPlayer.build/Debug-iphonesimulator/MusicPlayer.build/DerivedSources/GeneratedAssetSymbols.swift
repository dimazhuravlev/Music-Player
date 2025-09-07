import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Anasheed" asset catalog image resource.
    static let anasheed = DeveloperToolsSupport.ImageResource(name: "Anasheed", bundle: resourceBundle)

    /// The "EveningAzkar" asset catalog image resource.
    static let eveningAzkar = DeveloperToolsSupport.ImageResource(name: "EveningAzkar", bundle: resourceBundle)

    /// The "MorningAzkar" asset catalog image resource.
    static let morningAzkar = DeveloperToolsSupport.ImageResource(name: "MorningAzkar", bundle: resourceBundle)

    /// The "Ruqya" asset catalog image resource.
    static let ruqya = DeveloperToolsSupport.ImageResource(name: "Ruqya", bundle: resourceBundle)

    /// The "album" asset catalog image resource.
    static let album = DeveloperToolsSupport.ImageResource(name: "album", bundle: resourceBundle)

    /// The "backward" asset catalog image resource.
    static let backward = DeveloperToolsSupport.ImageResource(name: "backward", bundle: resourceBundle)

    /// The "dislike-active" asset catalog image resource.
    static let dislikeActive = DeveloperToolsSupport.ImageResource(name: "dislike-active", bundle: resourceBundle)

    /// The "dislike-default" asset catalog image resource.
    static let dislikeDefault = DeveloperToolsSupport.ImageResource(name: "dislike-default", bundle: resourceBundle)

    /// The "forward" asset catalog image resource.
    static let forward = DeveloperToolsSupport.ImageResource(name: "forward", bundle: resourceBundle)

    /// The "like-active" asset catalog image resource.
    static let likeActive = DeveloperToolsSupport.ImageResource(name: "like-active", bundle: resourceBundle)

    /// The "like-default" asset catalog image resource.
    static let likeDefault = DeveloperToolsSupport.ImageResource(name: "like-default", bundle: resourceBundle)

    /// The "pause" asset catalog image resource.
    static let pause = DeveloperToolsSupport.ImageResource(name: "pause", bundle: resourceBundle)

    /// The "play" asset catalog image resource.
    static let play = DeveloperToolsSupport.ImageResource(name: "play", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Anasheed" asset catalog image.
    static var anasheed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .anasheed)
#else
        .init()
#endif
    }

    /// The "EveningAzkar" asset catalog image.
    static var eveningAzkar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .eveningAzkar)
#else
        .init()
#endif
    }

    /// The "MorningAzkar" asset catalog image.
    static var morningAzkar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .morningAzkar)
#else
        .init()
#endif
    }

    /// The "Ruqya" asset catalog image.
    static var ruqya: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ruqya)
#else
        .init()
#endif
    }

    /// The "album" asset catalog image.
    static var album: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .album)
#else
        .init()
#endif
    }

    /// The "backward" asset catalog image.
    static var backward: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .backward)
#else
        .init()
#endif
    }

    /// The "dislike-active" asset catalog image.
    static var dislikeActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dislikeActive)
#else
        .init()
#endif
    }

    /// The "dislike-default" asset catalog image.
    static var dislikeDefault: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .dislikeDefault)
#else
        .init()
#endif
    }

    /// The "forward" asset catalog image.
    static var forward: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .forward)
#else
        .init()
#endif
    }

    /// The "like-active" asset catalog image.
    static var likeActive: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .likeActive)
#else
        .init()
#endif
    }

    /// The "like-default" asset catalog image.
    static var likeDefault: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .likeDefault)
#else
        .init()
#endif
    }

    /// The "pause" asset catalog image.
    static var pause: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pause)
#else
        .init()
#endif
    }

    /// The "play" asset catalog image.
    static var play: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .play)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Anasheed" asset catalog image.
    static var anasheed: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .anasheed)
#else
        .init()
#endif
    }

    /// The "EveningAzkar" asset catalog image.
    static var eveningAzkar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .eveningAzkar)
#else
        .init()
#endif
    }

    /// The "MorningAzkar" asset catalog image.
    static var morningAzkar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .morningAzkar)
#else
        .init()
#endif
    }

    /// The "Ruqya" asset catalog image.
    static var ruqya: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ruqya)
#else
        .init()
#endif
    }

    /// The "album" asset catalog image.
    static var album: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .album)
#else
        .init()
#endif
    }

    /// The "backward" asset catalog image.
    static var backward: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .backward)
#else
        .init()
#endif
    }

    /// The "dislike-active" asset catalog image.
    static var dislikeActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dislikeActive)
#else
        .init()
#endif
    }

    /// The "dislike-default" asset catalog image.
    static var dislikeDefault: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .dislikeDefault)
#else
        .init()
#endif
    }

    /// The "forward" asset catalog image.
    static var forward: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .forward)
#else
        .init()
#endif
    }

    /// The "like-active" asset catalog image.
    static var likeActive: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .likeActive)
#else
        .init()
#endif
    }

    /// The "like-default" asset catalog image.
    static var likeDefault: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .likeDefault)
#else
        .init()
#endif
    }

    /// The "pause" asset catalog image.
    static var pause: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pause)
#else
        .init()
#endif
    }

    /// The "play" asset catalog image.
    static var play: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .play)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

