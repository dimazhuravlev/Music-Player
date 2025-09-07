import SwiftUI

struct MiniPlayer: View {
    @Binding var isPlaying: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            // Album art
            Image("album")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .cornerRadius(6)
            
            // Animated play/pause icon
            AnimatedIconButton(
                icon1: "play",
                icon2: "pause",
                isActive: isPlaying,
                iconSize: 24
            ) {
                isPlaying.toggle()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 72)
                .fill(.thinMaterial)
        )
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MiniPlayer(isPlaying: .constant(false)) {
            print("MiniPlayer tapped!")
        }
    }
}
