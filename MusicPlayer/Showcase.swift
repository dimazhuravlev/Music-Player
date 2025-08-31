import SwiftUI

struct Showcase: View {
    @State private var isPlaying = false
    @State private var isCardsPressed = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 32) {
                    PlaylistCarousel(
                        title: "Ramadan Mubarak",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed"),
                            PlaylistCard(imageName: "EveningAzkar"),
                            PlaylistCard(imageName: "MorningAzkar"),
                            PlaylistCard(imageName: "Ruqya")
                        ]
                    )
                    
                    PlaylistCarousel(
                        title: "Faith Journey",
                        playlists: [
                            PlaylistCard(imageName: "Ruqya"),
                            PlaylistCard(imageName: "MorningAzkar"),
                            PlaylistCard(imageName: "EveningAzkar"),
                            PlaylistCard(imageName: "Anasheed")
                        ]
                    )
                    
                    PlaylistCarousel(
                        title: "The Holy Quran",
                        playlists: [
                            PlaylistCard(imageName: "EveningAzkar"),
                            PlaylistCard(imageName: "Anasheed"),
                            PlaylistCard(imageName: "MorningAzkar"),
                            PlaylistCard(imageName: "Ruqya")
                        ]
                    )
                    
                    PlaylistCarousel(
                        title: "Daily Reminders",
                        playlists: [
                            PlaylistCard(imageName: "MorningAzkar"),
                            PlaylistCard(imageName: "EveningAzkar"),
                            PlaylistCard(imageName: "Anasheed"),
                            PlaylistCard(imageName: "Ruqya")
                        ]
                    )
                    
                    PlaylistCarousel(
                        title: "Spiritual Growth",
                        playlists: [
                            PlaylistCard(imageName: "Anasheed"),
                            PlaylistCard(imageName: "Ruqya"),
                            PlaylistCard(imageName: "MorningAzkar"),
                            PlaylistCard(imageName: "EveningAzkar")
                        ]
                    )
                }
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            
            // Fixed bottom bar with mini player
            VStack {
                Spacer()
                
                HStack {
                    miniPlayerWidget
                    Spacer()
                    
                    ZStack {
                        Image("Ruqya")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .rotationEffect(.degrees(isCardsPressed ? -14 : -10))
                            .offset(x: isCardsPressed ? -14 : -10, y: isCardsPressed ? 4 : 4)
                            .animation(.smooth(duration: 0.15), value: isCardsPressed)

                        Image("album")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white, lineWidth: 2)
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
                .padding(.bottom, 24)
                .background(
                    Rectangle()
                        .frame(height: 200)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black.opacity(0.4), location: 0.3),
                                    .init(color: .black.opacity(0.9), location: 0.8),
                                    .init(color: .black, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                )
            }
        }
    }
    

    
    private var miniPlayerWidget: some View {
        HStack(spacing: 16) {
            // Album art
            Image("album")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .cornerRadius(6)
            
            // Animated play/pause icon
            AnimatedIconButton(
                icon1: "play",
                icon2: "pause",
                isActive: isPlaying,
                iconSize: 24
            ) {
                isPlaying.toggle()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 72)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    Showcase()
}
