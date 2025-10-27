import SwiftUI

public enum BeatleTab { case record, pads, synth }

struct RootView: View {
    @Environment(\.beatle) private var T
    @State private var tab: BeatleTab = .pads
    @StateObject private var padStore = PadStore()
    
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
        .safeAreaInset(edge: .bottom) { BeatleTabBarWithTap(selectedTab: $tab) }
        .onAppear {
            // Start audio engine first
            AudioEngineService.shared.start()
            // Then restore pad metadata on launch
            Task {
                await padStore.loadFromDisk()
                // Reopen last kit
                await KitService.shared.reopenLastKit(padStore: padStore)
            }
        }
    }
}

/// Tab bar that handles re-tap detection for edit mode
struct BeatleTabBarWithTap: View {
    @Binding var selectedTab: BeatleTab
    @State private var lastTapTime: [BeatleTab: Date] = [:]
    
    var body: some View {
        BeatleTabBar(tab: $selectedTab)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == .pads {
                    // Check if this is a re-tap (within 0.5 seconds)
                    if let lastTime = lastTapTime[.pads],
                       Date().timeIntervalSince(lastTime) < 0.5 {
                        // Re-tap detected - notify PadsPage
                        NotificationCenter.default.post(name: NSNotification.Name("BeatlePadEditModeToggle"), object: nil)
                    }
                    lastTapTime[.pads] = Date()
                }
            }
    }
}
