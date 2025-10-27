import Foundation

/// Kit model - represents a complete kit configuration
struct Kit: Identifiable, Codable {
    let id: String
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var pads: [Pad]
    var kitGain: Float = 1.0
    var tempo: Float? = nil
    
    init(id: String = UUID().uuidString,
         name: String,
         createdAt: Date = Date(),
         pads: [Pad] = [],
         kitGain: Float = 1.0,
         tempo: Float? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = Date()
        self.pads = pads
        self.kitGain = kitGain
        self.tempo = tempo
    }
}

extension Kit {
    mutating func updateTimestamp() {
        updatedAt = Date()
    }
}

