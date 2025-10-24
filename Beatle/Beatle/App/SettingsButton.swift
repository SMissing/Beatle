import SwiftUI

struct SettingsButton: View {
    @Environment(\.beatle) private var T
    @EnvironmentObject private var settings: SettingsStore
    @State private var show = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            show = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(T.surfaceAlt)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(T.stroke.opacity(0.35), lineWidth: 1))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $show) { SettingsSheet() }
        .accessibilityLabel("Settings")
    }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.beatle) private var T
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Playback") {
                    Toggle("Keep screen awake", isOn: Binding(
                        get: { settings.keepAwake },
                        set: { settings.keepAwake = $0 }
                    ))
                    .tint(T.coral)
                }
                Section {
                    Text("Beatle uses a single dark theme inspired by MPC Retro.")
                        .foregroundStyle(.secondary)
                        .font(BeatleFont.body)
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Done") { dismiss() } } }
        }
        .useBeatleTheme()
    }
}
