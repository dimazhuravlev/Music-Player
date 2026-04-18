import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Оффлайн bottom sheet (Figma: `offline bottom sheet`, node 18179:92767).
/// Три размытых пятна: accent (base), #a700ba, белое 70%.
struct OfflineBottomSheet: View {
    var isPresented: Bool
    var onGoOffline: () -> Void
    var onDragChanged: (CGFloat) -> Void = { _ in }
    var onDragEnded: (CGFloat) -> Void = { _ in }

    @State private var blobEntrance: CGFloat = 0

    /// Высота «хвоста» под нижним краем: при оттягивании вверх видно продолжение градиента/блобов, а не чёрную щель.
    static let bottomContinuationHeight: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            sheetCardContent
                .frame(width: geo.size.width, height: geo.size.height)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24,
                        style: .continuous
                    )
                )
                .overlay(alignment: .bottom) {
                    sheetBottomContinuation(width: geo.size.width)
                        .frame(height: Self.bottomContinuationHeight)
                        .offset(y: Self.bottomContinuationHeight)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
        }
        .onChange(of: isPresented) { _, shown in
            if shown {
                blobEntrance = 0
                withAnimation(.smooth(duration: 0.9)) {
                    blobEntrance = 1
                }
            } else {
                blobEntrance = 0
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let t = value.translation.height
                    guard t <= 0 else { return }
                    onDragChanged(t)
                }
                .onEnded { value in
                    onDragEnded(value.translation.height)
                }
        )
    }

    private var sheetCardContent: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.12), location: 0),
                    .init(color: Color.black.opacity(0.38), location: 0.22),
                    .init(color: Color(red: 0.12, green: 0.02, blue: 0.18).opacity(0.72), location: 0.48),
                    .init(color: Color.accent.opacity(0.78), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GeometryReader { geo in
                offlineSheetBlobs(width: geo.size.width, height: geo.size.height)
                    .opacity(Double(blobEntrance))
                    .scaleEffect(0.92 + 0.08 * blobEntrance)
            }

            VStack(spacing: 24) {
                Text("Internet seems\nto be dead")
                    .font(.Headline3)
                    .foregroundStyle(Color.fill1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 270)

                VStack(spacing: 12) {
                    Button(action: onGoOffline) {
                        Text("Go Offline")
                            .font(.Text1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Text("or swipe up to switch")
                        .font(.Text1)
                        .foregroundStyle(Color.subtitle)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 270)
                }
            }
            .padding(.horizontal, 52)
            .padding(.bottom, 64)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func sheetBottomContinuation(width: CGFloat) -> some View {
        ZStack {
            // Без тёмного/black внизу — иначе поверх блобов читается как полупрозрачная пелена (и может смешиваться со скримом).
            LinearGradient(
                stops: [
                    .init(color: Color.accent.opacity(0.78), location: 0),
                    .init(color: Color(red: 0.12, green: 0.02, blue: 0.18).opacity(0.72), location: 0.38),
                    .init(color: Color.accent.opacity(0.62), location: 0.72),
                    .init(color: Color(red: 0.18, green: 0.04, blue: 0.22).opacity(0.88), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Ellipse()
                .fill(Color.accent.opacity(0.45))
                .frame(width: min(560, width * 1.35), height: 160)
                .blur(radius: 64)
                .offset(y: -56)
            Ellipse()
                .fill(Color(red: 167 / 255, green: 0, blue: 186 / 255).opacity(0.38))
                .frame(width: 260, height: 250)
                .blur(radius: 72)
                .offset(x: -width * 0.18, y: -40)
            Ellipse()
                .fill(Color.white.opacity(0.22))
                .frame(width: 200, height: 190)
                .blur(radius: 58)
                .offset(x: width * 0.22, y: -24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Figma: base 700×694 blur 98; dark #a700ba 242×240; white 70% 232×230.
    private func offlineSheetBlobs(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPresented)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let w = width
            let h = height

            let dx0 = sin(t * 0.42) * 14 + cos(t * 0.27) * 6
            let dy0 = cos(t * 0.38) * 10 + sin(t * 0.33) * 5
            let dx1 = sin(t * 0.55 + 1.2) * 12 + cos(t * 0.41) * 7
            let dy1 = cos(t * 0.47 + 0.8) * 11 + sin(t * 0.36) * 6
            let dx2 = sin(t * 0.35 + 2.1) * 10 + cos(t * 0.51) * 8
            let dy2 = cos(t * 0.44 + 1.5) * 9 + sin(t * 0.29) * 5

            let baseW = min(700, w * 1.87)
            let baseH = min(480, h * 0.62)

            ZStack {
                Ellipse()
                    .fill(Color.accent)
                    .frame(width: baseW, height: baseH)
                    .blur(radius: 98)
                    .offset(x: dx0, y: h * 0.44 + dy0)

                Ellipse()
                    .fill(Color(red: 167 / 255, green: 0, blue: 186 / 255))
                    .frame(width: 242, height: 240)
                    .blur(radius: 98)
                    .offset(x: -w * 0.22 + dx1, y: h * 0.32 + dy1)

                Ellipse()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 232, height: 230)
                    .blur(radius: 98)
                    .offset(x: w * 0.24 + dx2, y: h * 0.26 + dy2)
            }
            .frame(width: w, height: h, alignment: .center)
        }
    }
}

#Preview {
    #if canImport(UIKit)
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            OfflineBottomSheet(isPresented: true, onGoOffline: {}, onDragChanged: { _ in }, onDragEnded: { _ in })
                .frame(height: UIScreen.main.bounds.height * 0.9)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    #else
    Color.black
    #endif
}
