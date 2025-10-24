import Foundation
@preconcurrency import AVFoundation

enum AudioNormalizeError: Error { case assetFailed, readerFailed, writerFailed, convertFailed }

/// Robustly convert any readable audio (mp3/m4a/wav/aiff/caf) to 48kHz PCM Float32 WAV.
/// Returns `outputURL` on success.
func convertToPCM48kWAV(inputURL: URL, outputURL: URL) async throws -> URL {
    // Build asset (handles compressed types better than AVAudioFile)
    let asset = AVURLAsset(url: inputURL)
    guard let track = try? await asset.loadTracks(withMediaType: .audio).first else {
        print("🛑 Converter: no audio track in asset")
        throw AudioNormalizeError.assetFailed
    }

    // Reader
    guard let reader = try? AVAssetReader(asset: asset) else {
        print("🛑 Converter: failed to create AVAssetReader")
        throw AudioNormalizeError.readerFailed
    }

    // Get track properties using modern API
    let naturalTimeScale = try await track.load(.naturalTimeScale)
    let formatDescriptions = try await track.load(.formatDescriptions)
    
    // Source output: decompress to PCM (device sample rate agnostic)
    let sourceSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMIsNonInterleaved: false,
        AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsFloatKey: true,
        AVSampleRateKey: naturalTimeScale > 0 ? naturalTimeScale : 44100,
        AVNumberOfChannelsKey: max(1, formatDescriptions.compactMap { CMAudioFormatDescriptionGetStreamBasicDescription($0)?.pointee.mChannelsPerFrame }.first ?? 2)
    ]
    let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: sourceSettings)
    readerOutput.alwaysCopiesSampleData = false
    reader.add(readerOutput)

    // Destination format: 48k Float32 interleaved, same channel count as source output reports
    reader.startReading()

    // Probe first buffer to determine channels
    var channels: UInt32 = 2
    if let firstBuffer = readerOutput.copyNextSampleBuffer(), let bdesc = CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(firstBuffer)!)?.pointee {
        channels = max(1, bdesc.mChannelsPerFrame)
        CMSampleBufferInvalidate(firstBuffer)
    }

    guard let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: AVAudioChannelCount(channels), interleaved: true) else {
        print("🛑 Converter: failed to build output format")
        throw AudioNormalizeError.convertFailed
    }

    // Writer file
    if FileManager.default.fileExists(atPath: outputURL.path) { try? FileManager.default.removeItem(at: outputURL) }
    guard let outFile = try? AVAudioFile(forWriting: outputURL, settings: outFormat.settings, commonFormat: .pcmFormatFloat32, interleaved: true) else {
        print("🛑 Converter: failed to open output WAV file")
        throw AudioNormalizeError.writerFailed
    }

    // Converter from whatever the reader gives → target format
    // We'll build an AVAudioFormat for the reader's CMSampleBuffer dynamically.
    // Using a dummy to satisfy the type; we'll actually convert between dynamic input format → outFormat below.
    // If this fails, we will try per-buffer converter.
    // But typically we'll create a new converter per buffer format change.
    _ = AVAudioConverter(from: outFormat, to: outFormat)

    // Read loop (continue from where we left off after probing)
    while reader.status == .reading {
        guard let sample = readerOutput.copyNextSampleBuffer() else { break }
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sample) else { continue }
        guard let fmtDesc = CMSampleBufferGetFormatDescription(sample) else { continue }
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc)?.pointee else { continue }

        // Build an AVAudioFormat for the input buffer
        guard let inFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: asbd.mSampleRate,
                                           channels: asbd.mChannelsPerFrame,
                                           interleaved: true) else { continue }

        // Copy bytes into an AVAudioPCMBuffer
        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sample))
        guard let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frameCount) else { continue }
        inBuffer.frameLength = frameCount

        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
        if let dp = dataPointer, let ch0 = inBuffer.floatChannelData?.pointee {
            // Interleaved float32 expected in `dp`
            memcpy(ch0, dp, totalLength)
        }

        // Convert → outFormat
        guard let realConverter = AVAudioConverter(from: inFormat, to: outFormat) else {
            CMSampleBufferInvalidate(sample)
            print("🛑 Converter: could not create converter for buffer")
            throw AudioNormalizeError.convertFailed
        }

        guard let outBuf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: inBuffer.frameLength) else {
            CMSampleBufferInvalidate(sample)
            throw AudioNormalizeError.convertFailed
        }

        var err: NSError?
        let status = realConverter.convert(to: outBuf, error: &err, withInputFrom: { [inBuffer] _, ioStatus in
            ioStatus.pointee = .haveData
            return inBuffer
        })
        if let e = err {
            CMSampleBufferInvalidate(sample)
            print("🛑 Converter error:", e.localizedDescription)
            throw AudioNormalizeError.convertFailed
        }

        if status == .haveData, outBuf.frameLength > 0 {
            try outFile.write(from: outBuf)
        }

        CMSampleBufferInvalidate(sample)
    }

    if reader.status == .completed {
        print("✅ Converted to WAV:", outputURL.lastPathComponent)
        return outputURL
    } else if reader.status == .failed {
        print("🛑 Reader failed:", reader.error?.localizedDescription ?? "(unknown)")
        throw AudioNormalizeError.readerFailed
    } else {
        print("⚠️ Reader ended with status:", reader.status.rawValue)
        return outputURL
    }
}
