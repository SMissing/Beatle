import Foundation
import AVFoundation
import Accelerate

/// Import progress callback
struct ImportProgress {
    let filename: String
    let stage: ImportStage
    let progress: Double // 0.0 to 1.0
}

enum ImportStage: String {
    case copying = "Copying"
    case decoding = "Decoding"
    case resampling = "Resampling"
    case converting = "Converting"
    case normalizing = "Normalizing"
    case analyzing = "Analyzing"
    case ready = "Ready"
}

/// Audio processing result
struct AudioAnalysis {
    let duration: TimeInterval
    let sampleRate: Double
    let channels: Int
    let fileSize: Int64
    let peak: Float // Peak amplitude
    let rms: Float // RMS amplitude
}

/// Import pipeline for converting audio files to 48kHz mono normalized format
enum ImportPipeline {
    
    /// Import a file with progress updates
    static func importFile(
        from sourceURL: URL,
        to destinationURL: URL,
        progressCallback: ((ImportProgress) -> Void)? = nil
    ) async throws -> AudioAnalysis {
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .decoding,
            progress: 0.1
        ))
        
        // Step 1: Read source file
        guard let inputFile = try? AVAudioFile(forReading: sourceURL) else {
            throw ImportError.decodeFailed
        }
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .decoding,
            progress: 0.3
        ))
        
        // Step 2: Resample to 48kHz
        let targetFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48000,
            channels: 1
        )!
        
        guard let converter = AVAudioConverter(
            from: inputFile.processingFormat,
            to: targetFormat
        ) else {
            throw ImportError.converterInitFailed
        }
        
        // Allocate output buffer
        let inputLength = AVAudioFrameCount(inputFile.length)
        let outputCapacity = AVAudioFrameCount(Double(inputLength) * 48000.0 / inputFile.processingFormat.sampleRate * 1.2)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputCapacity
        ) else {
            throw ImportError.bufferAllocFailed
        }
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .resampling,
            progress: 0.4
        ))
        
        // Step 3: Convert to mono if stereo
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: inputFile.processingFormat,
                frameCapacity: 8192
            ) else {
                outStatus.pointee = .noDataNow
                return nil
            }
            
            do {
                try inputFile.read(into: inputBuffer)
            } catch {
                outStatus.pointee = .endOfStream
                return nil
            }
            
            guard inputBuffer.frameLength > 0 else {
                outStatus.pointee = .endOfStream
                return nil
            }
            
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            throw ImportError.resampleFailed(error.localizedDescription)
        }
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .converting,
            progress: 0.6
        ))
        
        // Step 4: Convert stereo to mono with -3dB gain compensation
        if inputFile.processingFormat.channelCount == 2 {
            // Already converted to mono by converter above, but we should apply -3dB gain
            // to prevent clipping when summing L+R
            let gain: Float = 0.707 // -3dB in linear scale
            if let channelData = outputBuffer.floatChannelData {
                let length = Int(outputBuffer.frameLength)
                for frame in 0..<length {
                    channelData[0][frame] *= gain
                }
            }
        }
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .normalizing,
            progress: 0.7
        ))
        
        // Step 5: Peak normalize to -1.0 dBFS
        normalizeBuffer(outputBuffer, targetPeakdB: -1.0)
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .analyzing,
            progress: 0.8
        ))
        
        // Step 6: Analyze audio
        let analysis = analyzeAudio(buffer: outputBuffer)
        
        // Step 7: Write to destination
        guard let outputFile = try? AVAudioFile(
            forWriting: destinationURL,
            settings: targetFormat.settings
        ) else {
            throw ImportError.writeFailed
        }
        
        do {
            try outputFile.write(from: outputBuffer)
        } catch {
            throw ImportError.writeFailed
        }
        
        // Get final file size
        let attributes = try? FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        
        progressCallback?(ImportProgress(
            filename: sourceURL.lastPathComponent,
            stage: .ready,
            progress: 1.0
        ))
        
        return AudioAnalysis(
            duration: analysis.duration,
            sampleRate: 48000.0,
            channels: 1,
            fileSize: fileSize,
            peak: analysis.peak,
            rms: analysis.rms
        )
    }
    
    // MARK: - Private Helpers
    
    private static func normalizeBuffer(_ buffer: AVAudioPCMBuffer, targetPeakdB: Float) {
        guard let channelData = buffer.floatChannelData else { return }
        let length = Int(buffer.frameLength)
        
        // Find peak
        var peak: Float = 0.0
        for frame in 0..<length {
            let absValue = abs(channelData[0][frame])
            peak = max(peak, absValue)
        }
        
        guard peak > 0 else { return }
        
        // Calculate target peak in linear scale
        let targetPeak = pow(10.0, targetPeakdB / 20.0) // Convert dB to linear
        
        // Calculate gain factor
        let gain = targetPeak / peak
        
        // Apply normalization
        for frame in 0..<length {
            channelData[0][frame] *= gain
        }
    }
    
    private static func analyzeAudio(buffer: AVAudioPCMBuffer) -> (duration: TimeInterval, peak: Float, rms: Float) {
        guard let channelData = buffer.floatChannelData else {
            return (0, 0, 0)
        }
        
        let frameLength = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate
        
        var peak: Float = 0.0
        var sumSquared: Float = 0.0
        
        // Calculate peak and RMS
        for frame in 0..<frameLength {
            let value = channelData[0][frame]
            let absValue = abs(value)
            peak = max(peak, absValue)
            sumSquared += value * value
        }
        
        let rms = sqrt(sumSquared / Float(frameLength))
        let duration = Double(frameLength) / sampleRate
        
        return (duration, peak, rms)
    }
}

enum ImportError: LocalizedError {
    case decodeFailed
    case converterInitFailed
    case bufferAllocFailed
    case resampleFailed(String)
    case writeFailed
    
    var errorDescription: String? {
        switch self {
        case .decodeFailed: return "Failed to decode audio file"
        case .converterInitFailed: return "Failed to initialize audio converter"
        case .bufferAllocFailed: return "Failed to allocate audio buffer"
        case .resampleFailed(let details): return "Resampling failed: \(details)"
        case .writeFailed: return "Failed to write output file"
        }
    }
}

