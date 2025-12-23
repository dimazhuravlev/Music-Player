import SwiftUI

struct ToastConfig: Equatable {
    var title: String
    var coverImageName: String? = nil
    var duration: TimeInterval = 4
    var id = UUID()
}

struct ToastView: View {
    let config: ToastConfig
    let coverRotation: Double
    let coverOffsetY: CGFloat

    var body: some View {
        HStack(spacing: 8) {

            // Artist/album/playlist cover
            if let cover = config.coverImageName, !cover.isEmpty {
                Image(cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipped()
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
                    )
                    .rotationEffect(.degrees(coverRotation))
                    .offset(y: coverOffsetY)
            }

            // Title
            Text(config.title)
                .font(.Text2)
                .foregroundColor(.fill1)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .layoutPriority(1)

            Spacer(minLength: 12)

            // Button placeholder
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.fill1)
            }
        }
        .padding(.trailing, 12)
        .padding(.leading, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 280)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            RoundedRectangle(cornerRadius: 80)
                .fill(Color.black.opacity(0.01))   // tiny tint to help blendMode work
                .background(.ultraThinMaterial)    // iOS glass
                .blendMode(.overlay)
                .cornerRadius(80)
                .overlay(
                    RoundedRectangle(cornerRadius: 80)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.66)
                )
        )
        // isolate blendMode so it doesn't mess the whole parent view
        .compositingGroup()
    }
}


class ToastManager: ObservableObject {

    static let shared = ToastManager()

    @Published var isPresented: Bool = false
    @Published var currentConfig: ToastConfig = ToastConfig(title: "")

    private init() {}

    /// Call this to show a toast
    func show(title: String, cover: String? = nil, duration: TimeInterval = 4) {
        currentConfig = ToastConfig(
            title: title,
            coverImageName: cover,
            duration: duration
        )
        isPresented = true
    }
}


/// ViewModifier that mounts the toast above the content,
/// animates it in/out, auto-dismisses on a timer, and handles tap.
private struct ToastPresenter: ViewModifier {

    @Binding var isPresented: Bool
    var config: ToastConfig
    var onTap: (() -> Void)?

    // Vertical position of the whole toast container
    @State private var yOffset: CGFloat = -100
    // Opacity of the whole toast container
    @State private var opacity: Double = 0
    // Small blur for dismiss animation
    @State private var blurRadius: CGFloat = 0

    // Target resting offset (relative to safe area top / nav bar).
    private let targetYOffset: CGFloat = -16

    // The cover does a tiny tilt+drop entrance.
    // These are animated separately from the main slide-down.
    @State private var coverRotation: Double = -10
    @State private var coverOffsetY: CGFloat = -30

    // We use a token to ensure that only the latest scheduled timer can dismiss.
    // If a new toast shows before the old one auto-dismisses, the old timer won't kill the new toast.
    @State private var timerToken: Int = 0

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                ToastView(
                    config: config,
                    coverRotation: coverRotation,
                    coverOffsetY: coverOffsetY
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )
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

    // Show / Dismiss logic

    private func show() {
        // Prepare starting state for the entrance animation.
        withAnimation(.none) {
            coverRotation = -12     // tilt backward
            coverOffsetY = -30      // lifted up
            yOffset = -100          // toast off-screen above
        }

        let springIn = Animation.spring(response: 0.5, dampingFraction: 0.75)

        // Make toast visible immediately (opacity 1, no blur),
        opacity = 1
        blurRadius = 0
        withAnimation(springIn) {
            yOffset = targetYOffset
        }

        // Slight delay for the cover "bounce"
        withAnimation(springIn.delay(0.15)) {
            coverRotation = 6      // tilt forward
            coverOffsetY = 0       // drop into place
        }

        // Auto-dismiss after config.duration.
        timerToken += 1
        let token = timerToken

        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
            if token == timerToken {
                dismiss()
            }
        }
    }

    private func dismiss() {
        // Fade out + blur the whole toast.
        withAnimation(.linear(duration: 0.5)) {
            opacity = 0
            blurRadius = 16
        }

        // After fade completes, actually unmount the toast from the view tree
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            isPresented = false
            coverRotation = -10
            coverOffsetY = -30
            blurRadius = 0
        }
    }
}


extension View {
    func toast(
        isPresented: Binding<Bool>,
        config: ToastConfig,
        onTap: (() -> Void)? = nil
    ) -> some View {
        modifier(
            ToastPresenter(
                isPresented: isPresented,
                config: config,
                onTap: onTap
            )
        )
    }
}


#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack { Spacer() }
    }
    .toast(
        isPresented: .constant(true),
        config: ToastConfig(
            title: "Done! Your playlist’s in Collection",
            duration: 3.0
        )
    )
}

