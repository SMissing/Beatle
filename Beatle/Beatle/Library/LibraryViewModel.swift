import Foundation
import SwiftUI
import Combine

/// View model for the library tab
@MainActor
final class LibraryViewModel: ObservableObject {
    
    @Published var selectedView: LibraryView = .all
    @Published private(set) var searchText = ""
    @Published private(set) var isImporting = false
    @Published private(set) var importProgress: ImportProgress? = nil
    @Published var showImportPicker = false
    
    private let sampleIndex = SampleIndex.shared
    
    // MARK: - Computed Properties
    
    var currentSamples: [Sample] {
        var samples: [Sample] = []
        
        switch selectedView {
        case .all:
            samples = sampleIndex.allSamples
        case .folders:
            // Show folders list
            return []
        case .favourites:
            samples = sampleIndex.starredSamples
        case .recents:
            samples = sampleIndex.recentSamples
        case .unassigned:
            samples = sampleIndex.unassignedSamples
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            samples = samples.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return samples
    }
    
    var folders: [SampleFolder] {
        sampleIndex.allFolders
    }
    
    // MARK: - Methods
    
    func selectView(_ view: LibraryView) {
        selectedView = view
    }
    
    func setSearchText(_ text: String) {
        searchText = text
    }
    
    func toggleStar(for sample: Sample) {
        sampleIndex.toggleStar(sampleId: sample.id)
    }
    
    func moveSample(_ sample: Sample, to folderId: String?) {
        sampleIndex.moveSample(sample.id, to: folderId)
    }
    
    func deleteSample(_ sample: Sample) {
        // Remove file
        try? FileManager.default.removeItem(at: sample.url)
        // Remove preview
        try? FileManager.default.removeItem(at: StoragePaths.previewURL(sampleId: sample.id))
        // Remove from index
        sampleIndex.removeSample(id: sample.id)
    }
    
    func createFolder(name: String) -> SampleFolder {
        let folder = SampleFolder(name: name)
        sampleIndex.addFolder(folder)
        return folder
    }
    
    func importFiles(_ urls: [URL], to folder: SampleFolder? = nil) async {
        isImporting = true
        defer { isImporting = false }
        
        let folderId = folder?.id
        
        for url in urls {
            await importFile(url, to: folderId)
        }
    }
    
    private func importFile(_ sourceURL: URL, to folderId: String?) async {
        do {
            // Check for duplicate
            let contentData = try Data(contentsOf: sourceURL)
            let hash = StoragePaths.contentHash(data: contentData)
            
            if let existing = sampleIndex.findSample(byContentHash: hash) {
                // Duplicate found - create a link to it
                let linkedSample = Sample(
                    name: "\(existing.name) (copy)",
                    url: existing.url,
                    folderId: folderId,
                    isStarred: existing.isStarred,
                    duration: existing.duration,
                    sampleRate: existing.sampleRate,
                    channels: existing.channels,
                    fileSize: existing.fileSize,
                    contentHash: existing.contentHash
                )
                sampleIndex.addSample(linkedSample)
                return
            }
            
            // Generate destination path
            let filename = StoragePaths.uniqueFilename(
                originalName: sourceURL.lastPathComponent,
                hash: hash,
                extension: "wav"
            )
            let destinationURL = StoragePaths.sampleURL(
                folderId: folderId ?? "unassigned",
                filename: filename
            )
            
            // Import with progress
            let analysis = try await ImportPipeline.importFile(
                from: sourceURL,
                to: destinationURL,
                progressCallback: { [weak self] progress in
                    Task { @MainActor in
                        self?.importProgress = progress
                    }
                }
            )
            
            // Create sample record
            let sample = Sample(
                name: sourceURL.deletingPathExtension().lastPathComponent,
                url: destinationURL,
                folderId: folderId,
                isStarred: false,
                duration: analysis.duration,
                sampleRate: analysis.sampleRate,
                channels: analysis.channels,
                fileSize: analysis.fileSize,
                contentHash: hash
            )
            
            sampleIndex.addSample(sample)
            
            // Generate waveform in background
            Task {
                if let waveform = WaveformPreviewer.generate(from: destinationURL) {
                    WaveformPreviewer.save(waveform: waveform, sampleId: sample.id)
                }
            }
            
        } catch {
            print("Import failed: \(error)")
        }
    }
}

