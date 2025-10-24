import SwiftUI
import Combine

struct Pad: Identifiable, Equatable {
    let id: Int
    var name: String = "Empty"
    var accentHex: String
    var storedURL: URL? = nil
    var hasSample: Bool { storedURL != nil }
    var accent: Color { Color(hex: accentHex) }
}

@MainActor
final class PadStore: ObservableObject {
    @Published var pads: [Pad] = [
        Pad(id: 0, accentHex: "#F26249"),
        Pad(id: 1, accentHex: "#52B3B6"),
        Pad(id: 2, accentHex: "#EC2F3B"),
        Pad(id: 3, accentHex: "#FF9B5A"),
        Pad(id: 4, accentHex: "#F26249"),
        Pad(id: 5, accentHex: "#52B3B6"),
        Pad(id: 6, accentHex: "#EC2F3B"),
        Pad(id: 7, accentHex: "#FF9B5A"),
    ] {
        didSet { PadStateStore.save(pads) }
    }

    func loadFromDisk() {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to load pad metadata without audio processing
        print("📱 PadStore: Audio functionality removed, ready for new implementation")
    }

    func importSample(for id: Int, from pickedURL: URL) {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to handle file import without audio processing
        print("📱 Import functionality removed, ready for new implementation")
        
        // For now, just update the UI to show a placeholder
        if let i = pads.firstIndex(where: { $0.id == id }) {
            pads[i].name = pickedURL.lastPathComponent
            pads[i].storedURL = pickedURL
        }
    }

    func clearSample(for id: Int) {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to handle file cleanup without audio processing
        if let i = pads.firstIndex(where: { $0.id == id }) {
            pads[i].storedURL = nil
            pads[i].name = "Empty"
        }
    }
    
    private func loadBundledSampleForPad(_ padId: Int) {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to handle bundled resources without audio processing
        print("📱 Bundled sample loading removed, ready for new implementation")
    }
}
