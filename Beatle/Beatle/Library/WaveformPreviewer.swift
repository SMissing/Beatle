import Foundation
import AVFoundation
import Accelerate

/// Generates waveform preview data for visual display
enum WaveformPreviewer {
    
    /// Target points for waveform preview (for efficient rendering)
    static let targetPoints = 200
    
    /// Generate waveform data from audio file
    static func generate(from url: URL) -> [Float]? {
        guard let file = try? AVAudioFile(forReading: url) else {
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            return nil
        }
        
        guard (try? file.read(into: buffer)) != nil else {
            return nil
        }
        
        return generate(buffer: buffer)
    }
    
    /// Generate waveform data from buffer
    static func generate(buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let frameLength = Int(buffer.frameLength)
        
        // If we have stereo, use the first channel (mono conversion)
        let monoSignal = channelData[0]
        
        // Downsample to target points
        let step = max(1, frameLength / targetPoints)
        var waveform: [Float] = []
        waveform.reserveCapacity(targetPoints)
        
        // For each target point, calculate RMS over a window
        for i in 0..<targetPoints {
            let start = i * step
            let end = min(start + step, frameLength)
            
            guard end > start else { continue }
            
            var maxValue: Float = 0.0
            for j in start..<end {
                let absValue = abs(monoSignal[j])
                maxValue = max(maxValue, absValue)
            }
            
            waveform.append(maxValue)
        }
        
        return waveform
    }
    
    /// Save waveform data to cache
    static func save(waveform: [Float], sampleId: String) {
        let url = StoragePaths.previewURL(sampleId: sampleId)
        let data = Data(bytes: waveform, count: waveform.count * MemoryLayout<Float>.size)
        try? data.write(to: url)
    }
    
    /// Load waveform data from cache
    static func load(sampleId: String) -> [Float]? {
        let url = StoragePaths.previewURL(sampleId: sampleId)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let count = data.count / MemoryLayout<Float>.size
        return data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0.baseAddress?.assumingMemoryBound(to: Float.self), count: count))
        }
    }
    
    /// Generate or load waveform for a sample
    static func waveform(for sample: Sample) async -> [Float] {
        // Try cache first
        if let cached = load(sampleId: sample.id) {
            return cached
        }
        
        // Generate from file
        guard let waveform = generate(from: sample.url) else {
            return Array(repeating: 0.0, count: targetPoints)
        }
        
        // Cache it
        save(waveform: waveform, sampleId: sample.id)
        
        return waveform
    }
    
    static func waveform(for url: URL) async -> [Float] {
        // Try to load cached waveform if we can identify it by URL
        let sampleId = url.deletingPathExtension().lastPathComponent
        
        if let cached = load(sampleId: sampleId) {
            return cached
        }
        
        // Generate from file
        guard let waveform = generate(from: url) else {
            return Array(repeating: 0.0, count: targetPoints)
        }
        
        // Cache it
        save(waveform: waveform, sampleId: sampleId)
        
        return waveform
    }
}

