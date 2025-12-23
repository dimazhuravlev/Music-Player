import SwiftUI

// Preference key to measure content height
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct BlockerSheet: View {
    let track: Track
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0
    @State private var isAnimating = false
    @StateObject private var gyro = GyroManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 3)
                .padding(.top, 6)
                .padding(.bottom, 48)
            
            // Album cover with blurred background
            ZStack {
                // Blurred background cover
                Image(track.albumCover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .blur(radius: 48)
                    .opacity(isAnimating ? 0.5 : 0)
                    .scaleEffect(isAnimating ? 1.6 : 1)
                    .rotationEffect(.degrees(8))
                    .animation(.spring(duration: 0.5).delay(0.3), value: isAnimating)
                
                // Original cover
                Image(track.albumCover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
                    .offset(y: isAnimating ? 0 : -180)
                    .scaleEffect(isAnimating ? 1 : 0.8)
                    .rotationEffect(.degrees(isAnimating ? (8 + gyro.roll * 8) : -4), anchor: .center)
                    .rotation3DEffect(.degrees(gyro.pitch * 16), axis: (x: 1, y: 0, z: 0))
                    .rotation3DEffect(.degrees(gyro.roll * 16), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: isAnimating)
                    .animation(.easeOut(duration: 0.2), value: gyro.pitch)
                    .animation(.easeOut(duration: 0.2), value: gyro.roll)
            }
            .padding(.bottom, 24)
            
            // Title
            Text("\(track.title) Needs a\u{00A0}Subscription")
                .font(.Headline3)
                .foregroundColor(.fill1)
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 8)
                .animation(.smooth(duration: 0.4).delay(0.2), value: isAnimating)
            
            // Subtitle
            Text("Get full access to play\nthis and thousands more")
                .font(.Text1)
                .foregroundColor(.subtitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 8)
                .animation(.smooth(duration: 0.4).delay(0.2), value: isAnimating)
            
            // Get access button
            Button(action: {
                dismiss()
            }) {
                Text("Get access")
                    .font(.Text1)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 32)
                    .background(Color.white)
                    .cornerRadius(56)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 8)
            .animation(.smooth(duration: 0.4).delay(0.3), value: isAnimating)
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ContentHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
            withAnimation(.easeInOut(duration: 0.3)) {
                contentHeight = height
            }
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.height(300)])
        .presentationDragIndicator(.hidden)
        .background(.ultraThinMaterial)
        .onAppear {
            // Haptic feedback when sheet opens
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            isAnimating = true
        }
    }
}

#Preview {
    BlockerSheet(track: Track(
        id: 1,
        title: "Taste",
        artist: "Uglymoss",
        albumCover: "blur",
        releaseYear: 2023
    ))
}

