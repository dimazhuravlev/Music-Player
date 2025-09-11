import SwiftUI
import CoreText

class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    func registerFonts() {
        // Register YangoGroupHeadline-Bold.otf
        if let fontURL = Bundle.main.url(forResource: "YangoGroupHeadline-Bold", withExtension: "otf") {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("✅ YangoGroupHeadline-Bold font registered successfully")
            } else {
                print("❌ Failed to register YangoGroupHeadline-Bold font: \(error?.takeRetainedValue() ?? "Unknown error" as! CFError)")
            }
        } else {
            print("❌ YangoGroupHeadline-Bold.otf not found in bundle")
        }
        
        // Register YangoText-Medium.ttf
        if let fontURL = Bundle.main.url(forResource: "YangoText-Medium", withExtension: "ttf") {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("✅ YangoText-Medium font registered successfully")
            } else {
                print("❌ Failed to register YangoText-Medium font: \(error?.takeRetainedValue() ?? "Unknown error" as! CFError)")
            }
        } else {
            print("❌ YangoText-Medium.ttf not found in bundle")
        }
    }
}
