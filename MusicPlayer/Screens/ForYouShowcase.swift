import SwiftUI
import UIKit

struct ForYouShowcase: View {
    @State private var selectedPlaylist: String?
    @State private var navigateToPlayer = false
    @State private var refreshOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var refreshBlurRadius: CGFloat = 0
    @State private var maxPullDistanceReached: CGFloat = 0
    @State private var displayedTracks: [Track] = []
    @State private var isDragging = false
    @ObservedObject var shaderPlayer: ShaderPlayerManager
    
    // Haptic feedback manager
    @StateObject private var hapticManager = PullToRefreshHapticManager()
    
    private let maxPullDistance: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Generator(
                        shaderPlayer: shaderPlayer,
                        tracks: displayedTracks,
                        refreshOffset: refreshOffset,
                        blurRadius: isRefreshing ? refreshBlurRadius : min(refreshOffset / 4, 20),
                        hasTriggeredFinalHaptic: hapticManager.hasTriggeredFinalHaptic,
                        isRefreshing: isRefreshing,
                        refreshBlurRadius: refreshBlurRadius
                    )
                    
                    PlaylistCarousel(
                        title: "Best Releases for You",
                        playlists: [
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Artists You Like",
                        playlists: [
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Daily Reminders",
                        playlists: [
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {}),
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                    
                    PlaylistCarousel(
                        title: "Spiritual Growth",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed", onTap: {}),
                            PlaylistCard(imageName: "Ruqya", onTap: {}),
                            PlaylistCard(imageName: "MorningAzkar", onTap: {}),
                            PlaylistCard(imageName: "EveningAzkar", onTap: {})
                        ],
                        onPlaylistTap: { playlistName in
                            selectedPlaylist = playlistName
                            navigateToPlayer = true
                        }
                    )
                }
                .padding(.bottom, 120)
            }
            .background(Color.black)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            isDragging = true
                            
                            // Reset refreshing state if user starts pulling again
                            if isRefreshing {
                                isRefreshing = false
                                refreshBlurRadius = 0
                            }
                            
                            let pullDistance = value.translation.height
                            
                            // Track maximum pull distance reached
                            maxPullDistanceReached = max(maxPullDistanceReached, pullDistance)
                            
                            // Reduce animation complexity for better performance
                            refreshOffset = min(pullDistance * 0.3, 80)
                            
                            // Handle haptic feedback based on pull distance
                            hapticManager.handlePullDistance(pullDistance)
                        }
                    }
                    .onEnded { value in
                        // Stop haptic feedback when gesture ends
                        hapticManager.reset()
                        isDragging = false
                        
                        // Check if user reached the threshold (160px) to trigger refresh
                        if maxPullDistanceReached >= hapticManager.hapticStopDistance {
                            // User pulled enough - start refresh sequence
                            isRefreshing = true
                            
                            // Set fixed blur value for refresh period
                            refreshBlurRadius = 32
                            
                            // Keep refreshOffset at max value during refresh
                            withAnimation(.easeOut(duration: 0.1)) {
                                refreshOffset = 40
                            }
                            
                            // Start refresh content
                            Task {
                                await refreshContent()
                            }
                            
                            // After 3 seconds, smoothly hide status and remove blur
                            Task {
                                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                                
                                await MainActor.run {
                                    // Shuffle tracks for new order
                                    let allTracks = TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 }
                                    displayedTracks = allTracks.shuffled()
                                    
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        refreshOffset = 0
                                        refreshBlurRadius = 0
                                        isRefreshing = false
                                    }
                                }
                            }
                        } else {
                            // If not enough pull, just reset immediately
                            withAnimation(.easeOut(duration: 0.3)) {
                                refreshOffset = 0
                            }
                        }
                        
                        // Reset max pull distance for next gesture
                        maxPullDistanceReached = 0
                    }
            )
            .refreshable {
                await refreshContent()
            }
            .onAppear {
                hideRefreshControl()
            }
            .onChange(of: refreshOffset) { _ in
                // Hide refresh control whenever refresh offset changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hideRefreshControl()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            Playlist(playlistName: selectedPlaylist)
        }
        .onAppear {
            // Initialize tracks on first appearance
            if displayedTracks.isEmpty {
                let allTracks = TrackDataManager.shared.getSampleTracks().prefix(9).map { $0 }
                displayedTracks = allTracks.shuffled()
            }
        }
    }
    
    private func refreshContent() async {
        isRefreshing = true
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isRefreshing = false
    }
    
    private func hideRefreshControl() {
        DispatchQueue.main.async {
            // Find UIScrollView in the view hierarchy and hide its refreshControl
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findAndHideRefreshControl(in: window)
            }
        }
    }
    
    private func findAndHideRefreshControl(in view: UIView) {
        if let scrollView = view as? UIScrollView {
            // Hide refresh control completely
            if let refreshControl = scrollView.refreshControl {
                refreshControl.tintColor = .clear
                refreshControl.backgroundColor = .clear
                refreshControl.alpha = 0
                // Hide all subviews
                refreshControl.subviews.forEach { $0.isHidden = true }
            }
        }
        
        for subview in view.subviews {
            findAndHideRefreshControl(in: subview)
        }
    }
    
}

#Preview {
    ForYouShowcase(shaderPlayer: ShaderPlayerManager())
}
