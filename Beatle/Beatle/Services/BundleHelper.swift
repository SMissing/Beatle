import Foundation

/// Unified bundle lookup helper used by both PadStore and AudioEngineService
struct BundleHelper {
    /// Resolves bundled sample URL for a given base name (e.g., "1", "2", etc.)
    /// Tries /BundledSamples/<name>.{wav,aif,aiff} first, then falls back to root bundle
    static func resolveBundledURL(named base: String) -> URL? {
        let exts = ["wav", "aif", "aiff"]
        
        // Try /BundledSamples subfolder first
        for ext in exts {
            if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "BundledSamples") {
                return url
            }
        }
        
        // Fallback to root bundle
        for ext in exts {
            if let url = Bundle.main.url(forResource: base, withExtension: ext) {
                return url
            }
        }
        
        return nil
    }
}
