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
        let dtos = PadStateStore.load()
        
        // Process saved DTOs if they exist
        if !dtos.isEmpty {
            for dto in dtos {
                if let i = pads.firstIndex(where: { $0.id == dto.id }) {
                    pads[i].name = dto.name
                    pads[i].accentHex = dto.accentHex
                    
                    // Only restore URL if file actually exists
                    if let storedPath = dto.storedPath {
                        let url = URL(fileURLWithPath: storedPath)
                        if FileManager.default.fileExists(atPath: url.path) {
                            pads[i].storedURL = url
                            AudioEngineService.shared.loadSample(pad: dto.id, url: url)
                            print("🔄 Restored pad \(dto.id) from disk: \(url.lastPathComponent)")
                        } else {
                            print("🛑 File not found for pad \(dto.id): \(storedPath)")
                            // Clear the stored URL since file doesn't exist
                            pads[i].storedURL = nil
                            pads[i].name = "Empty"
                            // Try to load bundled sample as fallback
                            loadBundledSampleForPad(dto.id)
                        }
                    } else {
                        pads[i].storedURL = nil
                        // Try to load bundled sample for empty pads
                        loadBundledSampleForPad(dto.id)
                    }
                }
            }
        } else {
            // No saved DTOs - load bundled samples for all pads
            print("🔄 No saved pad data found, loading bundled samples for all pads")
            for padId in 0..<8 {
                loadBundledSampleForPad(padId)
            }
        }
    }

    func importSample(for id: Int, from pickedURL: URL) {
        Task {
            do {
                let stored = try await SampleLibrary.importSample(forPad: id, from: pickedURL)
                // ✅ Always update the pad to point to the latest converted WAV
                if let i = pads.firstIndex(where: { $0.id == id }) {
                    pads[i].storedURL = stored
                    pads[i].name = stored.lastPathComponent
                    // reload into engine right now (only if file exists)
                    if FileManager.default.fileExists(atPath: stored.path) {
                        AudioEngineService.shared.loadSample(pad: id, url: stored)
                        print("🔄 Pad \(id) linked to new file:", stored.path)
                    } else {
                        print("🛑 Imported file does not exist:", stored.path)
                    }
                }
            } catch {
                print("🛑 Import failed:", error.localizedDescription)
            }
        }
    }

    func clearSample(for id: Int) {
        do { try SampleLibrary.clearSamples(forPad: id) } catch { print(error) }
        if let i = pads.firstIndex(where: { $0.id == id }) {
            pads[i].storedURL = nil
            pads[i].name = "Empty"
        }
    }
    
    private func loadBundledSampleForPad(_ padId: Int) {
        guard (0..<8).contains(padId) else { return }
        
        let baseName = "\(padId + 1)" // Convert pad ID to sample name (1-8)
        let exts = ["wav", "aif", "aiff"]
        
        for ext in exts {
            // Try BundledSamples subdirectory first (where AudioEngineService finds them)
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "BundledSamples") {
                // Update the pad store
                if let i = pads.firstIndex(where: { $0.id == padId }) {
                    pads[i].storedURL = url
                    pads[i].name = url.lastPathComponent
                    print("🔄 Pad \(padId) loaded bundled sample: \(url.lastPathComponent)")
                    print("🔄 Pad \(padId) hasSample: \(pads[i].hasSample)")
                    
                    // Load into audio engine
                    AudioEngineService.shared.loadSample(pad: padId, url: url)
                }
                
                return
            }
        }
        
        // Fallback to root bundle if not found in subdirectory
        for ext in exts {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                // Update the pad store
                if let i = pads.firstIndex(where: { $0.id == padId }) {
                    pads[i].storedURL = url
                    pads[i].name = url.lastPathComponent
                    print("🔄 Pad \(padId) loaded bundled sample (fallback): \(url.lastPathComponent)")
                    print("🔄 Pad \(padId) hasSample: \(pads[i].hasSample)")
                    
                    // Load into audio engine
                    AudioEngineService.shared.loadSample(pad: padId, url: url)
                }
                
                return
            }
        }
        
        print("⚠️ No bundled sample found for pad \(padId)")
    }
}
