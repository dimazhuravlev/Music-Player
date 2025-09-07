import SwiftUI

struct BottomBar: View {
    @State private var isPlaying = false
    @State private var isCardsPressed = false
    @State private var showPlayer = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                MiniPlayer(isPlaying: $isPlaying) {
                    // Present Player as full screen that slides up from bottom
                    showPlayer = true
                }
                Spacer()
                
                ZStack {
                    Image("Ruqya")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(isCardsPressed ? -14 : -10))
                        .offset(x: isCardsPressed ? -14 : -10, y: isCardsPressed ? 4 : 4)
                        .animation(.smooth(duration: 0.15), value: isCardsPressed)

                    Image("album")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(isCardsPressed ? 14 : 10))
                        .offset(x: isCardsPressed ? 16 : 12, y: isCardsPressed ? -2 : -2)
                        .animation(.smooth(duration: 0.15), value: isCardsPressed)
                }
                
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.25)) {
                        isCardsPressed.toggle()
                    }
                    // Reset after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.smooth(duration: 0.25)) {
                            isCardsPressed = false
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                    // Navigate to Collection page (placeholder for now)
                    print("Navigate to Collection page")
                } onPressingChanged: { isPressing in
                    withAnimation(.smooth(duration: 0.2)) {
                        isCardsPressed = isPressing
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 32)
            .padding(.bottom, 24)
            .background(
                Rectangle()
                    .frame(height: 260)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.25), location: 0.2),
                                .init(color: .black.opacity(0.55), location: 0.3),
                                .init(color: .black.opacity(0.85), location: 0.7),
                                .init(color: .black, location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
        }
        .fullScreenCover(isPresented: $showPlayer) {
            Player(dismiss: {
                showPlayer = false
            })
        }
    }
    

}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BottomBar()
    }
}
