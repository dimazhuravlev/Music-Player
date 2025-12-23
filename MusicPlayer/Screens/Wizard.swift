import SwiftUI

struct Wizard: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var isPressed = false
    @State private var scrollPosition: Int? = nil
    @State private var selectedCardIndex = 0 // Track the currently selected card
    @State private var selectedCards: Set<Int> = [] // Track all selected cards
    @State private var lastSelectedIndex: Int? = nil // Track the most recently selected card
    @State private var titleOpacity: Double = 1.0
    @State private var currentTitleText: String = "Find Your Music Self"
    @State private var currentSubtitleText: String = "Pick some vibes that fits you best"
    @State private var titleShakeOffset: CGFloat = 0
    private var totalCards: Int {
        GenreCatalog.shared.entries.count
    }
    private let multiplier = 3 // Optimized multiplier for smooth 60fps performance
    
    init() {
        // Start at a large offset to allow infinite scrolling in both directions
        _currentIndex = State(initialValue: totalCards * 2) // Start in the middle of the range
        _scrollPosition = State(initialValue: totalCards * 2) // Initialize scroll position to match currentIndex
    }
    
    var body: some View {
        NavigationStack {
            wizardContent
        }
    }
    
    private var wizardContent: some View {
        ZStack {
                // Background cover from GenreCatalog
                Image(GenreCatalog.shared.entries[selectedCardIndex % GenreCatalog.shared.entries.count].backgroundCover)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(.all, edges: .all)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                    .scaleEffect(1.2)
                    .opacity(0.5)
                    .blur(radius: 100)
                    .animation(.smooth(duration: 0.4), value: selectedCardIndex)
                
                VStack(spacing: 0) {
                    // Custom NavBar with back and skip buttons
                    NavBar(
                        showBackButton: true,
                        showSearchButton: false,
                        showSkipButton: true,
                        showBackground: false,
                        onSkipTap: {
                            // Handle skip action - dismiss the wizard
                            withAnimation(.smooth(duration: 3.2)) {
                                dismiss()
                            }
                        },
                        scrollOffset: 0
                    )

                    Spacer()
                    
                    // Title Section
                    VStack(spacing: 2) {
                        Text(currentTitleText)
                            .font(.Headline3)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(titleOpacity)
                        
                        if !currentSubtitleText.isEmpty {
                            Text(currentSubtitleText)
                                .font(.Text1)
                                .foregroundStyle(Color.subtitle)
                                .opacity(titleOpacity)
                        }
                    }
                    .frame(height: 130)
                    .padding(.horizontal, 48)
                    .offset(x: titleShakeOffset)
                    .onChange(of: selectedCards) { oldValue, newValue in
                        // Animate on any change to selectedCards (adding/removing genres)
                        animateTitleTransition()
                    }
                
                Spacer()
                
                // Carousel
                GeometryReader { geometry in
                    let cardWidth: CGFloat = 280
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            // Create a large number of cards for seamless infinite scrolling
                            ForEach(0..<(totalCards * multiplier), id: \.self) { index in
                                let realIndex = index % totalCards
                                GenreCard(
                                    index: realIndex,
                                    isSelected: selectedCards.contains(realIndex),
                                    isActive: abs(realIndex - selectedCardIndex) <= 1,
                                    onTap: {
                                        if selectedCards.contains(realIndex) {
                                            selectedCards.remove(realIndex)
                                            // Clear lastSelectedIndex if we're deselecting it
                                            if lastSelectedIndex == realIndex {
                                                lastSelectedIndex = selectedCards.isEmpty ? nil : selectedCards.first
                                            }
                                            // Haptic feedback for untap/deselect
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        } else {
                                            selectedCards.insert(realIndex)
                                            lastSelectedIndex = realIndex // Track the most recently selected
                                            // Haptic feedback for tap/select
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                )
                                .frame(width: cardWidth, height: cardWidth * 1.52)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                        .padding(.vertical, 20) // Add vertical padding for shadows
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $scrollPosition)
                    .scrollTargetBehavior(.viewAligned)
                    .onChange(of: scrollPosition) { _, newPosition in
                        guard let newPosition = newPosition else { return }
                        currentIndex = newPosition
                        selectedCardIndex = newPosition % totalCards
                        
                        // Add haptic feedback when scrolling to a new card
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
                
                Spacer(minLength: 24)
                
                 // Custom Next Button (no native highlight)
                 ZStack {
                     Text("Save")
                         .font(.Text1)
                         .foregroundStyle((selectedCards.isEmpty || isSpiritualOnlySelected()) ? Color.white.opacity(0.3) : Color.black)
                         .padding(.vertical, 20)
                         .padding(.horizontal, 64)
                         .background((selectedCards.isEmpty || isSpiritualOnlySelected()) ? Color.white.opacity(0.1) : Color.white)
                         .clipShape(Capsule())
                         .scaleEffect(isPressed ? 0.95 : 1.0)
                         .animation(.smooth(duration: 0.15), value: isPressed)
                         .animation(.smooth(duration: 0.4), value: selectedCards.isEmpty)
                         .animation(.smooth(duration: 0.4), value: isSpiritualOnlySelected())
                 }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                withAnimation(.smooth(duration: 0.2)) { isPressed = true }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.smooth(duration: 0.2)) { isPressed = false }
                            
                            if selectedCards.isEmpty || isSpiritualOnlySelected() {
                                triggerShakeAnimation()
                            } else {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                dismiss()
                            }
                        }
                )

                Spacer(minLength: 32)

                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(1)
        .navigationBarHidden(true)
    }
    
    // Animate title transition with opacity
    private func animateTitleTransition() {
        withAnimation(.smooth(duration: 0.4)) {
            titleOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateTitleText()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.smooth(duration: 0.4)) {
                    titleOpacity = 1.0
                }
            }
        }
    }
    
    // Update title and subtitle based on selected genres
    private func updateTitleText() {
        if selectedCards.isEmpty {
            currentTitleText = "Find Your Music Self"
            currentSubtitleText = "Pick some vibes that fits you best"
            return
        }
        
        // Build formatted genre string
        let catalog = GenreCatalog.shared
        var selectedGenres = selectedCards.map { index in
            catalog.entries[index % catalog.entries.count].genre
        }
        
        // Move the last selected genre to the first position
        if let lastSelected = lastSelectedIndex {
            let lastSelectedGenre = catalog.entries[lastSelected % catalog.entries.count].genre
            selectedGenres.removeAll { $0 == lastSelectedGenre }
            selectedGenres.insert(lastSelectedGenre, at: 0)
        }
        
        let genreText: String
        switch selectedGenres.count {
        case 1:
            genreText = selectedGenres[0]
        case 2:
            genreText = "\(selectedGenres[0]) and \(selectedGenres[1])"
        default:
            genreText = "\(selectedGenres[0]), \(selectedGenres[1]) and so much more"
        }
        
        currentTitleText = "I'm all about \(genreText)"
        currentSubtitleText = (selectedCards.count == 1 && isSpiritualOnlySelected()) ? "Pick one more vibe" : ""
    }
    
    // Check if only Spiritual genre is selected
    private func isSpiritualOnlySelected() -> Bool {
        guard selectedCards.count == 1 else { return false }
        let spiritualIndex = 3 // Spiritual genre is at index 3 in the catalog
        return selectedCards.contains(spiritualIndex)
    }
    
    // Trigger shake animation for empty title
    private func triggerShakeAnimation() {
        // Create symmetrical left-right shake with damping
        let shakeSequence = [
            (offset: 12.0, duration: 0.07, intensity: 1.0),
            (offset: -11.0, duration: 0.07, intensity: 1.0),
            (offset: 10.0, duration: 0.07, intensity: 0.8),
            (offset: -9.0, duration: 0.07, intensity: 0.8),
            (offset: 7.0, duration: 0.07, intensity: 0.6),
            (offset: -6.0, duration: 0.07, intensity: 0.5),
            (offset: 3.0, duration: 0.07, intensity: 0.4),
            (offset: -2.0, duration: 0.07, intensity: 0.3),
            (offset: 0.0, duration: 0.10, intensity: nil)
        ]
        
        var currentDelay: Double = 0
        
        for (index, shake) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                withAnimation(.smooth(duration: shake.duration)) {
                    self.titleShakeOffset = shake.offset
                }
                
                // Trigger haptic feedback synchronously with shake
                if let intensity = shake.intensity {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred(intensity: CGFloat(intensity))
                }
            }
            currentDelay += shake.duration
        }
    }
    
}




#Preview {
    NavigationStack {
        Wizard()
    }
}
