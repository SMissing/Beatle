import SwiftUI

struct MPCPadCard: View {
    @Environment(\.beatle) private var T
    @EnvironmentObject private var store: PadStore

    let pad: Pad
    let size: CGFloat
    let isEditing: Bool
    @State private var showPicker = false

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
                       AudioEngineService.shared.triggerPad(pad.id)
                   })
                .contentShape(Rectangle())
                .allowsHitTesting(!isEditing)   // 🔑 disable touch on front when editing
                .zIndex(isEditing ? 0 : 1)      // front only on top when not editing
                .onAppear {
                    print("🔍 MPCPad FRONT: appeared, isEditing=\(isEditing), allowsHitTesting=\(!isEditing)")
                }
                .opacity(isEditing ? 0 : 1)
                .rotation3DEffect(.degrees(isEditing ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0))
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

            // BACK (loader face)
            BeatlePanel {
                VStack(spacing: 10) {
                    Text(pad.name)
                        .font(BeatleFont.label)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(T.textSecondary)

                    HStack(spacing: 10) {
                        Button(pad.hasSample ? "Replace" : "Load from Files") {
                            showPicker = true
                        }
                        .buttonStyle(.beatle(accent: pad.accent))

                        if pad.hasSample {
                            Button("Clear") { store.clearSample(for: pad.id) }
                                .buttonStyle(.beatle(accent: T.keycapAlt))
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .allowsHitTesting(isEditing)     // 🔑 enable touch on back when editing
            .zIndex(isEditing ? 1 : 0)      // back on top when editing
            .onAppear {
                print("🔍 MPCPad BACK: appeared, isEditing=\(isEditing), allowsHitTesting=\(isEditing)")
            }
            .rotation3DEffect(.degrees(isEditing ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .opacity(isEditing ? 1 : 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isEditing)
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



