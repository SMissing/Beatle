import SwiftUI

public enum BeatleShade {
    /// Nav bar background: slightly lighter than surface for separation on dark
    public static func navBarBackground(surface: Color) -> Color { surface.lighter(0.08) }
}

public extension Color {
    func lighter(_ amount: Double) -> Color {
        Color(uiColor: UIColor(self).withBrightnessDelta(+amount))
    }
    func darker(_ amount: Double) -> Color {
        Color(uiColor: UIColor(self).withBrightnessDelta(-amount))
    }
}

fileprivate extension UIColor {
    func withBrightnessDelta(_ delta: Double) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: s, brightness: max(0, min(1, b + delta)), alpha: a)
    }
}
