import SwiftUI
import VariableBlur

struct TopNavBar: View {
    @Binding var selectedTab: Int
    @State private var pressedTabIndex: Int? = nil
    
    let tabs = ["For You", "Trends", "Religious"]
    
    var body: some View {
        HStack {
            // Tab buttons with indicator
            HStack(spacing: 10) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Text(tab)
                        .font(.Headline3)
                        .foregroundColor(selectedTab == index ? .fill1 : .white.opacity(0.35))
                        .shadow(color: selectedTab == index ? .clear : .black.opacity(0.5), radius: 2, x: 0, y: 0)
                        .shadow(color: selectedTab == index ? .clear : .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .animation(.smooth(duration: 0.4), value: selectedTab)
                        .scaleEffect(pressedTabIndex == index ? 0.9 : 1.0)
                        .animation(.smooth(duration: 0.1), value: pressedTabIndex)
                        .onTapGesture {
                            selectedTab = index
                        }
                        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                            pressedTabIndex = pressing ? index : nil
                        }, perform: {})
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if pressedTabIndex == nil {
                                        pressedTabIndex = index
                                    }
                                }
                                .onEnded { _ in
                                    pressedTabIndex = nil
                                }
                        )
                }
            }
            .overlay(alignment: .topLeading) {
                // Active tab indicator (white pin) - positioned precisely
                GeometryReader { geometry in
                    let tabWidth = (geometry.size.width - CGFloat(tabs.count - 1) * 10) / CGFloat(tabs.count)
                    let pinX = CGFloat(selectedTab) * (tabWidth + 5) + tabWidth / 2
                    
                    Circle()
                        .fill(Color.fill1)
                        .frame(width: 8, height: 8)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 0)
                        .position(x: pinX, y: 48)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0), value: selectedTab)
                }
                .frame(height: 40)
            }
            
            Spacer()
            
            // User profile picture
            Button(action: {
                // Handle profile tap
            }) {
                Image("userpic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .background {
            ZStack {
                VariableBlurView(maxBlurRadius: 16, direction: .blurredTopClearBottom)
                    .frame(height: 105)
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
                        ],),
                    startPoint: .bottom, 
                    endPoint: .top
                )
                .frame(height: 120)
                .ignoresSafeArea()
            }
        }
    }
}


#Preview {
    ZStack {
        TopNavBar(selectedTab: .constant(0))
    }
}
