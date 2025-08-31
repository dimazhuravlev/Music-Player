import SwiftUI

struct PlaylistCarousel: View {
    let title: String
    let playlists: [PlaylistCard]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(playlists.enumerated()), id: \.offset) { index, playlist in
                        playlist
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct PlaylistCard: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 168, height: 168)
            .clipped()
            .cornerRadius(12)
            .border(Color.white.opacity(0.08), width: 0.66)
    }
}
