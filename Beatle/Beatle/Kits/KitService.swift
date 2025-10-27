import Foundation
import Combine

/// Service for managing kit persistence
@MainActor
final class KitService: ObservableObject {
    static let shared = KitService()
    
    @Published private(set) var currentKit: Kit? = nil
    
    private let lastKitIdKey = "beatle.lastKitId"
    
    // MARK: - Methods
    
    func save(_ kit: Kit) async throws {
        let url = StoragePaths.kitURL(kitId: kit.id)
        var updatedKit = kit
        updatedKit.updateTimestamp()
        
        let data = try JSONEncoder().encode(updatedKit)
        try data.write(to: url)
        
        currentKit = updatedKit
    }
    
    func load(kitId: String) async throws -> Kit? {
        let url = StoragePaths.kitURL(kitId: kitId)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let kit = try JSONDecoder().decode(Kit.self, from: data)
        
        currentKit = kit
        return kit
    }
    
    func saveLastKitId(_ kitId: String?) {
        UserDefaults.standard.set(kitId, forKey: lastKitIdKey)
    }
    
    func loadLastKitId() -> String? {
        UserDefaults.standard.string(forKey: lastKitIdKey)
    }
    
    func reopenLastKit(padStore: PadStore) async {
        guard let lastKitId = loadLastKitId() else {
            return
        }
        
        do {
            let kit = try await load(kitId: lastKitId)
            if let kit = kit {
                // Apply kit to pad store
                padStore.pads = kit.pads
                currentKit = kit
            }
        } catch {
            print("Failed to load last kit: \(error)")
        }
    }
    
    func createNewKit(name: String = "New Kit", pads: [Pad]? = nil) async throws {
        let kit = Kit(
            name: name,
            pads: pads ?? generateEmptyKit()
        )
        
        try await save(kit)
        saveLastKitId(kit.id)
    }
    
    private func generateEmptyKit() -> [Pad] {
        let swatches = BeatlePalette.allSwatches
        return (0..<8).map { id in
            Pad(id: id, accentHex: swatches[id % swatches.count].hex)
        }
    }
    
    private func applyKit(_ kit: Kit) async {
        // This will be called from PadStore or wherever kit loading happens
    }
    
    func delete(kitId: String) throws {
        let url = StoragePaths.kitURL(kitId: kitId)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        
        if currentKit?.id == kitId {
            currentKit = nil
        }
    }
}

