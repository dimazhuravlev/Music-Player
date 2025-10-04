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
                        .frame(width: 44, height: 44)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.fill1, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(isCardsPressed ? -14 : -10))
                        .offset(x: isCardsPressed ? -14 : -10, y: isCardsPressed ? 4 : 4)
                        .animation(.smooth(duration: 0.15), value: isCardsPressed)

                    Image("blur")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.fill1, lineWidth: 2)
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
            .padding(.bottom, 40)
        }
        .background (alignment: .bottom) {
            ZStack {
                VariableBlurView(maxBlurRadius: 8, direction: .blurredBottomClearTop)
                    .frame(height: 100)
                    .ignoresSafeArea()
                
                // Dark gradient overlay for better contrast
                LinearGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: .black.opacity(0), location: 0.00),
                        Gradient.Stop(color: .black.opacity(0.07), location: 0.11),
                        Gradient.Stop(color: .black.opacity(0.13), location: 0.21),
                        Gradient.Stop(color: .black.opacity(0.18), location: 0.28),
                        Gradient.Stop(color: .black.opacity(0.24), location: 0.34),
                        Gradient.Stop(color: .black.opacity(0.29), location: 0.39),
                        Gradient.Stop(color: .black.opacity(0.34), location: 0.44),
                        Gradient.Stop(color: .black.opacity(0.39), location: 0.48),
                        Gradient.Stop(color: .black.opacity(0.44), location: 0.51),
                        Gradient.Stop(color: .black.opacity(0.49), location: 0.55),
                        Gradient.Stop(color: .black.opacity(0.53), location: 0.59),
                        Gradient.Stop(color: .black.opacity(0.58), location: 0.65),
                        Gradient.Stop(color: .black.opacity(0.63), location: 0.71),
                        Gradient.Stop(color: .black.opacity(0.69), location: 0.79),
                        Gradient.Stop(color: .black.opacity(0.74), location: 0.88),
                        Gradient.Stop(color: .black.opacity(0.8), location: 1.00),
                        ]),
                    startPoint: .top,
                    endPoint: .bottom
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
