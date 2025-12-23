import SwiftUI

// MARK: - Models

struct Track: Identifiable {
    let id: Int
    let title: String
    let artist: String
    let albumCover: String
    let releaseYear: Int
}

struct TrackRow: View {
    let track: Track
    var onTap: (() -> Void)?
    @State private var isPlaying = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(track.albumCover)
                .resizable()
                .scaledToFill()
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
            
            Button(action: {}) {
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
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 16),
            alignment: .bottom
        )
    }
}

