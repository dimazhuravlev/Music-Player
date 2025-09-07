import SwiftUI

extension Font {
    // Custom font families
    static func customFont(_ name: String, size: CGFloat) -> Font {
        return Font.custom(name, size: size)
    }
    
    // Custom font variants using YangoGroupHeadline-Bold
    static let Title1 = Font.custom("YangoGroupHeadline-Bold", size: 48)
    static let Title2 = Font.custom("YangoGroupHeadline-Bold", size: 40)
    static let Text1 = Font.custom("YangoGroupHeadline-Bold", size: 32)
    static let Text2 = Font.custom("YangoGroupHeadline-Bold", size: 28)
    static let Text3 = Font.custom("YangoGroupHeadline-Bold", size: 24)
}

// Font family names for easy reference
struct CustomFontFamily {
    static let yangoGroupHeadlineBold = "YangoGroupHeadline-Bold"
}
