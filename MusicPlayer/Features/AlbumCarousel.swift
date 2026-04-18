import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Горизонтальная карусель альбомов: три полные квадратные карточки и узкий край четвёртой (размер от ширины экрана).
struct AlbumCarousel: View {
    let title: String
    let albums: [AlbumCardItem]
    let onAlbumTap: (AlbumCardItem) -> Void
    var onAlbumLongPress: ((AlbumCardItem) -> Void)? = nil
    
    private let contentInset: CGFloat = 16
    private let cardSpacing: CGFloat = 8
    /// Видимая полоска четвёртой карточки у правого края экрана.
    private let fourthCardPeek: CGFloat = 26
    private let textBlockHeight: CGFloat = 44
    
    private var layoutWidth: CGFloat {
        #if canImport(UIKit)
        max(UIScreen.main.bounds.width, 320)
        #else
        390
        #endif
    }
    
    /// Три карточки + два зазора + peek укладываются в `(layoutWidth − contentInset)` от левого края первой обложки до правого края экрана.
    private var coverSize: CGFloat {
        let rowWidth = layoutWidth - contentInset
        let raw = (rowWidth - 2 * cardSpacing - fourthCardPeek) / 3
        return max(92, min(raw, 160))
    }
    
    private var coverCornerRadius: CGFloat { coverSize * (12 / 168) }
    
    private var rowScrollHeight: CGFloat { coverSize + 8 + textBlockHeight }
    
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
                    ForEach(albums) { item in
                        AlbumCard(
                            item: item,
                            coverSize: coverSize,
                            coverCornerRadius: coverCornerRadius,
                            onTap: { onAlbumTap(item) },
                            onLongPress: onAlbumLongPress.map { handler in { handler(item) } }
                        )
                    }
                }
                .padding(.horizontal, contentInset)
            }
            .frame(height: rowScrollHeight)
        }
    }
}

struct AlbumCardItem: Identifiable, Equatable, Codable {
    let id: String
    let coverImageName: String
    let albumTitle: String
    let artistName: String
    var coverImageURL: URL? = nil
    var deezerAlbumId: Int? = nil
}

/// Квадратная обложка как у `PlaylistCard`, под ней название альбома (белый) и исполнитель (серый).
struct AlbumCard: View {
    let item: AlbumCardItem
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
            VStack(alignment: .leading, spacing: 8) {
                CachedAsyncImage(url: item.coverImageURL, assetName: item.coverImageName)
                    .frame(width: coverSize, height: coverSize)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: coverCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.albumTitle)
                        .font(.Text1)
                        .foregroundStyle(Color.fill1)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(item.artistName)
                        .font(.Text1)
                        .foregroundStyle(Color.offlineBannerSubtitle)
                        .lineLimit(1)
                }
                .frame(width: coverSize, alignment: .leading)
            }
            .frame(width: coverSize, alignment: .topLeading)
        }
        .buttonStyle(AlbumCardButtonStyle())
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

private struct AlbumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ScrollView {
        AlbumCarousel(
            title: "Albums",
            albums: [],
            onAlbumTap: { _ in }
        )
    }
    .background(Color.black)
}
