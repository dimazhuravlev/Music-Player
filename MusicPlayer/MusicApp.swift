#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

@main
struct MusicApp: App {
    init() {
        // Register custom fonts on app launch
        FontManager.shared.registerFonts()
#if canImport(UIKit)
        UIWindow.appearance().backgroundColor = UIColor.black
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @StateObject private var toastManager = ToastManager.shared
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            NavigationStack {
                MainContentView()
                    .background(Color.black)
                    .statusBar(hidden: false)
            }
            .preferredColorScheme(.dark)
        }
        .toast(isPresented: $toastManager.isPresented, config: toastManager.currentConfig)
    }
}

struct MainContentView: View {
    @State private var selectedTab = 0
    @State private var isTransitioning = false
    @State private var previousTab = 0
    @State private var pendingTab = 0
    
    init() {
        // Initialize pendingTab to match selectedTab
        _pendingTab = State(initialValue: 0)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Showcase content with sequential fade and slight blur
            Group {
                switch pendingTab {
                case 0:
                    ForYouShowcase()
                        .opacity(isTransitioning ? 0 : 1)
                        .blur(radius: isTransitioning ? 4 : 0)
                case 1:
                    TrendsShowcase()
                        .opacity(isTransitioning ? 0 : 1)
                        .blur(radius: isTransitioning ? 4 : 0)
                case 2:
                    ReligiousShowcase()
                        .opacity(isTransitioning ? 0 : 1)
                        .blur(radius: isTransitioning ? 4 : 0)
                default:
                    ForYouShowcase()
                        .opacity(isTransitioning ? 0 : 1)
                        .blur(radius: isTransitioning ? 4 : 0)
                }
            }
            .animation(.smooth(duration: 0.3), value: isTransitioning)
            .onChange(of: selectedTab) { oldValue, newValue in
                // Only animate if actually changing tabs
                guard oldValue != newValue else { return }
                
                // Phase 1: Fade out current showcase (0.3s)
                isTransitioning = true
                
                // Phase 2: After fade out completes, switch content and fade in new showcase
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    previousTab = pendingTab
                    pendingTab = newValue
                    isTransitioning = true
                    
                    // Then fade in the new showcase
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                        isTransitioning = false
                    }
                }
            }
            
            // Fixed top navbar that stays in place during navigation
            VStack {
                TopNavBar(selectedTab: $selectedTab)
                Spacer()
            }
            
            // Fixed bottom bar that stays in place during navigation
            VStack {
                Spacer()
                BottomBar()
            }
        }
    }
}

#Preview {
    NavigationStack {
        MainContentView()
    }
}
