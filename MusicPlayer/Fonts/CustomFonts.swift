import SwiftUI

extension Font {
    // Custom font families
    static func customFont(_ name: String, size: CGFloat, weight: Font.Weight = .black) -> Font {
        return Font.custom(name, size: size)
            .weight(weight)
    }
    
    // Custom weight variants using variable font
    static let Title1 = Font.custom("YS Market VF", size: 48).weight(.bold)
    static let Title2 = Font.custom("YS Market VF", size: 40).weight(.bold)
    static let Text1 = Font.custom("YS Market VF", size: 32).weight(.bold)
    static let Text2 = Font.custom("YS Market VF", size: 28).weight(.bold)
    static let Text3 = Font.custom("YS Market VF", size: 24).weight(.bold)
}

// Font family names for easy reference
struct CustomFontFamily {
    static let ysMarketVF = "YS Market VF"
}
