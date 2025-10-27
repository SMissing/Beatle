import Foundation
import AVFoundation
import AudioKit
import SoundpipeAudioKit
import Combine

@MainActor
final class AudioEngineService: ObservableObject {
    static let shared = AudioEngineService()

    // Canonical processing format - use 44.1kHz to match AudioPlayer
    private let processingFormat = AVAudioFormat(
        standardFormatWithSampleRate: 44_100,
        channels: 2
    )!

    private let engine = AudioEngine()
    private let mainMixer = Mixer()

    private var padMixers: [Mixer] = (0..<8).map { _ in Mixer() }
    
    // Audio players and buffers for each pad
    private var padPlayers: [AudioPlayer?] = Array(repeating: nil, count: 8)
    private var padBuffers: [AVAudioPCMBuffer?] = Array(repeating: nil, count: 8)

    private var started = false

    private init() {
        // Ensure AudioKit settings are configured before any nodes are created
        Settings.sampleRate = 44_100
        Settings.bufferLength = .short
        
        print("🔧 AudioKit Settings: sampleRate=\(Settings.sampleRate), bufferLength=\(Settings.bufferLength)")
        
        // Set volumes for all mixers
        padMixers.forEach { mixer in
            mixer.volume = 1.0
        }
        
        mainMixer.volume = 1.0
    }

