import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Скелетон экрана альбома (Figma: Sandbox Mobile — screen skeleton).
/// Плейсхолдеры: белый 10%.
struct AlbumSkeletonScreen: View {
    @State private var scrollOffset: CGFloat = 0
    @EnvironmentObject private var showcaseNavState: ShowcaseNavState
    @EnvironmentObject private var offlineModeState: OfflineModeState

    private var heroSide: CGFloat {
        #if canImport(UIKit)
        UIScreen.main.bounds.width
        #else
        390
        #endif
    }

    /// Горизонтальные поля как раньше; между ними — квадратная обложка.
    private var coverHorizontalInset: CGFloat { heroSide * 0.1707 }
    private var coverSquareSide: CGFloat { heroSide - 2 * coverHorizontalInset }

    private let skeletonFill = Color.white.opacity(0.1)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 1)
                        .trackScrollOffset(in: "scroll", offset: $scrollOffset)

                    heroSection
                        .padding(.top, 120)

                    headerBlock

                    trackListBlock

                    Spacer(minLength: 120)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(.container, edges: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(!offlineModeState.isSkeletonOfflineSheetPresented)
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard !offlineModeState.isSkeletonOfflineSheetPresented else { return }
                    withAnimation(.smooth(duration: 0.65)) {
                        offlineModeState.isSkeletonOfflineSheetPresented = true
                    }
                }
            )

            VStack {
                NavBar(
                    showBackButton: true,
                    showSearchButton: true,
                    onSearchTap: {},
                    contentName: nil,
                    contentImageName: nil,
                    scrollOffset: scrollOffset
                )
                Spacer()
            }
        }
#if os(iOS)
        .navigationBarHidden(true)
#endif
        .onAppear { showcaseNavState.isShowingDetail = true }
        .onDisappear {
            showcaseNavState.isShowingDetail = false
            offlineModeState.isSkeletonOfflineSheetPresented = false
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(skeletonFill)
            .frame(width: coverSquareSide, height: coverSquareSide)
            .frame(maxWidth: .infinity)
            .padding(.bottom, heroSide * 0.0933)
    }

    // MARK: - Title, artist, controls, divider

    private var headerBlock: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                skeletonBar(width: 203, height: 40, cornerRadius: 0)

                HStack(spacing: 8) {
                    Circle()
                        .fill(skeletonFill)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 6) {
                        skeletonBar(width: 112, height: 12, cornerRadius: 0)
                        skeletonBar(width: 77, height: 12, cornerRadius: 0)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                skeletonBar(width: 107, height: 40, cornerRadius: 48)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Circle()
                        .fill(skeletonFill)
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(skeletonFill)
                        .frame(width: 40, height: 40)
                }
            }

            Rectangle()
                .fill(skeletonFill)
                .frame(height: 0.5)
                .padding(.horizontal, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    // MARK: - Track list

    private var trackListBlock: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { _ in
                trackRowSkeleton
            }
        }
    }

    private var trackRowSkeleton: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(skeletonFill)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                skeletonBar(width: 180, height: 14, cornerRadius: 0)
                skeletonBar(width: 98, height: 14, cornerRadius: 0)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func skeletonBar(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(skeletonFill)
            .frame(width: width, height: height)
    }
}

#Preview {
    NavigationStack {
        AlbumSkeletonScreen()
            .environmentObject(ShowcaseNavState())
            .environmentObject(OfflineModeState())
    }
}
