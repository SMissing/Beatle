import Foundation

// Minimal stub for PadStateStore - audio functionality removed
struct PadStateDTO: Codable {
    let id: Int
    let name: String
    let accentHex: String
    let storedPath: String?
}

struct PadStateStore {
    static func save(_ pads: [Pad]) {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to save pad metadata without audio
    }
    
    static func load() -> [PadStateDTO] {
        // Audio functionality removed - ready for new implementation
        // This could be reimplemented to load pad metadata without audio
        return []
    }
}
