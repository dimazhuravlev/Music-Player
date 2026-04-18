import SwiftUI

struct ForYouShowcase: View {
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    
    var body: some View {
        ShowcaseFeedView(skeletonFirstAlbumCarousel: true, shaderPlayer: shaderPlayer)
    }
}

#Preview {
    ForYouShowcase(shaderPlayer: ShaderPlayerManager())
}
