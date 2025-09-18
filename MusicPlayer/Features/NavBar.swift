import SwiftUI
import VariableBlur

// MARK: - Scroll Position Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geometry.frame(in: .named(coordinateSpace)).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

struct NavBar: View {
    @Environment(\.dismiss) private var dismiss
    
    let showBackButton: Bool
    let showSearchButton: Bool
    let onSearchTap: (() -> Void)?
    let contentName: String?
    let contentImageName: String?
    let scrollOffset: CGFloat
    
    init(
        showBackButton: Bool = true,
        showSearchButton: Bool = true,
        onSearchTap: (() -> Void)? = nil,
        contentName: String? = nil,
        contentImageName: String? = nil,
        scrollOffset: CGFloat = 0
    ) {
        self.showBackButton = showBackButton
        self.showSearchButton = showSearchButton
        self.onSearchTap = onSearchTap
        self.contentName = contentName
        self.contentImageName = contentImageName
        self.scrollOffset = scrollOffset
    }
    
    // MARK: - Computed Properties
    private var contentVisibility: Double {
        // Content appears smoothly when scroll position reaches 360
        return scrollOffset >= 360 ? 1.0 : 0.0
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
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
                        )
                    
                    Text(contentName)
                        .font(.Headline4)
                        .foregroundColor(.fill1)
                        .lineLimit(1)
                }
                .opacity(contentVisibility)
                .animation(.easeInOut(duration: 0.4), value: scrollOffset)
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
                        Gradient.Stop(color: .black.opacity(0), location: 0.00),
                        Gradient.Stop(color: .black.opacity(0.07), location: 0.11),
                        Gradient.Stop(color: .black.opacity(0.13), location: 0.21),
                        Gradient.Stop(color: .black.opacity(0.18), location: 0.28),
                        Gradient.Stop(color: .black.opacity(0.24), location: 0.34),
                        Gradient.Stop(color: .black.opacity(0.29), location: 0.39),
                        Gradient.Stop(color: .black.opacity(0.34), location: 0.44),
                        Gradient.Stop(color: .black.opacity(0.39), location: 0.48),
                        Gradient.Stop(color: .black.opacity(0.44), location: 0.51),
                        Gradient.Stop(color: .black.opacity(0.49), location: 0.55),
                        Gradient.Stop(color: .black.opacity(0.53), location: 0.59),
                        Gradient.Stop(color: .black.opacity(0.58), location: 0.65),
                        Gradient.Stop(color: .black.opacity(0.63), location: 0.71),
                        Gradient.Stop(color: .black.opacity(0.69), location: 0.79),
                        Gradient.Stop(color: .black.opacity(0.74), location: 0.88),
                        Gradient.Stop(color: .black.opacity(0.8), location: 1.00),
                        ],),
                    startPoint: .bottom,
                    endPoint: .top
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
                .background(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                )
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
                .background(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                )
                .clipShape(Circle())
        }
    }
}

// MARK: - View Extension
extension View {
    func trackScrollOffset(in coordinateSpace: String, offset: Binding<CGFloat>) -> some View {
        self.modifier(ScrollOffsetModifier(coordinateSpace: coordinateSpace, offset: offset))
    }
}
