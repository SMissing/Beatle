import SwiftUI

struct MPCPadCard: View {
    @Environment(\.beatle) private var T
    @EnvironmentObject private var store: PadStore

    let pad: Pad
    let size: CGFloat
    let isEditing: Bool
    let onEditTap: (() -> Void)?
    @State private var showPicker = false
    
    init(pad: Pad, size: CGFloat, isEditing: Bool, onEditTap: (() -> Void)? = nil) {
        self.pad = pad
        self.size = size
        self.isEditing = isEditing
        self.onEditTap = onEditTap
    }

    var body: some View {
        ZStack {
            // FRONT  — disable touch when editing, enable when not editing
            MPCPad(size: size,
                   accent: pad.accent,
                   isActive: pad.hasSample,
                   action: {
                       print("🎯 PAD PRESSED: Pad \(pad.id) tapped")
                       print("🎯 PAD STATE: hasSample=\(pad.hasSample), storedURL=\(pad.storedURL?.lastPathComponent ?? "nil")")
                       guard pad.hasSample else { 
                           print("❌ PAD PRESSED: No sample loaded for pad \(pad.id)")
                           return 
                       }
                       print("✅ PAD PRESSED: Sample exists, triggering audio...")
                       
                       // Update engine with current pad config
                       AudioEngineService.shared.updatePadConfig(
                           id: pad.id,
                           playbackMode: pad.playbackMode,
                           chokeGroup: pad.chokeGroup,
                           gain: pad.gain,
                           pitch: pad.pitch
                       )
                       
                       AudioEngineService.shared.triggerPad(pad.id, isDown: true)
                   },
                   releaseAction: {
                       // Gate mode - release on finger up
                       if pad.playbackMode == .gate {
                           print("🎯 PAD RELEASED: Stopping gate playback for pad \(pad.id)")
                           AudioEngineService.shared.releasePad(pad.id)
                       }
                   })
                .contentShape(Rectangle())
                .allowsHitTesting(!isEditing)   // 🔑 disable touch on front when editing
                .zIndex(isEditing ? 0 : 1)      // front only on top when not editing
                .onAppear {
                    print("🔍 MPCPad FRONT: appeared, isEditing=\(isEditing), allowsHitTesting=\(!isEditing)")
                }
                .opacity(isEditing ? 0 : 1)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(pad.hasSample ? pad.accent.opacity(0.9) : Color.clear)
                    .frame(width: 8, height: 8)
                    .padding(8)
            }
            .overlay {
                if !pad.hasSample {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.10))
                }
            }

            // BACK (edit face)
            BeatlePanel {
                VStack(spacing: 10) {
                    Text(pad.name)
                        .font(BeatleFont.label)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(T.textSecondary)
                    
                    // Show mode and choke group
                    HStack(spacing: 6) {
                        if pad.hasSample {
                            Text(pad.playbackMode == .oneShot ? "OS" : "GT")
                                .font(BeatleFont.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(T.surface)
                                .cornerRadius(4)
                            
                            if pad.chokeGroup > 0 {
                                Text("C\(pad.chokeGroup)")
                                    .font(BeatleFont.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(T.surface)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Color dot
                    Circle()
                        .fill(pad.accent)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(width: size, height: size)
            .allowsHitTesting(isEditing)
            .zIndex(isEditing ? 1 : 0)
            .onTapGesture {
                if pad.hasSample {
                    onEditTap?()
                } else {
                    showPicker = true
                }
            }
            .opacity(isEditing ? 1 : 0)
        }
        .animation(nil, value: isEditing)
        .sheet(isPresented: $showPicker) {
            SingleDocumentPicker { url in
                store.importSample(for: pad.id, from: url)
            }
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            print("🔍 MPCPadCard appeared for pad \(pad.id) - hasSample: \(pad.hasSample), storedURL: \(pad.storedURL?.lastPathComponent ?? "nil")")
        }
        .onChange(of: pad.hasSample) { _, newValue in
            print("🔄 MPCPadCard pad \(pad.id) hasSample changed to: \(newValue)")
        }
    }
}



