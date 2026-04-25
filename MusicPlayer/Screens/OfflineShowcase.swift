import SwiftUI

/// Витрина в офлайн-режиме: тот же контент, что у For You; навигация — один заголовок «Offline» в `TopNavBar`.
struct OfflineShowcase: View {
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    
    var body: some View {
        ShowcaseFeedView(
            albumCarouselTitleOverrides: [
                "Saved Tracks",
                "Saved Albums",
                "Saved Playlists"
            ],
            shaderPlayer: shaderPlayer
        )
    }
}

#Preview {
    OfflineShowcase(shaderPlayer: ShaderPlayerManager())
}