    func start() {
        guard !started else { 
            print("🔍 DEBUG: Audio engine already started")
            return 
        }
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

            // Note: Bundled samples will be loaded by PadStore.loadFromDisk()

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
        let exts = ["wav", "aif", "aiff"]
        print("🔍 DEBUG: Looking for bundled sample: \(base)")
        
        for ext in exts {
            if let u = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "BundledSamples") {
                print("🔍 DEBUG: Found bundled sample: \(u.path)")
                return u
            }
        }
        // fallback if Xcode didn't nest under subdirectory in bundle
        for ext in exts {
            if let u = Bundle.main.url(forResource: base, withExtension: ext) {
                print("🔍 DEBUG: Found bundled sample (fallback): \(u.path)")
                return u
            }
        }
        print("🔍 DEBUG: No bundled sample found for: \(base)")
        return nil
    }


    private func loadPad(_ index: Int, from url: URL) throws {
        let file = try AVAudioFile(forReading: url)

        // Always end up with a 44.1k/2ch buffer
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
            print("🔧 Created new player for pad \(index)")
        }

        // Assign the (44.1k) buffer
        padBuffers[index] = out
        player.buffer = out
        player.isLooping = false
        player.volume = 1.0
        

        // Debug what the player is actually running at now
        let sr = player.avAudioNode.outputFormat(forBus: 0).sampleRate
        print("🔧 Pad \(index) player output SR now: \(sr)")
        
        // Additional debug info
        print("🔧 Pad \(index) PLAYER SETUP:")
        print("🔧   - Buffer assigned: \(player.buffer != nil)")
        print("🔧   - Volume: \(player.volume)")
        print("🔧   - IsLooping: \(player.isLooping)")
        print("🔧   - HasEngine: \(player.avAudioNode.engine != nil)")
        print("🔧   - Buffer frameLength: \(out.frameLength)")
        print("🔧   - Buffer sampleRate: \(out.format.sampleRate)")
        print("🔧   - Buffer channels: \(out.format.channelCount)")
        
        // Check for format mismatch and warn
        if sr != out.format.sampleRate {
            print("⚠️ FORMAT MISMATCH: Player SR=\(sr), Buffer SR=\(out.format.sampleRate)")
            print("⚠️ This will prevent audio playback!")
        } else {
            print("✅ FORMAT MATCH: Player and buffer both at \(sr)Hz")
        }
    }

    // MARK: User Sample Loading (for imported files)
    func loadSample(pad id: Int, url: URL) {
        guard (0..<8).contains(id) else { 
            print("🛑 Invalid pad ID: \(id)")
            return 
        }
        
        print("🔍 DEBUG: Loading user sample for pad \(id) from: \(url.path)")
        
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

    // MARK: Trigger & Self-Test
    
    /// Current pad configurations - managed by PadStore
    var padConfigs: [Int: (playbackMode: PlaybackMode, chokeGroup: Int, gain: Float, pitch: Int)] = [:]
    private var activePad: Int? = nil // For gate mode
    
    func updatePadConfig(id: Int, playbackMode: PlaybackMode, chokeGroup: Int, gain: Float, pitch: Int) {
        padConfigs[id] = (playbackMode, chokeGroup, gain, pitch)
    }
    
    func triggerPad(_ index: Int, isDown: Bool = true) {
        print("🎵 AUDIO TRIGGER: triggerPad called for pad \(index), isDown=\(isDown)")
        print("🎵 ENGINE STATE: isRunning=\(engine.avEngine.isRunning), started=\(started)")
        
        guard engine.avEngine.isRunning else { 
            print("❌ AUDIO TRIGGER: Engine not running"); 
            return 
        }
        
        guard let player = padPlayers[index] else {
            print("❌ AUDIO TRIGGER: No player for pad \(index)");
            return
        }
        
        guard padBuffers[index] != nil else {
            print("❌ AUDIO TRIGGER: No buffer for pad \(index)");
            return
        }
        
        // Get pad config
        let config = padConfigs[index] ?? (.oneShot, 0, 1.0, 0)
        
        // Handle choke groups
        if config.chokeGroup > 0 {
            for (i, otherPlayer) in padPlayers.enumerated() {
                if i != index, let player = otherPlayer, let otherConfig = padConfigs[i] {
                    if otherConfig.chokeGroup == config.chokeGroup {
                        print("🎵 CHOKE: Stopping pad \(i) (same group)")
                        player.stop()
                    }
                }
            }
        }
        
        if isDown {
            // Start playback
            print("✅ AUDIO TRIGGER: Starting playback for pad \(index)")
            print("🎵 PLAYER STATE: mode=\(config.playbackMode), choke=\(config.chokeGroup)")
            
            player.volume = config.gain
            
            print("🎵 STOPPING PLAYER...")
            player.stop()
            
            print("🎵 STARTING PLAYBACK...")
            player.play()
            
            print("🎵 PLAYBACK RESULT: isPlaying=\(player.isPlaying)")
            
            activePad = index
            
            // Additional verification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🎵 PLAYBACK CHECK: isPlaying=\(player.isPlaying) after 100ms")
            }
        } else {
            // Gate mode - stop on finger up (only for gate mode)
            if config.playbackMode == .gate {
                print("🎵 GATE: Stopping pad \(index) on finger up")
                player.stop()
                if activePad == index {
                    activePad = nil
                }
            }
        }
    }
    
    /// Release pad (finger up)
    func releasePad(_ index: Int) {
        guard let config = padConfigs[index], config.playbackMode == .gate else {
            return
        }
        triggerPad(index, isDown: false)
    }

    func selfTestPads() {
        print("🔔 SELF TEST: Starting pad test sequence...")
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                print("🔔 SELF TEST: Testing pad \(i)")
                self?.triggerPad(i)
            }
        }
    }
    
    func testSinglePad(_ index: Int) {
        print("🔔 SINGLE TEST: Testing pad \(index)")
        triggerPad(index)
    }

    // MARK: Manual Engine Control
    func forceStartEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.0029)
            try session.setActive(true)
            
            // Only build graph if not already started
            if !started {
                engine.output = mainMixer
                for mixer in padMixers {
                    mainMixer.addInput(mixer)
                }
                
                try engine.start()
                started = true
                print("🔊 Engine force-started successfully")
                
                // Try to reload bundled samples
                preloadBundledPads()
            } else {
                print("🔊 Engine already started")
            }
            
        } catch {
            print("🛑 Force start failed:", error)
        }
    }

    // MARK: Debug methods
    func debugAudioSession() {
        let session = AVAudioSession.sharedInstance()
        print("🔍 AUDIO SESSION DEBUG:")
        print("🔍 Category: \(session.category)")
        print("🔍 Mode: \(session.mode)")
        print("🔍 Options: \(session.categoryOptions)")
        print("🔍 Sample Rate: \(session.sampleRate)")
        print("🔍 IO Buffer Duration: \(session.ioBufferDuration)")
        print("🔍 Output Route: \(session.currentRoute.outputs.first?.portType.rawValue ?? "unknown")")
        print("🔍 Engine Started: \(started)")
        print("🔍 Main Mixer Volume: \(mainMixer.volume)")
        
        for (i, mixer) in padMixers.enumerated() {
            print("🔍 Pad \(i) Mixer Volume: \(mixer.volume)")
            print("🔍 Pad \(i) Player Exists: \(padPlayers[i] != nil)")
            print("🔍 Pad \(i) Buffer Exists: \(padBuffers[i] != nil)")
            if let player = padPlayers[i] {
                print("🔍 Pad \(i) Player Volume: \(player.volume)")
                print("🔍 Pad \(i) Player Has Engine: \(player.avAudioNode.engine != nil)")
            }
        }
    }
    
    func repairAudioEngine() {
        print("🔧 Attempting to repair audio engine...")
        
        // Stop and restart engine
        if started {
            engine.stop()
            started = false
        }
        
        // Restart engine
        do {
            try engine.start()
            started = true
            print("✅ Audio engine repaired and restarted")
        } catch {
            print("🛑 Failed to restart engine after repair:", error)
        }
    }

    // MARK: Debug tone
    func testBeep(duration: Double = 0.25) {
        if !started { 
            print("🛑 Test beep: audio engine not started")
            return 
        }
        
        let osc = Oscillator(frequency: 880, amplitude: 0.2) // A5
        mainMixer.addInput(osc)
        osc.start()
        print("🔊 Test beep started")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            osc.stop()
            self?.mainMixer.removeInput(osc)
            print("🔊 Test beep stopped")
        }
    }
}