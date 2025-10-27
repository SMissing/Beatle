import SwiftUI

public enum BeatleFont {
    // Swap to your custom fonts later if desired
    public static let display = Font.system(.title, design: .rounded).weight(.heavy)
    public static let title   = Font.system(.title2, design: .rounded).weight(.bold)
    public static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    public static let body    = Font.system(.body, design: .rounded)
    public static let label   = Font.system(.subheadline, design: .rounded).weight(.medium)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let mono    = Font.system(.caption, design: .monospaced)
}
