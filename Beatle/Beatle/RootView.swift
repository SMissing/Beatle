import SwiftUI

public enum BeatleTab { case record, pads, synth }

struct RootView: View {
    @Environment(\.beatle) private var T
    @State private var tab: BeatleTab = .pads
    @StateObject private var padStore = PadStore() // ⬅️ now owned here

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch tab {
            case .record: RecorderPage().environmentObject(padStore)
            case .pads:   PadsPage().environmentObject(padStore)
            case .synth:  SynthPage().environmentObject(padStore)
            }
            SettingsButton()
                .padding(.leading, 16).padding(.top, 12)
        }
        .beatleRootBackground()
        .useBeatleTheme()
        .safeAreaInset(edge: .bottom) { BeatleTabBar(tab: $tab) }
        .onAppear {
            padStore.loadFromDisk() // ⬅️ restore pad metadata on launch
        }
    }
}
