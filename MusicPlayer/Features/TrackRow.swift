import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Models

struct Track: Identifiable, Codable {
    let id: Int
    let title: String
    let artist: String
    let albumCover: String
    let releaseYear: Int
    var albumCoverURL: URL? = nil
    var artistImageURL: URL? = nil      // XL (1000px) for player background
    var artistThumbnailURL: URL? = nil  // Medium (250px) for small avatars
    var deezerAlbumId: Int? = nil
    var previewURL: URL? = nil
    var albumTitle: String? = nil       // Album name shown in player header
    var trackTitle: String? = nil       // A real track name from that album
}

struct TrackRow: View {
    let track: Track
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)? = nil
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: track.albumCoverURL, assetName: track.albumCover)
                .frame(width: 48, height: 48)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(track.title)
                    .font(.Text1)
                    .foregroundColor(.fill1)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.Text1)
                    .foregroundColor(.subtitle)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: { onLongPress?() }) {
                Image(systemName: "ellipsis")
                    .font(.Text1)
                    .foregroundColor(.subtitle)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            onLongPress?()
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 16),
            alignment: .bottom
        )
    }
}

