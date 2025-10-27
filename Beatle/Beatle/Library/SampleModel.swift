import Foundation

/// Folder model for organizing samples
struct SampleFolder: Identifiable, Codable {
    let id: String
    var name: String
    let createdAt: Date
    var sampleIds: [String] // Array of sample IDs
    
    init(name: String, id: String = UUID().uuidString) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.sampleIds = []
    }
}

/// Sample model - represents an audio sample in the library
struct Sample: Identifiable, Codable {
    let id: String
    var name: String
    let url: URL
    var folderId: String? // nil for Unassigned
    var isStarred: Bool
    let createdAt: Date
    
    // Audio properties
    var duration: TimeInterval
    let sampleRate: Double
    let channels: Int
    var fileSize: Int64
    let contentHash: String
    
    // Display
    var displayName: String { name }
    
    init(name: String,
         url: URL,
         folderId: String? = nil,
         isStarred: Bool = false,
         duration: TimeInterval = 0,
         sampleRate: Double = 48000,
         channels: Int = 1,
         fileSize: Int64 = 0,
         contentHash: String = "") {
        self.id = contentHash.isEmpty ? UUID().uuidString : contentHash
        self.name = name
        self.url = url
        self.folderId = folderId
        self.isStarred = isStarred
        self.createdAt = Date()
        self.duration = duration
        self.sampleRate = sampleRate
        self.channels = channels
        self.fileSize = fileSize
        self.contentHash = contentHash
    }
}

extension Sample: Hashable {
    static func == (lhs: Sample, rhs: Sample) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// View categories for library browsing
enum LibraryView: String, CaseIterable {
    case all = "All"
    case folders = "Folders"
    case favourites = "Favourites"
    case recents = "Recents"
    case unassigned = "Unassigned"
}

