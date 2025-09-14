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

    /// The "aquarium" asset catalog image resource.
    static let aquarium = DeveloperToolsSupport.ImageResource(name: "aquarium", bundle: resourceBundle)

    /// The "backward" asset catalog image resource.
    static let backward = DeveloperToolsSupport.ImageResource(name: "backward", bundle: resourceBundle)

    /// The "benson" asset catalog image resource.
    static let benson = DeveloperToolsSupport.ImageResource(name: "benson", bundle: resourceBundle)

    /// The "benson boone" asset catalog image resource.
    static let bensonBoone = DeveloperToolsSupport.ImageResource(name: "benson boone", bundle: resourceBundle)

    /// The "blur" asset catalog image resource.
    static let blur = DeveloperToolsSupport.ImageResource(name: "blur", bundle: resourceBundle)

    /// The "cure" asset catalog image resource.
    static let cure = DeveloperToolsSupport.ImageResource(name: "cure", bundle: resourceBundle)

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

    /// The "love letters" asset catalog image resource.
    static let loveLetters = DeveloperToolsSupport.ImageResource(name: "love letters", bundle: resourceBundle)

    /// The "my bloody valentine" asset catalog image resource.
    static let myBloodyValentine = DeveloperToolsSupport.ImageResource(name: "my bloody valentine", bundle: resourceBundle)

    /// The "pause" asset catalog image resource.
    static let pause = DeveloperToolsSupport.ImageResource(name: "pause", bundle: resourceBundle)

    /// The "pixies" asset catalog image resource.
    static let pixies = DeveloperToolsSupport.ImageResource(name: "pixies", bundle: resourceBundle)

    /// The "play" asset catalog image resource.
    static let play = DeveloperToolsSupport.ImageResource(name: "play", bundle: resourceBundle)

    /// The "sonic" asset catalog image resource.
    static let sonic = DeveloperToolsSupport.ImageResource(name: "sonic", bundle: resourceBundle)

    /// The "teddy swims" asset catalog image resource.
    static let teddySwims = DeveloperToolsSupport.ImageResource(name: "teddy swims", bundle: resourceBundle)

    /// The "tul8et" asset catalog image resource.
    static let tul8Et = DeveloperToolsSupport.ImageResource(name: "tul8et", bundle: resourceBundle)

    /// The "uglymoss" asset catalog image resource.
    static let uglymoss = DeveloperToolsSupport.ImageResource(name: "uglymoss", bundle: resourceBundle)

    /// The "userpic" asset catalog image resource.
    static let userpic = DeveloperToolsSupport.ImageResource(name: "userpic", bundle: resourceBundle)

    /// The "wegz" asset catalog image resource.
    static let wegz = DeveloperToolsSupport.ImageResource(name: "wegz", bundle: resourceBundle)

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

    /// The "aquarium" asset catalog image.
    static var aquarium: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .aquarium)
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

    /// The "benson" asset catalog image.
    static var benson: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .benson)
#else
        .init()
#endif
    }

    /// The "benson boone" asset catalog image.
    static var bensonBoone: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bensonBoone)
#else
        .init()
#endif
    }

    /// The "blur" asset catalog image.
    static var blur: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blur)
#else
        .init()
#endif
    }

    /// The "cure" asset catalog image.
    static var cure: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cure)
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

    /// The "love letters" asset catalog image.
    static var loveLetters: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loveLetters)
#else
        .init()
#endif
    }

    /// The "my bloody valentine" asset catalog image.
    static var myBloodyValentine: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .myBloodyValentine)
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

    /// The "pixies" asset catalog image.
    static var pixies: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pixies)
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

    /// The "sonic" asset catalog image.
    static var sonic: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sonic)
#else
        .init()
#endif
    }

    /// The "teddy swims" asset catalog image.
    static var teddySwims: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .teddySwims)
#else
        .init()
#endif
    }

    /// The "tul8et" asset catalog image.
    static var tul8Et: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tul8Et)
#else
        .init()
#endif
    }

    /// The "uglymoss" asset catalog image.
    static var uglymoss: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .uglymoss)
#else
        .init()
#endif
    }

    /// The "userpic" asset catalog image.
    static var userpic: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .userpic)
#else
        .init()
#endif
    }

    /// The "wegz" asset catalog image.
    static var wegz: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wegz)
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

    /// The "aquarium" asset catalog image.
    static var aquarium: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .aquarium)
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

    /// The "benson" asset catalog image.
    static var benson: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .benson)
#else
        .init()
#endif
    }

    /// The "benson boone" asset catalog image.
    static var bensonBoone: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bensonBoone)
#else
        .init()
#endif
    }

    /// The "blur" asset catalog image.
    static var blur: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .blur)
#else
        .init()
#endif
    }

    /// The "cure" asset catalog image.
    static var cure: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cure)
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

    /// The "love letters" asset catalog image.
    static var loveLetters: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loveLetters)
#else
        .init()
#endif
    }

    /// The "my bloody valentine" asset catalog image.
    static var myBloodyValentine: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .myBloodyValentine)
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

    /// The "pixies" asset catalog image.
    static var pixies: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pixies)
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

    /// The "sonic" asset catalog image.
    static var sonic: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sonic)
#else
        .init()
#endif
    }

    /// The "teddy swims" asset catalog image.
    static var teddySwims: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .teddySwims)
#else
        .init()
#endif
    }

    /// The "tul8et" asset catalog image.
    static var tul8Et: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tul8Et)
#else
        .init()
#endif
    }

    /// The "uglymoss" asset catalog image.
    static var uglymoss: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .uglymoss)
#else
        .init()
#endif
    }

    /// The "userpic" asset catalog image.
    static var userpic: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .userpic)
#else
        .init()
#endif
    }

    /// The "wegz" asset catalog image.
    static var wegz: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wegz)
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

