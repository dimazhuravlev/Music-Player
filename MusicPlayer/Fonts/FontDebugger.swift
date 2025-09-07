import SwiftUI

struct FontDebugger {
    static func printAvailableFonts() {
        print("=== Available Font Families ===")
        // Note: SwiftUI Font doesn't provide direct access to system font families
        // This is a simplified version that works with SwiftUI-only approach
        let commonFonts = [
            "System", "Helvetica", "Times New Roman", "Courier", "Arial",
            "Georgia", "Verdana", "Trebuchet MS", "Impact", "Comic Sans MS"
        ]
        
        for font in commonFonts {
            print("Font: \(font)")
        }
        print("===============================")
        print("Note: For full font family listing, UIKit import is required")
    }
}
