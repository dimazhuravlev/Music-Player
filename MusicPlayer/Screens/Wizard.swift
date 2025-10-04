import SwiftUI

struct Wizard: View {
    @State private var currentIndex = 0
    @State private var scrollPosition: Int? = nil
    @State private var selectedCardIndex = 0 // Track the currently selected card
    @State private var selectedCards: Set<Int> = [] // Track all selected cards
    @State private var lastSelectedIndex: Int? = nil // Track the most recently selected card
    @State private var titleOpacity: Double = 1.0
    @State private var currentTitleText: String = "Find Your Music Self"
    @State private var currentSubtitleText: String = "Pick some vibe that fits you best"
    private var totalCards: Int {
        GenreCatalog.shared.entries.count
    }
    private let multiplier = 20 // Reduced multiplier for better performance
    
    init() {
        // Start at a large offset to allow infinite scrolling in both directions
        _currentIndex = State(initialValue: totalCards * 10) // Start in the middle of a large range
    }
    
    var body: some View {
        ZStack {
            // Background cover from GenreCatalog
            Image(GenreCatalog.shared.entries[selectedCardIndex % GenreCatalog.shared.entries.count].backgroundCover)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .all)
                .clipped()
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                .scaleEffect(1.8)
                .opacity(0.4)
                .blur(radius: 140)
                .animation(.easeInOut(duration: 0.4), value: selectedCardIndex)     
            
            VStack(spacing: 0) {
                Spacer(minLength: 96)
                
                // Title Section
                VStack(spacing: 2) {
                    if selectedCards.isEmpty {
                        Text(currentTitleText)
                            .font(.Headline3)
                            .foregroundStyle(.white)
                            .opacity(titleOpacity)
                        Text(currentSubtitleText)
                            .font(.Text1)
                            .foregroundStyle(Color.subtitle)
                            .opacity(titleOpacity)
                    } else {
                        Text(currentTitleText)
                            .font(.Headline3)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(titleOpacity)
                    }
                }
                .frame(height: 130)
                .padding(.horizontal, 48)
                .animation(.easeInOut(duration: 0.3), value: selectedCards.isEmpty)
                .onChange(of: selectedCards) { oldValue, newValue in
                    // Animate on any change to selectedCards (adding/removing genres)
                    animateTitleTransition()
                }
                
                Spacer()
                
                // Carousel
                GeometryReader { geometry in
                    let cardWidth: CGFloat = 280
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Create a large number of cards for seamless infinite scrolling
                                ForEach(0..<(totalCards * multiplier), id: \.self) { index in
                                    let realIndex = index % totalCards
                                    GenreCard(
                                        index: realIndex,
                                        isSelected: selectedCards.contains(realIndex),
                                        onTap: {
                                            if selectedCards.contains(realIndex) {
                                                selectedCards.remove(realIndex)
                                                // Clear lastSelectedIndex if we're deselecting it
                                                if lastSelectedIndex == realIndex {
                                                    lastSelectedIndex = selectedCards.isEmpty ? nil : selectedCards.first
                                                }
                                            } else {
                                                selectedCards.insert(realIndex)
                                                lastSelectedIndex = realIndex // Track the most recently selected
                                            }
                                        }
                                    )
                                    .frame(width: cardWidth, height: cardWidth * 1.6)
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                            .padding(.vertical, 20) // Add vertical padding for shadows
                        }
                        .scrollPosition(id: $scrollPosition)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollTargetLayout()
                        .onAppear {
                            // Start at the initial position
                            proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
                            scrollPosition = currentIndex
                        }
                        .onChange(of: scrollPosition) { _, newPosition in
                            guard let newPosition = newPosition else { return }
                            currentIndex = newPosition
                            selectedCardIndex = newPosition % totalCards
                        }
                    }
                }
                // .frame(height: 450)
                // .padding(.vertical, 30) // Increased padding for shadow space
                
                Spacer()
                
                // Next Button
                Button(action: {}) {
                    Text("Next")
                        .font(.Text1)
                        .foregroundStyle(selectedCards.isEmpty ? Color.white.opacity(0.3) : Color.black)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 64)
                        .background(selectedCards.isEmpty ? Color.white.opacity(0.1) : Color.white)
                        .clipShape(Capsule())
                }
                
                Spacer(minLength: 56)
            }
        }
        .ignoresSafeArea(.all, edges: .all)
    }
    
    // Helper function to get the genre names from selected cards (last selected first)
    private func getSelectedGenreName() -> String {
        guard !selectedCards.isEmpty else {
            return ""
        }
        
        let catalog = GenreCatalog.shared
        var selectedGenres = selectedCards.map { index in
            let genreDefinition = catalog.entries[index % catalog.entries.count]
            return genreDefinition.genre
        }
        
        // Move the last selected genre to the first position
        if let lastSelected = lastSelectedIndex {
            let lastSelectedGenre = catalog.entries[lastSelected % catalog.entries.count].genre
            selectedGenres.removeAll { $0 == lastSelectedGenre }
            selectedGenres.insert(lastSelectedGenre, at: 0)
        }
        
        switch selectedGenres.count {
        case 1:
            return selectedGenres[0]
        case 2:
            return "\(selectedGenres[0]) and \(selectedGenres[1])"
        case 3:
            return "\(selectedGenres[0]), \(selectedGenres[1]) and \(selectedGenres[2])"
        default:
            // Show only the first 3 + "and so much more"
            let firstThree = Array(selectedGenres.prefix(3))
            if firstThree.count >= 2 {
                let firstTwo = firstThree.dropLast().joined(separator: ", ")
                let lastGenre = firstThree.last!
                return "\(firstTwo), \(lastGenre) and so much more"
            } else {
                return "\(firstThree[0]) and so much more"
            }
        }
    }
    
    // Animate title transition with opacity
    private func animateTitleTransition() {
        // Phase 1: Fade out old text
        withAnimation(.smooth(duration: 0.6)) {
            titleOpacity = 0.0
        }
        
        // Phase 2: After fade out completes, swap text and fade in new text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Update the text content
            updateTitleText()
            
            // Fade in new text
            withAnimation(.smooth(duration: 0.6)) {
                titleOpacity = 1.0
            }
        }
    }
    
    // Update title text based on current selection
    private func updateTitleText() {
        if selectedCards.isEmpty {
            currentTitleText = "Find Your Music Self"
            currentSubtitleText = "Pick some vibes that fits you best"
        } else {
            currentTitleText = "I'm all about \(getSelectedGenreName())"
            currentSubtitleText = ""
        }
    }
    
}




#Preview {
    NavigationStack {
        Wizard()
    }
}
