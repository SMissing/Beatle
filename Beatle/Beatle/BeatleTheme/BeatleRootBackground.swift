import SwiftUI

public struct BeatleRootBackground: ViewModifier {
    @Environment(\.beatle) private var T
    public func body(content: Content) -> some View {
        ZStack { T.surface.ignoresSafeArea(); content }
    }
}

public extension View {
    func beatleRootBackground() -> some View { self.modifier(BeatleRootBackground()) }
}
