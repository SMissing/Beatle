import SwiftUI

public enum BeatleTab { case record, pads, synth, library }

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
            case .library: LibraryTabView()
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
        BeatleTabBar(tab: Binding(
            get: { selectedTab },
            set: { newTab in
                let oldTab = selectedTab
                
                // Check if this is a re-tap on the pads tab (within 0.5 seconds)
                if newTab == .pads && oldTab == .pads {
                    if let lastTime = lastTapTime[.pads],
                       Date().timeIntervalSince(lastTime) < 0.5 {
                        // Re-tap detected - toggle edit mode
                        NotificationCenter.default.post(name: NSNotification.Name("BeatlePadEditModeToggle"), object: nil)
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        return // Don't change tab
                    }
                }
                
                selectedTab = newTab
                lastTapTime[newTab] = Date()
            }
        ))
    }
}
