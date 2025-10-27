import SwiftUI

struct LibraryTabView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.beatle) private var T
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Library")
                    .font(BeatleFont.title)
                    .foregroundStyle(T.textPrimary)
                Spacer()
                Button {
                    // Import action
                    viewModel.showImportPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(T.coral)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            // Segmented Control
            Picker("View", selection: $viewModel.selectedView) {
                ForEach(LibraryView.allCases, id: \.self) { view in
                    Text(view.rawValue).tag(view)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            // Content
            if viewModel.isImporting {
                ProgressView("Importing...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch viewModel.selectedView {
                case .folders:
                    FoldersListView(viewModel: viewModel)
                default:
                    SamplesListView(viewModel: viewModel)
                }
            }
        }
        .background(T.surface)
        .sheet(isPresented: $viewModel.showImportPicker) {
            MultiDocumentPicker { urls in
                Task {
                    await viewModel.importFiles(urls)
                }
            }
        }
    }
}

private struct SamplesListView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.beatle) private var T
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.currentSamples) { sample in
                    SampleRow(sample: sample) {
                        viewModel.toggleStar(for: sample)
                    } onDelete: {
                        viewModel.deleteSample(sample)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct FoldersListView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.beatle) private var T
    @State private var showCreateFolder = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.folders) { folder in
                    FolderRow(folder: folder)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct SampleRow: View {
    let sample: Sample
    let onToggleStar: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.beatle) private var T
    @State private var waveform: [Float] = []
    
    var body: some View {
        HStack(spacing: 12) {
            // Waveform preview
            WaveformView(waveform: waveform)
                .frame(width: 60, height: 30)
                .task {
                    waveform = await WaveformPreviewer.waveform(for: sample)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sample.name)
                    .font(BeatleFont.label)
                    .foregroundStyle(T.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formatDuration(sample.duration))
                        .font(BeatleFont.caption)
                        .foregroundStyle(T.textSecondary)
                    Text("•")
                        .font(BeatleFont.caption)
                        .foregroundStyle(T.textSecondary)
                    Text("48kHz Mono")
                        .font(BeatleFont.caption)
                        .foregroundStyle(T.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                onToggleStar()
            } label: {
                Image(systemName: sample.isStarred ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundStyle(sample.isStarred ? T.coral : T.textSecondary)
            }
        }
        .padding(12)
        .background(T.surfaceAlt)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct FolderRow: View {
    let folder: SampleFolder
    
    @Environment(\.beatle) private var T
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .font(.system(size: 20))
                .foregroundStyle(T.teal)
            
            Text(folder.name)
                .font(BeatleFont.label)
                .foregroundStyle(T.textPrimary)
            
            Spacer()
            
            Text("\(folder.sampleIds.count)")
                .font(BeatleFont.caption)
                .foregroundStyle(T.textSecondary)
        }
        .padding(12)
        .background(T.surfaceAlt)
        .cornerRadius(12)
    }
}

private struct WaveformView: View {
    let waveform: [Float]
    
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
            .stroke(Color.accentColor, lineWidth: 1)
        }
    }
}

