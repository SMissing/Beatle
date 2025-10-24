import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("beatle.keepAwake") var keepAwake: Bool = false
}
