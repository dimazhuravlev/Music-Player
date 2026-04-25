import SwiftUI

/// Контент для нативной `.sheet` с дебаг-настройками.
struct DebugMenuSheetContent: View {
    /// Включено — классический `BottomBar` + `MiniPlayer`; выключено — `BottomBarV2` + `MiniPlayerV2`.
    @Binding var useLegacyBottomBar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $useLegacyBottomBar) {
                Text("Новая навигация")
                    .font(.Text1)
                    .foregroundStyle(Color.fill1)
            }
            .tint(Color.accent)
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .preferredColorScheme(.dark)
    }
}
