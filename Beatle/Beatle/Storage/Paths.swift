import Foundation
import CryptoKit

/// Centralizes app storage paths and file management
enum StoragePaths {
    /// Documents directory root
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Samples directory: /Documents/Samples/
    static var samplesURL: URL {
        let url = documentsURL.appendingPathComponent("Samples", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    /// Kits directory: /Documents/Kits/
    static var kitsURL: URL {
        let url = documentsURL.appendingPathComponent("Kits", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    /// Previews directory: /Documents/Previews/
    static var previewsURL: URL {
        let url = documentsURL.appendingPathComponent("Previews", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    // MARK: - Sample Paths
    
    /// Get the folder URL for a given folder ID
    static func folderURL(id: String) -> URL {
        let url = samplesURL.appendingPathComponent(id, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    /// Get the file URL for a sample in a specific folder
    static func sampleURL(folderId: String, filename: String) -> URL {
        folderURL(id: folderId).appendingPathComponent(filename)
    }
    
    // MARK: - Kit Paths
    
    /// Get the kit JSON file URL
    static func kitURL(kitId: String) -> URL {
        kitsURL.appendingPathComponent("\(kitId).json")
    }
    
    // MARK: - Preview Paths
    
    /// Get waveform preview URL for a sample
    static func previewURL(sampleId: String) -> URL {
        previewsURL.appendingPathComponent("\(sampleId).waveform")
    }
    
    // MARK: - Utilities
    
    /// Generate a unique filename from content hash to avoid duplicates
    static func uniqueFilename(originalName: String, hash: String, extension: String) -> String {
        let cleanName = URL(fileURLWithPath: originalName).deletingPathExtension().lastPathComponent
        return "\(hash.prefix(8))_\(cleanName).\(`extension`)"
    }
    
    /// Clean filename for file system storage
    static func cleanFilename(_ original: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/?:&=%")
        return original.components(separatedBy: invalidChars).joined(separator: "_")
    }
    
    /// Create a content hash for duplicate detection
    static func contentHash(data: Data) -> String {
        String(data.sha256Hash().prefix(16))
    }
    
    /// Check if a file exists
    static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Delete a file
    static func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

extension Data {
    func sha256Hash() -> String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// Using CryptoKit for hashing - extension at bottom

