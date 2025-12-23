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
    @StateObject private var gyroManager = GyroManager()
    @StateObject private var nowPlayingState = NowPlayingState()
    @StateObject private var collectionState = CollectionState()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            MainContentView()
                .background(Color.black)
                .statusBar(hidden: false)
                .preferredColorScheme(.dark)
        }
        .environmentObject(gyroManager)
        .environmentObject(nowPlayingState)
        .environmentObject(collectionState)
        .toast(isPresented: $toastManager.isPresented, config: toastManager.currentConfig)
    }
}

// Tab selection enum for top-level navigation
enum AppTab: Int, CaseIterable {
    case showcase = 0
    case collection = 1
    case player = 2
}

struct MainContentView: View {
    @State private var selectedTab = 0
    @State private var isTransitioning = false
    @State private var previousTab = 0
    @State private var pendingTab = 0
    @State private var activeAppTab: AppTab = .showcase
    @StateObject private var shaderPlayer = ShaderPlayerManager()
    
    // Navigation paths for each tab to maintain independent navigation history
    @State private var showcaseNavigationPath = NavigationPath()
    @State private var collectionNavigationPath = NavigationPath()
    @State private var playerNavigationPath = NavigationPath()
    
    init() {
        // Initialize pendingTab to match selectedTab
        _pendingTab = State(initialValue: 0)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Tab content with independent NavigationStacks
            Group {
                switch activeAppTab {
                case .showcase:
                    NavigationStack(path: $showcaseNavigationPath) {
                        // Showcase content with sequential fade and slight blur
                        Group {
                            switch pendingTab {
                            case 0:
                                ForYouShowcase(shaderPlayer: shaderPlayer)
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
                                ForYouShowcase(shaderPlayer: shaderPlayer)
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
                        .background(Color.black)
                    }
                    
                case .collection:
                    NavigationStack(path: $collectionNavigationPath) {
                        Collection()
                            .background(Color.black)
                    }
                    
                case .player:
                    NavigationStack(path: $playerNavigationPath) {
                        Player(activeTab: $activeAppTab)
                            .background(Color.black)
                    }
                }
            }
            
            // Fixed top navbar that stays in place during navigation
            // Only show on showcase tab (where showcases are)
            if activeAppTab == .showcase {
                VStack {
                    TopNavBar(selectedTab: $selectedTab)
                    Spacer()
                }
            }
            
            // Fixed bottom bar that stays in place during navigation
            VStack {
                Spacer()
                BottomBar(activeTab: $activeAppTab)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MainContentView()
            .environmentObject(NowPlayingState())
    }
}
