import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ViewerViewModel

    var body: some View {
        NavigationSplitView {
            channelSidebar
        } detail: {
            waveformPane
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Open EDF/BDF") {
                    openFilePicker()
                }
                Button("Zoom In") {
                    Task { await viewModel.zoom(by: 0.7, pixelWidth: 1400) }
                }
                Button("Zoom Out") {
                    Task { await viewModel.zoom(by: 1.3, pixelWidth: 1400) }
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var channelSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let url = viewModel.openedFileURL {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
            } else {
                Text("No file selected")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            List(viewModel.channels, selection: Binding(
                get: { viewModel.selectedChannelID },
                set: { newValue in
                    guard let id = newValue else { return }
                    Task { await viewModel.selectChannel(id, pixelWidth: 1400) }
                })
            ) { channel in
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.label)
                        .font(.body)
                    Text("\(Int(channel.sampleRateHz)) Hz • \(channel.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Spacer()
        }
        .padding(12)
    }

    private var waveformPane: some View {
        VStack(spacing: 8) {
            HStack {
                Text("t = \(viewModel.visibleStartSeconds, specifier: "%.2f")s, window = \(viewModel.visibleDurationSeconds, specifier: "%.2f")s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("←") { Task { await viewModel.pan(by: -viewModel.visibleDurationSeconds * 0.25, pixelWidth: 1400) } }
                Button("→") { Task { await viewModel.pan(by: viewModel.visibleDurationSeconds * 0.25, pixelWidth: 1400) } }
            }

            WaveformMinMaxView(waveform: viewModel.waveform)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "edf") ?? .data,
            UTType(filenameExtension: "bdf") ?? .data
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.openFile(url: url)
        }
    }
}

#Preview {
    ContentView(viewModel: ViewerViewModel())
}
