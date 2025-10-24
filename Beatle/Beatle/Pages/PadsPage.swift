import SwiftUI

struct PadsPage: View {
    @Environment(\.beatle) private var T
    @EnvironmentObject private var store: PadStore
    @State private var isEditing = false

    private let horizontalPadding: CGFloat = 24
    private let interColumn: CGFloat = 16
    private let interRow: CGFloat = 18
    private let topSpacing: CGFloat = 12
    private let bottomSpacing: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - (horizontalPadding * 2) - interColumn
            let padSize = max(88, floor(availableWidth / 2.5))
            let columns = [
                GridItem(.fixed(padSize), spacing: interColumn),
                GridItem(.fixed(padSize), spacing: 0)
            ]

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(isEditing ? "Done" : "Edit") {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation { isEditing.toggle() }
                    }
                    .buttonStyle(.beatle(accent: T.keycap))
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)

                Spacer(minLength: topSpacing)

                LazyVGrid(columns: columns, alignment: .center, spacing: interRow) {
                    ForEach(store.pads) { pad in
                        MPCPadCard(pad: pad, size: padSize, isEditing: isEditing)
                            .environmentObject(store)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)

                Spacer(minLength: bottomSpacing)
            }
        }
    }
}
