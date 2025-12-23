import SwiftUI

struct Collection: View {
    @EnvironmentObject private var collectionState: CollectionState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                header
                
                ZStack {
                    CollectionCoverCard(
                        coverName: collectionState.previousCover,
                        placeholderTitle: "Тут появится предыдущий лайк",
                        rotation: -12,
                        xOffset: -32,
                        yOffset: 10
                    )
                    
                    CollectionCoverCard(
                        coverName: collectionState.latestCover,
                        placeholderTitle: "Поставьте лайк альбому или плейлисту",
                        rotation: 12,
                        xOffset: 32,
                        yOffset: -6
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: 320)
                
                Spacer()
            }
            .padding(.top, 72)
            .padding(.horizontal, 24)
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Collection")
                .font(.Headline1)
                .foregroundColor(.fill1)
            
            Text(collectionState.hasCovers ? "Последние добавленные" : "Лайкните, чтобы увидеть здесь каверы")
                .font(.Text1)
                .foregroundColor(.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CollectionCoverCard: View {
    let coverName: String?
    let placeholderTitle: String
    let rotation: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    
    var body: some View {
        ZStack {
            if let coverName {
                Image(coverName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipped()
            } else {
                placeholder
            }
        }
        .frame(width: 200, height: 200)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(12)
        .rotationEffect(.degrees(rotation))
        .offset(x: xOffset, y: yOffset)
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 10)
        .animation(.smooth(duration: 0.25), value: coverName)
    }
    
    @ViewBuilder
    private var placeholder: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .center) {
            Text(placeholderTitle)
                .font(.Text2)
                .foregroundColor(.subtitle)
                .multilineTextAlignment(.center)
                .padding(16)
        }
    }
}

#Preview {
    NavigationStack {
        Collection()
            .environmentObject(NowPlayingState())
            .environmentObject(CollectionState())
    }
}

