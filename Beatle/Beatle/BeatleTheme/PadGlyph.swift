import SwiftUI

public struct PadGlyph: View {
    @Environment(\.beatle) private var T
    var size: CGFloat = 20
    public init(size: CGFloat = 20) { self.size = size }

    public var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(LinearGradient(colors: [T.keycap, T.keycap.lighter(0.03)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(T.stroke.opacity(0.45), lineWidth: 1))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
