import Foundation

struct PadDTO: Codable {
    let id: Int
    let name: String
    let accentHex: String
    let storedPath: String? // path inside our sandbox (Application Support)
}

enum PadStateStore {
    private static var stateDir: URL {
      let asu = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      return asu.appendingPathComponent("Beatle/State", isDirectory: true)
    }
    private static var stateFile: URL { stateDir.appendingPathComponent("pads.json") }

    static func save(_ pads: [Pad]) {
        do {
            try FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
            let dtos = pads.map { PadDTO(id: $0.id, name: $0.name, accentHex: $0.accentHex, storedPath: $0.storedURL?.path) }
            let data = try JSONEncoder().encode(dtos)
            try data.write(to: stateFile, options: .atomic)
        } catch { print("PadState save failed:", error) }
    }

    static func load() -> [PadDTO] {
        do {
            let data = try Data(contentsOf: stateFile)
            return try JSONDecoder().decode([PadDTO].self, from: data)
        } catch { return [] }
    }
}
