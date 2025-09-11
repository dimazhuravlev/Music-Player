import SwiftUI

struct PlaylistCarousel: View {
    let title: String
    let playlists: [PlaylistCard]
    let onPlaylistTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.Headline5)
                .foregroundColor(.fill1)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(playlists.enumerated()), id: \.offset) { index, playlist in
                        PlaylistCard(imageName: playlist.imageName, onTap: {
                            onPlaylistTap(playlist.imageName)
                        })
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct PlaylistCard: View {
    let imageName: String
    let onTap: () -> Void
    @State private var cardTapScale: CGFloat = 1.0
    @State private var cardLongTapScale: CGFloat = 1.0
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 168, height: 168)
            .clipped()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
            )
            .scaleEffect(cardTapScale * cardLongTapScale)
            .animation(.smooth(duration: 0.1), value: cardTapScale)
            .animation(.smooth(duration: 0.2), value: cardLongTapScale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Scale down immediately when pressed
                        cardLongTapScale = 0.95
                    }
                    .onEnded { _ in
                        // Scale back up when released
                        cardLongTapScale = 1.0
                    }
            )
            .onTapGesture {
                // Tap animation with completion guarantee
                withAnimation(.smooth(duration: 0.1)) {
                    cardTapScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.smooth(duration: 0.1)) {
                        cardTapScale = 1.0
                    }
                }
                
                // Call the navigation action
                onTap()
            }
    }
}
