import Foundation
import AVFoundation
import AudioKit
import SoundpipeAudioKit
import Combine

@MainActor
final class AudioEngineService: ObservableObject {
    static let shared = AudioEngineService()

    // Canonical processing format - use 48kHz to match engine
    private let processingFormat = AVAudioFormat(
        standardFormatWithSampleRate: 48_000,
        channels: 2
    )!

    private lazy var engine = AudioEngine()
    private let mainMixer = Mixer()

    private var padMixers: [Mixer] = (0..<8).map { _ in Mixer() }
    
    // Audio players and buffers for each pad
    private var padPlayers: [AudioPlayer?] = Array(repeating: nil, count: 8)
    private var padBuffers: [AVAudioPCMBuffer?] = Array(repeating: nil, count: 8)

    private var started = false

    private init() {
        // Ensure AudioKit settings are configured before any nodes are created
        Settings.sampleRate = 48_000
        Settings.bufferLength = .short
        
        // Set volumes for all mixers
        padMixers.forEach { mixer in
            mixer.volume = 1.0
        }
        
        mainMixer.volume = 1.0
    }

    func start() {
        guard !started else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .defaultToSpeaker not allowed with .playback → causes -50
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.0029)
            try session.setActive(true)

            // Graph wiring (no dummy nodes)
            engine.output = mainMixer

            // Connect each padMixer into the main mixer
            for m in padMixers {
                mainMixer.addInput(m)
            }

            try engine.start()
            started = true
            print("✅ Audio engine started")

            // Only after engine is running:
            preloadBundledPads()

        } catch {
            print("🛑 Audio start error: \(error)")
            // Do NOT preload or proceed if engine failed
            return
        }
    }
    
    func stop() {
        engine.stop()
        started = false
    }

    // MARK: Bundled Sample Loading
    func preloadBundledPads() {
        let baseNames = (1...8).map { "\($0)" } // "1"..."8"
        for i in 0..<baseNames.count {
            guard let url = resolveBundledURL(named: baseNames[i]) else {
                print("⚠️ Missing bundled sample \(baseNames[i])")
                continue
            }
            do {
                try loadPad(i, from: url)
                print("✅ Preloaded pad \(i): \(url.lastPathComponent)")
            } catch {
                print("❌ Failed to preload pad \(i): \(error)")
            }
        }
    }
    
    func loadBundledSampleForPad(_ padId: Int) {
        guard (0..<8).contains(padId) else { return }
        
        let baseName = "\(padId + 1)" // Convert pad ID to sample name (1-8)
        guard let url = resolveBundledURL(named: baseName) else {
            print("⚠️ No bundled sample available for pad \(padId)")
            return
        }
        
        do {
            try loadPad(padId, from: url)
            print("✅ Loaded bundled sample for pad \(padId): \(url.lastPathComponent)")
        } catch {
            print("❌ Failed to load bundled sample for pad \(padId): \(error)")
        }
    }

    private func resolveBundledURL(named base: String) -> URL? {
        return BundleHelper.resolveBundledURL(named: base)
    }


    private func loadPad(_ index: Int, from url: URL) throws {
        let file = try AVAudioFile(forReading: url)

        // Always end up with a 48k/2ch buffer
        guard let out = AVAudioPCMBuffer(pcmFormat: processingFormat,
                                         frameCapacity: AVAudioFrameCount(file.length)) else {
            throw NSError(domain: "Beatle", code: -1, userInfo: [NSLocalizedDescriptionKey: "Buffer alloc failed"])
        }

        if file.processingFormat.sampleRate != processingFormat.sampleRate ||
           file.processingFormat.channelCount != processingFormat.channelCount {

            guard let converter = AVAudioConverter(from: file.processingFormat, to: processingFormat) else {
                throw NSError(domain: "Beatle", code: -2, userInfo: [NSLocalizedDescriptionKey: "Converter init failed"])
            }

            var convertError: NSError?

            // We'll stream chunks from the file until exhausted
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                let chunk = AVAudioFrameCount(8192)
                guard let temp = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: chunk) else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                do {
                    try file.read(into: temp)
                } catch {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                if temp.frameLength == 0 {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                outStatus.pointee = .haveData
                return temp
            }

            converter.convert(to: out, error: &convertError, withInputFrom: inputBlock)
            if let e = convertError { throw e }

        } else {
            try file.read(into: out)
        }

        // Make or reuse player — but ensure it runs at 48k
        let player: AudioPlayer
        if let existing = padPlayers[index] {
            // Inspect existing player's current format
            let currentSR = existing.avAudioNode.outputFormat(forBus: 0).sampleRate
            if currentSR != processingFormat.sampleRate {
                // Rebuild the player at 48k
                padMixers[index].removeInput(existing)       // detach from graph
                let newPlayer = AudioPlayer()
                padMixers[index].addInput(newPlayer)         // AudioKit graph attach/connect
                padPlayers[index] = newPlayer
                player = newPlayer
                print("🔧 Recreated pad \(index) player at 48k (was \(currentSR))")
            } else {
                player = existing
                player.stop()
            }
        } else {
            // Fresh player
            let p = AudioPlayer()
            padPlayers[index] = p
            padMixers[index].addInput(p)                     // AudioKit graph attach/connect
            player = p
        }

        // Assign the (48k) buffer
        padBuffers[index] = out
        player.buffer = out
        player.isLooping = false
        player.volume = 1.0

        // Verify player is running at 48kHz
        let sr = player.avAudioNode.outputFormat(forBus: 0).sampleRate
        if sr != 48_000 {
            print("⚠️ Pad \(index) player output SR: \(sr) (expected 48kHz)")
        }
    }

    // MARK: User Sample Loading (for imported files)
    func loadSample(pad id: Int, url: URL) {
        guard (0..<8).contains(id) else { 
            print("🛑 Invalid pad ID: \(id)")
            return 
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("🛑 File does not exist: \(url.path)")
            return
        }
        
        do {
            try loadPad(id, from: url)
            print("✅ User sample loaded for pad \(id): \(url.lastPathComponent)")
        } catch let error as NSError {
            print("🛑 Failed to load user sample for pad \(id): \(error.localizedDescription)")
            print("🛑 Error domain: \(error.domain), code: \(error.code)")
        } catch {
            print("🛑 Failed to load user sample for pad \(id):", error)
        }
    }

    // MARK: Trigger
    func triggerPad(_ index: Int) {
        guard engine.avEngine.isRunning else { return }
        guard let player = padPlayers[index], padBuffers[index] != nil else { return }
        player.stop()
        player.play()
    }

}