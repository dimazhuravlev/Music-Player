import SwiftUI

struct PlaylistCarousel: View {
    let title: String
    let playlists: [PlaylistCard]
    let onPlaylistTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.Headline5)
                    .foregroundColor(.fill1)
                
                Image("shevron")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.subtitle)
                    .frame(width: 20, height: 20)
            }
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
    
    var body: some View {
        Button {
            onTap()
        } label: {
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
        }
        .buttonStyle(PlaylistCardButtonStyle())
    }
}

private struct PlaylistCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}
