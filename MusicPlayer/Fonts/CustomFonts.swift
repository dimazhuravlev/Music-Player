import SwiftUI

extension Font {
    // Custom font families
    static func customFont(_ name: String, size: CGFloat) -> Font {
        return Font.custom(name, size: size)
    }
    
    // Custom font variants using YangoGroupHeadlineAR-ExtraBold
    static var Headline1: Font { Font.custom("YangoGroupHeadlineAR-ExtraBold", size: 48) }
    static var Headline2: Font { Font.custom("YangoGroupHeadlineAR-ExtraBold", size: 40) }
    static var Headline3: Font { Font.custom("YangoGroupHeadlineAR-ExtraBold", size: 32) }
    static var Headline4: Font { Font.custom("YangoGroupHeadlineAR-ExtraBold", size: 28) }
    static var Headline5: Font { Font.custom("YangoGroupHeadlineAR-ExtraBold", size: 24) }
    
    // Custom font variants using YangoText-Medium
    static var Title1: Font { Font.custom("YangoText-Medium", size: 24) }
    static var Title2: Font { Font.custom("YangoText-Medium", size: 18) }
    static var Text1: Font { Font.custom("YangoText-Medium", size: 15) }
    static var Text2: Font { Font.custom("YangoText-Medium", size: 13) }
    static var Text3: Font { Font.custom("YangoText-Medium", size: 11) }
}

// Font family names for easy reference
struct CustomFontFamily {
    static let yangoGroupHeadlineBold = "YangoGroupHeadlineAR-ExtraBold"
    static let yangoTextMedium = "YangoText-Medium"
}
