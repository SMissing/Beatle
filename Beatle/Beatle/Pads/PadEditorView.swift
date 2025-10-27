import SwiftUI

struct PadEditorView: View {
    @Binding var pad: Pad
    @Environment(\.beatle) private var T
    @EnvironmentObject private var store: PadStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSamplePicker = false
    @State private var selectedColorHex: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text(pad.name)
                        .font(BeatleFont.title)
                        .foregroundStyle(T.textPrimary)
                    Spacer()
                    Button("Done") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                    .buttonStyle(.beatle(accent: T.keycap))
                }
                
                // Waveform preview
                if pad.hasSample, let url = pad.storedURL {
                    WaveformPreview(url: url)
                        .frame(height: 80)
                        .background(T.surfaceAlt)
                        .cornerRadius(12)
                }
                
                // Sample controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sample")
                        .font(BeatleFont.headline)
                        .foregroundStyle(T.textPrimary)
                    
                    HStack(spacing: 12) {
                        Button("Replace") {
                            showSamplePicker = true
                        }
                        .buttonStyle(.beatle(accent: T.coral))
                        .frame(maxWidth: .infinity)
                        
                        Button("Clear") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            store.clearSample(for: pad.id)
                        }
                        .buttonStyle(.beatle(accent: T.keycapAlt))
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            pad.isFavourite.toggle()
                            store.updatePad(pad)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: pad.isFavourite ? "star.fill" : "star")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.beatle(accent: pad.isFavourite ? T.coral : T.keycapAlt))
                    }
                }
                .padding(.vertical, 16)
                
                Divider()
                    .foregroundStyle(T.stroke)
                
                // Playback mode
                VStack(alignment: .leading, spacing: 12) {
                    Text("Playback Mode")
                        .font(BeatleFont.headline)
                        .foregroundStyle(T.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([PlaybackMode.oneShot, PlaybackMode.gate], id: \.self) { mode in
                            Button {
                                pad.playbackMode = mode
                                store.updatePad(pad)
                                AudioEngineService.shared.updatePadConfig(
                                    id: pad.id,
                                    playbackMode: pad.playbackMode,
                                    chokeGroup: pad.chokeGroup,
                                    gain: pad.gain,
                                    pitch: pad.pitch
                                )
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(mode == .oneShot ? "One-shot" : "Gate")
                                    .font(BeatleFont.label)
                            }
                            .buttonStyle(.beatle(accent: pad.playbackMode == mode ? T.coral : T.keycapAlt))
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Divider()
                    .foregroundStyle(T.stroke)
                
                // Choke group
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choke Group")
                        .font(BeatleFont.headline)
                        .foregroundStyle(T.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([0, 1, 2, 3, 4], id: \.self) { group in
                            Button {
                                pad.chokeGroup = group
                                store.updatePad(pad)
                                AudioEngineService.shared.updatePadConfig(
                                    id: pad.id,
                                    playbackMode: pad.playbackMode,
                                    chokeGroup: pad.chokeGroup,
                                    gain: pad.gain,
                                    pitch: pad.pitch
                                )
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(group == 0 ? "None" : "\(group)")
                                    .font(BeatleFont.label)
                            }
                            .buttonStyle(.beatle(accent: pad.chokeGroup == group ? T.coral : T.keycapAlt))
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Divider()
                    .foregroundStyle(T.stroke)
                
                // Gain
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Gain")
                            .font(BeatleFont.headline)
                            .foregroundStyle(T.textPrimary)
                        Spacer()
                        Text(String(format: "%.2f", pad.gain))
                            .font(BeatleFont.label)
                            .foregroundStyle(T.textSecondary)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(pad.gain) },
                        set: { newValue in
                            pad.gain = Float(newValue.clamped(to: 0.0...1.5))
                            store.updatePad(pad)
                            AudioEngineService.shared.updatePadConfig(
                                id: pad.id,
                                playbackMode: pad.playbackMode,
                                chokeGroup: pad.chokeGroup,
                                gain: pad.gain,
                                pitch: pad.pitch
                            )
                        }
                    ), in: 0...1.5)
                    .tint(T.coral)
                }
                
                // Pitch
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Pitch")
                            .font(BeatleFont.headline)
                            .foregroundStyle(T.textPrimary)
                        Spacer()
                        Text(pad.pitch >= 0 ? "+\(pad.pitch)" : "\(pad.pitch)")
                            .font(BeatleFont.label)
                            .foregroundStyle(T.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Button("-12") {
                            pad.pitch = max(-12, pad.pitch - 12)
                            store.updatePad(pad)
                            AudioEngineService.shared.updatePadConfig(
                                id: pad.id,
                                playbackMode: pad.playbackMode,
                                chokeGroup: pad.chokeGroup,
                                gain: pad.gain,
                                pitch: pad.pitch
                            )
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .buttonStyle(.beatle(accent: T.keycapAlt))
                        
                        Button("−") {
                            pad.pitch = max(-12, pad.pitch - 1)
                            store.updatePad(pad)
                            AudioEngineService.shared.updatePadConfig(
                                id: pad.id,
                                playbackMode: pad.playbackMode,
                                chokeGroup: pad.chokeGroup,
                                gain: pad.gain,
                                pitch: pad.pitch
                            )
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .buttonStyle(.beatle(accent: T.keycapAlt))
                        
                        Text("\(pad.pitch)")
                            .font(BeatleFont.label)
                            .foregroundStyle(T.textPrimary)
                            .frame(maxWidth: .infinity)
                        
                        Button("+") {
                            pad.pitch = min(12, pad.pitch + 1)
                            store.updatePad(pad)
                            AudioEngineService.shared.updatePadConfig(
                                id: pad.id,
                                playbackMode: pad.playbackMode,
                                chokeGroup: pad.chokeGroup,
                                gain: pad.gain,
                                pitch: pad.pitch
                            )
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .buttonStyle(.beatle(accent: T.keycapAlt))
                        
                        Button("+12") {
                            pad.pitch = min(12, pad.pitch + 12)
                            store.updatePad(pad)
                            AudioEngineService.shared.updatePadConfig(
                                id: pad.id,
                                playbackMode: pad.playbackMode,
                                chokeGroup: pad.chokeGroup,
                                gain: pad.gain,
                                pitch: pad.pitch
                            )
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .buttonStyle(.beatle(accent: T.keycapAlt))
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                
                Divider()
                    .foregroundStyle(T.stroke)
                
                // Color picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pad Colour")
                        .font(BeatleFont.headline)
                        .foregroundStyle(T.textPrimary)
                    
                    BeatleColorPicker(selectedHex: $selectedColorHex)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(T.surface)
        .onChange(of: selectedColorHex) { _, newValue in
            pad.accentHex = newValue
            store.updatePad(pad)
            AudioEngineService.shared.updatePadConfig(
                id: pad.id,
                playbackMode: pad.playbackMode,
                chokeGroup: pad.chokeGroup,
                gain: pad.gain,
                pitch: pad.pitch
            )
        }
        .sheet(isPresented: $showSamplePicker) {
            SingleDocumentPicker { url in
                store.importSample(for: pad.id, from: url)
            }
        }
    }
    
    init(pad: Binding<Pad>) {
        self._pad = pad
        self._selectedColorHex = State(initialValue: pad.wrappedValue.accentHex)
    }
}

private struct WaveformPreview: View {
    let url: URL
    @State private var waveform: [Float] = []
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let midY = height / 2
                let step = width / CGFloat(max(1, waveform.count))
                
                for (index, value) in waveform.enumerated() {
                    let x = CGFloat(index) * step
                    let barHeight = CGFloat(value) * midY
                    path.move(to: CGPoint(x: x, y: midY - barHeight))
                    path.addLine(to: CGPoint(x: x, y: midY + barHeight))
                }
            }
            .stroke(Color.primary, lineWidth: 1)
        }
        .task {
            waveform = await WaveformPreviewer.waveform(for: url)
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

