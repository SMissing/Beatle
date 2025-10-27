import Foundation

struct SampleLibrary {
    static func importSample(forPad padId: Int, from url: URL) async throws -> URL {
        // Import the sample through the import pipeline
        let destinationURL = StoragePaths.sampleURL(
            folderId: "unassigned",
            filename: UUID().uuidString + ".wav"
        )
        
        // Import with conversion
        let _ = try await ImportPipeline.importFile(
            from: url,
            to: destinationURL,
            progressCallback: nil
        )
        
        return destinationURL
    }
    
    static func clearSamples(forPad padId: Int) throws {
        // Clear the pad in the audio engine
        AudioEngineService.shared.clearPad(padId)
    }
}
