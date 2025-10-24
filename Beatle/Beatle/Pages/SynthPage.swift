import SwiftUI

struct SynthPage: View {
    @Environment(\.beatle) private var T
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform.circle")
                .font(.system(size: 64))
                .symbolRenderingMode(.palette)
                .foregroundStyle(T.teal, T.keycap)
            Text("Synth (coming soon)")
                .font(BeatleFont.title)
                .foregroundStyle(.secondary)
            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
    }
}
