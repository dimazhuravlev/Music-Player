import SwiftUI
import CoreText

class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    func registerFonts() {
        // Register YangoGroupHeadlineAR-ExtraBold.otf
        if let fontURL = Bundle.main.url(forResource: "YangoGroupHeadlineAR-ExtraBold", withExtension: "otf") {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("✅ YangoGroupHeadlineAR-ExtraBold font registered successfully")
            } else {
                print("❌ Failed to register YangoGroupHeadlineAR-ExtraBold font: \(error?.takeRetainedValue() ?? "Unknown error" as! CFError)")
            }
        } else {
            print("❌ YangoGroupHeadlineAR-ExtraBold.otf not found in bundle")
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
