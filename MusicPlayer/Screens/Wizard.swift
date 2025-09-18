import SwiftUI

struct Wizard: View {
    @State private var currentIndex = 8 // Start at the first real card (after duplicates)
    private let totalCards = 8
    private let multiplier = 3 // Create 3 sets for infinite scrolling
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Carousel
                GeometryReader { geometry in
                    let cardWidth = geometry.size.width * 0.5
                    let cardSpacing: CGFloat = 20
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: cardSpacing) {
                                // Create multiple sets of cards for infinite scrolling
                                ForEach(0..<(totalCards * multiplier), id: \.self) { index in
                                    let realIndex = index % totalCards
                                    CarouselCard(index: realIndex)
                                        .frame(width: cardWidth, height: cardWidth * 1.6)
                                        .id(index)
                                }
                            }
                            .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollTargetLayout()
                        .onAppear {
                            // Start at the middle set (first real card)
                            proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
                        }
                        .onChange(of: currentIndex) { _, newIndex in
                            handleInfiniteScroll(proxy: proxy)
                        }
                    }
                }
                .frame(height: 300)
                
                Spacer()
            }
        }
    }
    
    private func handleInfiniteScroll(proxy: ScrollViewProxy) {
        // If we're at the beginning (first set), jump to the last set
        if currentIndex < totalCards {
            currentIndex = totalCards * 2 + (currentIndex % totalCards)
            withAnimation(.linear(duration: 0.1)) {
                proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
            }
        }
        // If we're at the end (last set), jump to the first set
        else if currentIndex >= totalCards * 2 {
            currentIndex = totalCards + (currentIndex % totalCards)
            withAnimation(.linear(duration: 0.1)) {
                proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
            }
        }
    }
}

struct CarouselCard: View {
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}



#Preview {
    NavigationStack {
        Wizard()
    }
}
