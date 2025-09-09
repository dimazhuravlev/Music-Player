import SwiftUI
import VariableBlur

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
        }
        .background (alignment: .bottom) {
            ZStack {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop)
                    .frame(height: 100)
                    .ignoresSafeArea()
                
                // Dark gradient overlay for better contrast
                LinearGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: .black.opacity(0.9), location: 0.00),
                        Gradient.Stop(color: .black.opacity(0.85), location: 0.11),
                        Gradient.Stop(color: .black.opacity(0.81), location: 0.20),
                        Gradient.Stop(color: .black.opacity(0.75), location: 0.27),
                        Gradient.Stop(color: .black.opacity(0.7), location: 0.34),
                        Gradient.Stop(color: .black.opacity(0.65), location: 0.39),
                        Gradient.Stop(color: .black.opacity(0.59), location: 0.44),
                        Gradient.Stop(color: .black.opacity(0.53), location: 0.48),
                        Gradient.Stop(color: .black.opacity(0.47), location: 0.53),
                        Gradient.Stop(color: .black.opacity(0.41), location: 0.57),
                        Gradient.Stop(color: .black.opacity(0.35), location: 0.61),
                        Gradient.Stop(color: .black.opacity(0.28), location: 0.67),
                        Gradient.Stop(color: .black.opacity(0.21), location: 0.73),
                        Gradient.Stop(color: .black.opacity(0.14), location: 0.81),
                        Gradient.Stop(color: .black.opacity(0.07), location: 0.89),
                        Gradient.Stop(color: .black.opacity(0), location: 1.00),
                        ],),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 100)
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()

    
        .sheet(isPresented: $showPlayer) {
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
