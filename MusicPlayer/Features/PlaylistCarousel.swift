import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PlaylistCarousel: View {
    let title: String
    let playlists: [PlaylistCard]
    let onPlaylistTap: (String) -> Void
    var onPlaylistLongPress: ((String) -> Void)? = nil

    private let contentInset: CGFloat = 16
    private let cardSpacing: CGFloat = 8
    private let fourthCardPeek: CGFloat = 26

    private var layoutWidth: CGFloat {
        #if canImport(UIKit)
        max(UIScreen.main.bounds.width, 320)
        #else
        390
        #endif
    }

    private var coverSize: CGFloat {
        let rowWidth = layoutWidth - contentInset
        let raw = (rowWidth - 2 * cardSpacing - fourthCardPeek) / 3
        return max(92, min(raw, 160))
    }

    private var coverCornerRadius: CGFloat { coverSize * (12 / 168) }

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
            .padding(.horizontal, contentInset)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(Array(playlists.enumerated()), id: \.offset) { index, playlist in
                        PlaylistCard(
                            imageName: playlist.imageName,
                            coverSize: coverSize,
                            coverCornerRadius: coverCornerRadius,
                            onTap: { onPlaylistTap(playlist.imageName) },
                            onLongPress: onPlaylistLongPress.map { handler in { handler(playlist.imageName) } }
                        )
                    }
                }
                .padding(.horizontal, contentInset)
            }
            .frame(height: coverSize)
        }
    }
}

struct PlaylistCard: View {
    let imageName: String
    var imageURL: URL? = nil
    var coverSize: CGFloat = 168
    var coverCornerRadius: CGFloat = 12
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var suppressTap = false

    var body: some View {
        Button {
            guard !suppressTap else { suppressTap = false; return }
            onTap()
        } label: {
            CachedAsyncImage(url: imageURL, assetName: imageName)
                .frame(width: coverSize, height: coverSize)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: coverCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                )
        }
        .buttonStyle(PlaylistCardButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3).onEnded { _ in
                suppressTap = true
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                onLongPress?()
            }
        )
    }
}

private struct PlaylistCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

