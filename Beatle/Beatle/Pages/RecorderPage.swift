import SwiftUI

struct RecorderPage: View {
    @Environment(\.beatle) private var T
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "record.circle.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.palette)
                .foregroundStyle(T.crimson, T.keycap)
            Text("Tape Recorder (coming soon)")
                .font(BeatleFont.title)
                .foregroundStyle(.secondary)
            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 24)
    }
}
