import Foundation
import Combine

/// Sample library index - manages all samples and folders
final class SampleIndex: ObservableObject {
    static let shared = SampleIndex()
    
    // MARK: - Published Properties
    
    @Published private(set) var samples: [String: Sample] = [:]
    @Published private(set) var folders: [String: SampleFolder] = [:]
    
    // MARK: - Computed Properties
    
    var allSamples: [Sample] {
        Array(samples.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    var starredSamples: [Sample] {
        Array(samples.values).filter { $0.isStarred }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var recentSamples: [Sample] {
        Array(samples.values).sorted { $0.createdAt > $1.createdAt }.prefix(50).map { $0 }
    }
    
    var unassignedSamples: [Sample] {
        Array(samples.values).filter { $0.folderId == nil }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var allFolders: [SampleFolder] {
        Array(folders.values).sorted { $0.name < $1.name }
    }
    
    // MARK: - Methods
    
    func sample(id: String) -> Sample? {
        samples[id]
    }
    
    func folder(id: String) -> SampleFolder? {
        folders[id]
    }
    
    func samplesIn(folderId: String) -> [Sample] {
        Array(samples.values).filter { $0.folderId == folderId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func addSample(_ sample: Sample) {
        samples[sample.id] = sample
        save()
    }
    
    func updateSample(_ sample: Sample) {
        samples[sample.id] = sample
        save()
    }
    
    func removeSample(id: String) {
        samples.removeValue(forKey: id)
        // Remove from folder's sampleIds if present
        for (folderId, var folder) in folders {
            folder.sampleIds.removeAll { $0 == id }
            folders[folderId] = folder
        }
        save()
    }
    
    func addFolder(_ folder: SampleFolder) {
        folders[folder.id] = folder
        save()
    }
    
    func updateFolder(_ folder: SampleFolder) {
        folders[folder.id] = folder
        save()
    }
    
    func removeFolder(id: String) {
        // Move samples in this folder to unassigned
        if let folder = folders[id] {
            for sampleId in folder.sampleIds {
                if var sample = samples[sampleId] {
                    sample.folderId = nil
                    samples[sampleId] = sample
                }
            }
        }
        folders.removeValue(forKey: id)
        save()
    }
    
    func toggleStar(sampleId: String) {
        if var sample = samples[sampleId] {
            sample.isStarred.toggle()
            samples[sampleId] = sample
            save()
        }
    }
    
    func moveSample(_ sampleId: String, to folderId: String?) {
        if var sample = samples[sampleId] {
            sample.folderId = folderId
            samples[sampleId] = sample
            save()
        }
    }
    
    func findSample(byContentHash hash: String) -> Sample? {
        samples.values.first { $0.contentHash == hash }
    }
    
    // MARK: - Persistence
    
    private let indexURL = StoragePaths.documentsURL.appendingPathComponent("SampleIndex.json")
    
    func save() {
        let data = SampleIndexData(
            samples: samples,
            folders: folders
        )
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: indexURL)
        }
    }
    
    func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode(SampleIndexData.self, from: data) else {
            return
        }
        self.samples = decoded.samples
        self.folders = decoded.folders
    }
    
    init() {
        load()
    }
}

private struct SampleIndexData: Codable {
    let samples: [String: Sample]
    let folders: [String: SampleFolder]
}

