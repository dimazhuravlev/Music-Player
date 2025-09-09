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
                        .font(.custom("YangoGroupHeadline-Bold", size: 32))
                        .foregroundColor(selectedTab == index ? .white : .white.opacity(0.35))
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
                        .fill(Color.white)
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
                VariableBlurView(maxBlurRadius: 8, direction: .blurredTopClearBottom)
                    .frame(height: 105)
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
                    startPoint: .top,
                    endPoint: .bottom
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
