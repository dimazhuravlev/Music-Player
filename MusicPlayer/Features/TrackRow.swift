import SwiftUI

// MARK: - Models

struct Track {
    let id: Int
    let title: String
    let artist: String
    let albumCover: String
}

struct TrackRow: View {
    let track: Track
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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(track.title)
                    .font(.Text1)
                    .foregroundColor(.fill1)
                
                Text(track.artist)
                    .font(.Text1)
                    .foregroundColor(.subtitle)
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
        .onTapGesture { isPlaying.toggle() }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 16),
            alignment: .bottom
        )
    }
}

