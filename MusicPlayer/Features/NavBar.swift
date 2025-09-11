import SwiftUI
import VariableBlur

struct NavBar: View {
    @Environment(\.dismiss) private var dismiss
    
    let showBackButton: Bool
    let showSearchButton: Bool
    let onSearchTap: (() -> Void)?
    let contentName: String?
    let contentImageName: String?
    
    init(
        showBackButton: Bool = true,
        showSearchButton: Bool = true,
        onSearchTap: (() -> Void)? = nil,
        contentName: String? = nil,
        contentImageName: String? = nil
    ) {
        self.showBackButton = showBackButton
        self.showSearchButton = showSearchButton
        self.onSearchTap = onSearchTap
        self.contentName = contentName
        self.contentImageName = contentImageName
    }
    
    var body: some View {
        HStack {
            BackButton()
            
            // Left-aligned content with image and title
            if let contentName = contentName, let contentImageName = contentImageName {
                HStack(spacing: 6) {
                    Image(contentImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width:40, height: 40)
                        .cornerRadius(6)
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Text(contentName)
                        .font(.Headline4)
                        .foregroundColor(.fill1)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            SearchButton(onTap: onSearchTap)
        }
        .padding(.horizontal, 12)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .background {
            ZStack {
                VariableBlurView(maxBlurRadius: 16, direction: .blurredTopClearBottom)
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

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.fill1)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct SearchButton: View {
    let onTap: (() -> Void)?
    
    init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.fill1)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
