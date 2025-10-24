import SwiftUI

public struct BeatleTabBar: View {
    @Environment(\.beatle) private var T
    @Binding var tab: BeatleTab

    public init(tab: Binding<BeatleTab>) { self._tab = tab }

    public var body: some View {
        let bg = BeatleShade.navBarBackground(surface: T.surface)
        let divider = T.stroke.opacity(0.55) // stronger on dark

        HStack(spacing: 0) {
            segment(.record) { Image(systemName: "record.circle") }
            DividerView(color: divider)
            segment(.pads)   { PadGlyph(size: 20) }
            DividerView(color: divider)
            segment(.synth)  { Image(systemName: "waveform") }
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            ZStack(alignment: .top) {
                bg.ignoresSafeArea(edges: .bottom) // flush to phone curve
                Rectangle().fill(divider).frame(height: 0.66).opacity(0.9) // top hairline
            }
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func segment<V: View>(_ value: BeatleTab, @ViewBuilder icon: () -> V) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { tab = value }
        } label: {
            VStack(spacing: 6) {
                icon()
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(value == tab ? T.textPrimary : T.textSecondary)
                RoundedRectangle(cornerRadius: 2)
                    .fill(value == tab ? T.textPrimary.opacity(0.85) : .clear)
                    .frame(width: 14, height: 3)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(value == tab ? T.textPrimary.opacity(0.08) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(value == tab ? T.textPrimary.opacity(0.16) : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DividerView: View {
    let color: Color
    var body: some View { Rectangle().fill(color).frame(width: 1, height: 28) }
}
