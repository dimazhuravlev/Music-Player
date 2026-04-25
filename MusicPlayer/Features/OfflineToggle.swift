import SwiftUI

struct OfflineToggle: View {
    @Binding var isOn: Bool
    var isEnabled: Bool = true
    var onToggle: ((Bool) -> Void)? = nil

    private let trackWidth: CGFloat = 42
    private let trackHeight: CGFloat = 26
    private let thumbSize: CGFloat = 16
    private let inset: CGFloat = 5

    private var onGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0xA3 / 255.0, green: 0x32 / 255.0, blue: 0xFF / 255.0), location: 0.4),
                .init(color: Color(red: 0xD6 / 255.0, green: 0x33 / 255.0, blue: 0xFF / 255.0), location: 1.0)
            ],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: 1.064, y: 0.749)
        )
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                        .fill(onGradient)
                        .opacity(isOn ? 1 : 0)
                }
                .frame(width: trackWidth, height: trackHeight)

            Circle()
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 2)
                .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
                .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 2.348)
                .offset(x: isOn ? (trackWidth - thumbSize - inset) : inset)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isEnabled else { return }
            let next = !isOn
            isOn = next
            onToggle?(next)
        }
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn)
    }
}

#Preview {
    VStack(spacing: 20) {
        OfflineToggle(isOn: .constant(true))
        OfflineToggle(isOn: .constant(false))
    }
    .padding()
    .background(Color.black)
}
