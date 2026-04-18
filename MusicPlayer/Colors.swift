import SwiftUI

// Color variants for consistent styling
extension Color {
    static let fill1 = Color.white
    /// Inactive tab / secondary label (Figma fill/five)
    static let fill5 = Color.white.opacity(0.6)
    static let subtitle = Color.white.opacity(0.5)
    static let accent = Color(red: 0.64, green: 0.2, blue: 1.0)
    /// Downloads tab — Offline Mode banner
    static let offlineBannerBackground = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let offlineBannerSubtitle = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
}
