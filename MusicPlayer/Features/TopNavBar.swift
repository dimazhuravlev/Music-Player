import SwiftUI
import VariableBlur
#if canImport(UIKit)
import UIKit
#endif

struct TopNavBar: View {
    @EnvironmentObject private var offlineModeState: OfflineModeState
    @EnvironmentObject private var debugPanelState: DebugPanelState
    @Binding var selectedTab: Int
    @State private var pressedTabIndex: Int? = nil
    @State private var previousSelectedTab: Int = 0
    @State private var showWizard = false
    /// Витрина Offline: визуальное состояние тоггла (модель `isEnabled` сбрасывается позже в анимации выхода).
    @State private var offlineHeaderToggleOn = true
    
    let tabs: [String]
    /// Витрина Offline: выключение офлайн-режима (обратная вспышка → Коллекция / Downloads).
    let onRequestDisableOffline: (() -> Void)?
    /// Идёт обратная вспышка выхода из офлайна — чтобы вернуть тоггл, если переход прервали.
    let isOfflineExitFlashActive: Bool
    /// `false` — не рендерить встроенный градиент+blur фон (когда снаружи нужно вставить слой между фоном и контентом, например, OfflineHeaderGlow).
    let showsBackground: Bool

    init(
        selectedTab: Binding<Int>,
        tabs: [String] = ["For You", "Trends", "Spiritual"],
        onRequestDisableOffline: (() -> Void)? = nil,
        isOfflineExitFlashActive: Bool = false,
        showsBackground: Bool = true
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.onRequestDisableOffline = onRequestDisableOffline
        self.isOfflineExitFlashActive = isOfflineExitFlashActive
        self.showsBackground = showsBackground
    }
    
    var body: some View {
        HStack {
            if tabs.count == 1 {
                HStack(alignment: .center, spacing: 14) {
                    Text(tabs[0])
                        .font(.Headline3)
                        .foregroundColor(.fill1)
                    if let disableOffline = onRequestDisableOffline {
                        OfflineToggle(
                            isOn: Binding(
                                get: { offlineHeaderToggleOn },
                                set: { on in
                                    guard !on else { return }
                                    offlineHeaderToggleOn = false
                                    disableOffline()
                                }
                            ),
                            isEnabled: !isOfflineExitFlashActive
                        )
                    }
                }
            } else {
                HStack(spacing: 10) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        Text(tab)
                            .font(.Headline3)
                            .foregroundColor(selectedTab == index ? .fill1 : .white.opacity(0.35))
                            .animation(.smooth(duration: 0.4), value: selectedTab)
                            .scaleEffect(pressedTabIndex == index ? 0.9 : 1.0)
                            .animation(.smooth(duration: 0.1), value: pressedTabIndex)
                            .onTapGesture {
                                selectedTab = index
                                if index != previousSelectedTab {
                                    triggerTopTabHaptic()
                                }
                                previousSelectedTab = index
                            }
                            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                                pressedTabIndex = pressing ? index : nil
                            }, perform: {})
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if pressedTabIndex == nil {
                                            pressedTabIndex = index
                                        }
                                    }
                                    .onEnded { _ in
                                        pressedTabIndex = nil
                                    }
                            )
                    }
                }
                .overlay(alignment: .topLeading) {
                    GeometryReader { geometry in
                        let tabWidth = (geometry.size.width - CGFloat(tabs.count - 1) * 10) / CGFloat(tabs.count)
                        let pinX = CGFloat(selectedTab) * (tabWidth + 5) + tabWidth / 2
                        
                        Circle()
                            .fill(Color.fill1)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 0)
                            .position(x: pinX, y: 48)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0), value: selectedTab)
                    }
                    .frame(height: 40)
                }
            }
            
            Spacer()
            
            // User profile picture
            Button(action: {
                showWizard = true
            }) {
                Image("userpic")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.66)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .fullScreenCover(isPresented: $showWizard) {
            Wizard()
                .environmentObject(debugPanelState)
        }
        .background {
            if showsBackground {
                TopNavBarBackground()
            }
        }
        .onAppear {
            if onRequestDisableOffline != nil {
                offlineHeaderToggleOn = offlineModeState.isEnabled
            }
        }
        .onChange(of: offlineModeState.isEnabled) { _, enabled in
            guard onRequestDisableOffline != nil else { return }
            offlineHeaderToggleOn = enabled
        }
        .onChange(of: isOfflineExitFlashActive) { _, active in
            guard onRequestDisableOffline != nil else { return }
            if !active && offlineModeState.isEnabled {
                offlineHeaderToggleOn = true
            }
        }
    }

    private func triggerTopTabHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}


/// Тёмный градиент + два VariableBlurView сверху. Вынесено отдельно, чтобы можно было вставить слой между фоном и контентом TopNavBar (OfflineHeaderGlow).
/// Самопозиционирующийся: верх контента анкорится к физическому верху экрана (через VStack + Spacer + `.ignoresSafeArea(edges: .top)`).
struct TopNavBarBackground: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(
                        stops: [
                            Gradient.Stop(color: .black.opacity(0.75), location: 0.00),
                            Gradient.Stop(color: .black.opacity(0.72), location: 0.11),
                            Gradient.Stop(color: .black.opacity(0.69), location: 0.21),
                            Gradient.Stop(color: .black.opacity(0.65), location: 0.28),
                            Gradient.Stop(color: .black.opacity(0.61), location: 0.34),
                            Gradient.Stop(color: .black.opacity(0.56), location: 0.40),
                            Gradient.Stop(color: .black.opacity(0.52), location: 0.44),
                            Gradient.Stop(color: .black.opacity(0.46), location: 0.48),
                            Gradient.Stop(color: .black.opacity(0.41), location: 0.52),
                            Gradient.Stop(color: .black.opacity(0.35), location: 0.56),
                            Gradient.Stop(color: .black.opacity(0.3), location: 0.60),
                            Gradient.Stop(color: .black.opacity(0.24), location: 0.66),
                            Gradient.Stop(color: .black.opacity(0.18), location: 0.72),
                            Gradient.Stop(color: .black.opacity(0.12), location: 0.79),
                            Gradient.Stop(color: .black.opacity(0.05), location: 0.89),
                            Gradient.Stop(color: .black.opacity(0), location: 1.00),
                        ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)

                VariableBlurView(maxBlurRadius: 4, direction: .blurredTopClearBottom)
                    .frame(height: 140)

                VariableBlurView(maxBlurRadius: 14, direction: .blurredTopClearBottom)
                    .frame(height: 100)
            }
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}


#Preview {
    ZStack {
        TopNavBar(selectedTab: .constant(0))
            .environmentObject(OfflineModeState())
            .environmentObject(DebugPanelState())
    }
}
