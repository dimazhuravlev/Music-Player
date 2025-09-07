import SwiftUI

@main
struct MusicApp: App {
    init() {
        // Register custom fonts on app launch
        FontManager.shared.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    Showcase()
                    
                    // Fixed bottom bar that stays in place during navigation
                    VStack {
                        Spacer()
                        BottomBar()
                    }
                    
                    // Temporary debug button (remove after confirming fonts work)
                    VStack {
                        HStack {
                            Spacer()
                            Button("Debug Fonts") {
                                FontDebugger.printAvailableFonts()
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Showcase()
            
            VStack {
                Spacer()
                BottomBar()
            }
        }
    }
}
