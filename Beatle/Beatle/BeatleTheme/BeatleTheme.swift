import SwiftUI

public struct BeatleTheme {
    // 70s accents (fixed)
    public let butter   = Color(hex: "#FFD58E")
    public let apricot  = Color(hex: "#FF9B5A")
    public let coral    = Color(hex: "#F26249")
    public let crimson  = Color(hex: "#EC2F3B")
    public let teal     = Color(hex: "#52B3B6")

    // Dark neutrals (MPC Retro inspired)
    public let surface        = Color(hex: "#191B20") // app background
    public let surfaceAlt     = Color(hex: "#22272E") // panels/bar
    public let surfaceRaised  = Color(hex: "#2A3139")
    public let stroke         = Color(hex: "#5E6B75")
    public let textPrimary    = Color.white.opacity(0.92)
    public let textSecondary  = Color.white.opacity(0.72)
    public let keycap         = Color(hex: "#5E6B75")
    public let keycapAlt      = Color(hex: "#6B3A4D")

    public static let dark = BeatleTheme()
}

// Environment injection (unchanged)
private struct BeatleThemeKey: EnvironmentKey { static let defaultValue = BeatleTheme.dark }
public extension EnvironmentValues {
    var beatle: BeatleTheme {
        get { self[BeatleThemeKey.self] }
        set { self[BeatleThemeKey.self] = newValue }
    }
}
public struct BeatleThemeProvider: ViewModifier {
    public func body(content: Content) -> some View {
        content.environment(\.beatle, .dark)
    }
}
public extension View { func useBeatleTheme() -> some View { modifier(BeatleThemeProvider()) } }
