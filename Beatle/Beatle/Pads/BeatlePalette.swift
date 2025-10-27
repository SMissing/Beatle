import SwiftUI

/// Beatle colour palette - retro/VHS-inspired swatches
struct BeatlePalette {
    // MARK: - Swatch Colors (hex values)
    static let warmApricot = "#F6B17A"
    static let sunsetRed = "#E26D5A"
    static let burntSienna = "#C75146"
    static let oliveGreen = "#7FB069"
    static let teal = "#3A7D7C"
    static let inkBlue = "#2E4057"
    static let retroPurple = "#7851A9"
    static let mustard = "#F2D479"
    static let dustyPink = "#EFA8B8"
    static let washedSky = "#8CC4FF"
    
    // MARK: - Swatch Array
    static let allSwatches: [(hex: String, name: String)] = [
        (warmApricot, "Warm Apricot"),
        (sunsetRed, "Sunset Red"),
        (burntSienna, "Burnt Sienna"),
        (oliveGreen, "Olive Green"),
        (teal, "Teal"),
        (inkBlue, "Ink Blue"),
        (retroPurple, "Retro Purple"),
        (mustard, "Mustard"),
        (dustyPink, "Dusty Pink"),
        (washedSky, "Washed Sky")
    ]
    
    // MARK: - Convenience Methods
    
    static func color(from hex: String) -> Color {
        Color(hex: hex)
    }
    
    static func defaultSwatch(for index: Int) -> String {
        let swatches = allSwatches
        return swatches[index % swatches.count].hex
    }
    
    /// Check if a hex color is in the palette
    static func contains(_ hex: String) -> Bool {
        allSwatches.contains { $0.hex.lowercased() == hex.lowercased() }
    }
    
    /// Find the name for a hex color
    static func name(for hex: String) -> String? {
        allSwatches.first { $0.hex.lowercased() == hex.lowercased() }?.name
    }
}

/// Color picker view for Beatle palette
struct BeatleColorPicker: View {
    @Binding var selectedHex: String
    let padding: CGFloat
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: padding), count: 5), spacing: padding) {
            ForEach(BeatlePalette.allSwatches, id: \.hex) { swatch in
                Button {
                    selectedHex = swatch.hex
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: swatch.hex))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedHex == swatch.hex ? Color.white : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    init(selectedHex: Binding<String>, padding: CGFloat = 12) {
        self._selectedHex = selectedHex
        self.padding = padding
    }
}

