import SwiftUI

// Card / Panel
public struct BeatlePanel<Content: View>: View {
    @Environment(\.beatle) private var T
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    public var body: some View {
        content()
            .padding(16)
            .background(T.surfaceAlt)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(T.stroke.opacity(0.35), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// Primary button (MPC key feel with accent glow)
public struct BeatleButtonStyle: ButtonStyle {
    @Environment(\.beatle) private var T
    var accent: Color

    public init(accent: Color? = nil) {
        self.accent = accent ?? Color(hex: "#F26249") // coral fallback
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BeatleFont.label)
            .padding(.vertical, 12).padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(T.keycap)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.9), lineWidth: 2))
                    .shadow(color: accent.opacity(configuration.isPressed ? 0.2 : 0.35), radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 1 : 3)
            )
            .foregroundStyle(T.textPrimary)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

public extension ButtonStyle where Self == BeatleButtonStyle {
    static func beatle(accent: Color? = nil) -> BeatleButtonStyle { BeatleButtonStyle(accent: accent) }
}

// Toggle (pad-latch style)
public struct BeatleToggleStyle: ToggleStyle {
    @Environment(\.beatle) private var T
    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label.font(BeatleFont.label).foregroundStyle(T.textPrimary)
            RoundedRectangle(cornerRadius: 8)
                .fill(configuration.isOn ? T.keycapAlt : T.keycap)
                .frame(width: 52, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((configuration.isOn ? T.crimson : T.stroke).opacity(0.9), lineWidth: 2)
                )
                .overlay(
                    Circle().fill(Color.white.opacity(0.9))
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isOn)
                )
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
