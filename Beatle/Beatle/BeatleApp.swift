import SwiftUI

@main
struct BeatleApp: App {
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .preferredColorScheme(.dark) // force dark
                .onChange(of: settings.keepAwake) { _, on in
                    UIApplication.shared.isIdleTimerDisabled = on
                }
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = settings.keepAwake
                }
        }
    }
}
