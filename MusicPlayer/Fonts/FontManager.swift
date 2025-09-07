import SwiftUI
import CoreText

class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    func registerFonts() {
        // Register YSMarket-VF.ttf
        if let fontURL = Bundle.main.url(forResource: "YSMarket-VF", withExtension: "ttf") {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("✅ YSMarket-VF font registered successfully")
            } else {
                print("❌ Failed to register YSMarket-VF font: \(error?.takeRetainedValue() ?? "Unknown error" as! CFError)")
            }
        } else {
            print("❌ YSMarket-VF.ttf not found in bundle")
        }
    }
}
