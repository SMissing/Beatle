import Foundation
import UniformTypeIdentifiers

enum SampleLibraryError: Error {
    case cannotAccessPickedURL
    case copyFailed
    case fileNotFound
}

struct SampleLibrary {
    static let appFolderName = "Beatle"
    static let samplesFolderName = "Samples"
    static let padsFolderName = "Pads"

    // ~/Library/Application Support/Beatle/Samples
    static var samplesRoot: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(appFolderName, isDirectory: true)
                         .appendingPathComponent(samplesFolderName, isDirectory: true)
    }

    static func padFolder(_ padId: Int) -> URL {
        samplesRoot.appendingPathComponent(padsFolderName, isDirectory: true)
                   .appendingPathComponent("pad_\(padId)", isDirectory: true)
    }

    /// Ensure all folders exist & exclude the root from iCloud backups
    static func ensureDirectories(padId: Int? = nil) throws {
        let fm = FileManager.default
        let root = samplesRoot
        let pads = root.appendingPathComponent(padsFolderName, isDirectory: true)
        if !fm.fileExists(atPath: root.path) { try fm.createDirectory(at: root, withIntermediateDirectories: true) }
        if !fm.fileExists(atPath: pads.path) { try fm.createDirectory(at: pads, withIntermediateDirectories: true) }
        if let id = padId {
            let padDir = padFolder(id)
            if !fm.fileExists(atPath: padDir.path) { try fm.createDirectory(at: padDir, withIntermediateDirectories: true) }
        }
        // exclude from iCloud backup
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        var excludeURL = root
        try? excludeURL.setResourceValues(rv)
    }

    /// Import a picked file into Beatle's library for a given pad and return the stored URL
    static func importSample(forPad padId: Int, from pickedURL: URL) async throws -> URL {
        try ensureDirectories(padId: padId)

        // Security-scoped access if outside sandbox
        var needsStop = false
        if pickedURL.startAccessingSecurityScopedResource() { needsStop = true }
        defer { if needsStop { pickedURL.stopAccessingSecurityScopedResource() } }

        let destDir = padFolder(padId)

        // Build unique WAV filename
        let base = pickedURL.deletingPathExtension().lastPathComponent
        let stamp = ISO8601DateFormatter()
        stamp.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let safeStamp = stamp.string(from: Date()).replacingOccurrences(of: ":", with: "")
        let filename = "\(base)_\(safeStamp).wav"
        let destWav = destDir.appendingPathComponent(filename)

        // Convert to 48k WAV (normalization)
        do {
            let url = try await convertToPCM48kWAV(inputURL: pickedURL, outputURL: destWav)
            return url
        } catch {
            print("🛑 Normalize failed:", error.localizedDescription)
            throw SampleLibraryError.copyFailed
        }
    }

    /// Remove the stored sample for a pad (if you keep only one, clear the directory)
    static func clearSamples(forPad padId: Int) throws {
        let fm = FileManager.default
        let dir = padFolder(padId)
        if fm.fileExists(atPath: dir.path) {
            let contents = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            for url in contents { try? fm.removeItem(at: url) }
        }
    }
}
