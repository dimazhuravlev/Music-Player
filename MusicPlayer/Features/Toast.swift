import SwiftUI

struct ToastConfig: Equatable {
    var title: String
    var iconName: String? = nil
    var coverImageName: String? = nil
    var duration: TimeInterval = 4
    var id = UUID()
}

struct ToastView: View {
    let config: ToastConfig
    let coverRotation: Double
    let coverOffsetY: CGFloat

    var body: some View {
        let leftCompositeWidth: CGFloat = (config.coverImageName?.isEmpty == false) ? (32 + 8) : 0
        let textMaxWidth: CGFloat = 240 - (leftCompositeWidth + 12 + 32 + 16 + 12)
        return HStack(spacing: 8) {
            if let cover = config.coverImageName, !cover.isEmpty {
                // Cover performs a brief tilt-and-drop, values are driven by presenter state
                Image(cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipped()
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
                    .rotationEffect(.degrees(coverRotation))
                    .offset(y: coverOffsetY)
            }
            Text(config.title)
                .font(.Text2)
                .foregroundColor(.fill1)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: textMaxWidth, alignment: .leading)

            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.fill1)
            }
        }
        .padding(.trailing, 12)
        .padding(.leading, 16)
        .padding(.vertical, 12)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            RoundedRectangle(cornerRadius: 80)
                .fill(Color.black.opacity(0.01))
                .background(.ultraThinMaterial)
                .blendMode(.overlay)
                .cornerRadius(72)
                .overlay(
                    RoundedRectangle(cornerRadius: 80)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                )
        )
        .compositingGroup()
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var isPresented: Bool = false
    @Published var currentConfig: ToastConfig = ToastConfig(title: "")
    private init() {}
    func show(title: String, cover: String? = nil, duration: TimeInterval = 4) {
        currentConfig = ToastConfig(title: title, iconName: nil, coverImageName: cover, duration: duration)
        isPresented = true
    }
}

private struct ToastPresenter: ViewModifier {
    @Binding var isPresented: Bool
    var config: ToastConfig
    var onTap: (() -> Void)?

    @State private var yOffset: CGFloat = -100
    @State private var opacity: Double = 0
    // Resting offset that visually aligns the toast with the top nav bar
    private let targetYOffset: CGFloat = -16
    // Cover starts slightly tilted and lifted, then settles in on show()
    @State private var coverRotation: Double = -10
    @State private var coverOffsetY: CGFloat = -30
    @State private var timerToken: Int = 0
    @State private var blurRadius: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                ToastView(config: config, coverRotation: coverRotation, coverOffsetY: coverOffsetY)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: yOffset)
                    .opacity(opacity)
                    .blur(radius: blurRadius)
                    .onTapGesture {
                        onTap?()
                        dismiss()
                    }
                    .onAppear { show() }
                    .onChange(of: config) { _, _ in show() }
            }
        }
    }

    private func show() {
        // Reset cover pose instantly (no animation) so next entrance always starts from the same state
        withAnimation(.none) {
            coverRotation = -12
            coverOffsetY = -30
            // Ensure starting off-screen for each show
            yOffset = -100
        }
        // Standard springs for entrance/exit
        let springIn = Animation.spring(response: 0.5, dampingFraction: 0.87)

        // Enter: make toast visible instantly, animate only the slide-down
        opacity = 1
        blurRadius = 0
        withAnimation(springIn) {
            yOffset = targetYOffset
        }
        // Stagger: begin the cover tilt-and-drop shortly after the container starts
        withAnimation(springIn.delay(0.15)) {
            coverRotation = 6
            coverOffsetY = 0
        }
        // Schedule dismissal tied to a token to avoid stale timers
        timerToken += 1
        let token = timerToken
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
            if token == timerToken {
                dismiss()
            }
        }
    }

    private func dismiss() {
        // Exit: fade and blur, without vertical movement
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 0
            blurRadius = 16
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            isPresented = false
            // Prepare for next show without animating the cover reset
            coverRotation = -10
            coverOffsetY = -30
            blurRadius = 0
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>,
               config: ToastConfig,
               onTap: (() -> Void)? = nil) -> some View {
        modifier(ToastPresenter(isPresented: isPresented, config: config, onTap: onTap))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
        }
    }
    .toast(
        isPresented: .constant(true),
        config: ToastConfig(title: "Done! Your playlist’s in Collection", duration: 3.0)
    )
}


