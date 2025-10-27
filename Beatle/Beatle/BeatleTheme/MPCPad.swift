import SwiftUI

public struct MPCPad: View {
    @Environment(\.beatle) private var T
    var size: CGFloat = 140
    var corner: CGFloat = 16
    var accent: Color
    var isActive: Bool = true
    var action: (() -> Void)? = nil
    var releaseAction: (() -> Void)? = nil // For gate mode

    // visual tuning
    private var lift: CGFloat { max(4, size * 0.02) }
    private var glowBlur: CGFloat { max(16, size * 0.18) }
    private var glowSpread: CGFloat { max(6, size * 0.06) }
    private var glowOffsetY: CGFloat { max(4, size * 0.08) }

    @State private var pressing = false
    @State private var tapped = false

    public init(size: CGFloat = 140, accent: Color? = nil, isActive: Bool = true, action: (() -> Void)? = nil, releaseAction: (() -> Void)? = nil) {
        self.size = size
        self.accent = accent ?? Color(hex: "#52B3B6")
        self.isActive = isActive
        self.action = action
        self.releaseAction = releaseAction
    }

    public var body: some View {
        let isPressed = pressing || tapped
        let activeOpacity: Double = isActive ? (isPressed ? 0.9 : 0.55) : 0.0

        ZStack {
            // UNDER-PAD GLOW
            RoundedRectangle(cornerRadius: corner + 6)
                .fill(accent)
                .frame(width: size + glowSpread, height: size + glowSpread)
                .blur(radius: glowBlur)
                .opacity(activeOpacity)
                .offset(y: glowOffsetY)
                .blendMode(.screen)
                .allowsHitTesting(false)

            // PAD BODY
            RoundedRectangle(cornerRadius: corner)
                .fill(
                    LinearGradient(
                        colors: [ T.keycap.darker(0.06), T.keycap, T.keycap.lighter(0.03) ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(T.stroke.opacity(0.35), lineWidth: 1.2)
                        .blendMode(.multiply)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(.black.opacity(0.25), lineWidth: 8)
                        .blur(radius: 6)
                        .mask(
                            RoundedRectangle(cornerRadius: corner)
                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                )
                .overlay(NoiseOverlay(opacity: 0.06, scale: 0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: corner))
                .shadow(color: .black.opacity(0.25), radius: isPressed ? 6 : 10, y: lift)
                .scaleEffect(isPressed ? 0.985 : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isPressed)
                .drawingGroup(opaque: false)
        }
        .frame(width: size, height: size)
        .contentShape(RoundedRectangle(cornerRadius: corner))
        // Trigger audio on press for low latency - allow rapid triggering
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressing {
                        pressing = true
                        print("🎯 MPCPad.onPress: Pad pressed!")
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        
                        print("🎯 MPCPad.onPress: Calling action...")
                        action?()
                        print("🎯 MPCPad.onPress: Action called")
                    }
                }
                .onEnded { _ in
                    pressing = false
                    print("🎯 MPCPad.onEnded: Pad released!")
                    releaseAction?()
                }
        )
        // Visual tap feedback for release
        .onTapGesture {
            print("🎯 MPCPad.onTapGesture: Pad tapped!")
            tapped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { tapped = false }
        }
        .accessibilityLabel("Drum pad")
        .accessibilityAddTraits(.isButton)
    }
}

