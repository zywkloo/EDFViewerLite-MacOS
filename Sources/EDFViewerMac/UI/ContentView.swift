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
                Toggle("Grid", isOn: $viewModel.showGrid)
                    .toggleStyle(.checkbox)
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

            List(selection: Binding(
                get: { viewModel.allChannelsMode ? nil : viewModel.selectedChannelID },
                set: { newValue in
                    guard let id = newValue else { return }
                    Task { await viewModel.selectChannel(id, pixelWidth: 1400) }
                })
            ) {
                Button {
                    Task { await viewModel.selectAllChannels(pixelWidth: 1400) }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Channels")
                            .font(.body.bold())
                            .foregroundColor(.accentColor)
                        if viewModel.fileDurationSeconds > 0 {
                            Text(formatDuration(viewModel.fileDurationSeconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.allChannelsMode ? Color.accentColor.opacity(0.2) : Color.clear)

                ForEach(viewModel.channels) { channel in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.label)
                            .font(.body)
                        Text("\(Int(channel.sampleRateHz)) Hz \u{2022} \(channel.unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(channel.id)
                }
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
                Text(viewModel.debugInfo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Spacer()
                Button("\u{2190}") { Task { await viewModel.pan(by: -viewModel.visibleDurationSeconds * 0.25, pixelWidth: 1400) } }
                    .disabled(!viewModel.canPanLeft)
                Button("\u{2192}") { Task { await viewModel.pan(by: viewModel.visibleDurationSeconds * 0.25, pixelWidth: 1400) } }
                    .disabled(!viewModel.canPanRight)
            }

            if viewModel.allChannelsMode {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(viewModel.allChannelWaveforms, id: \.channel.id) { entry in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(entry.channel.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                WaveformMinMaxView(
                                    waveform: entry.waveform,
                                    showGrid: viewModel.showGrid,
                                    startSeconds: viewModel.visibleStartSeconds,
                                    durationSeconds: viewModel.visibleDurationSeconds,
                                    unit: entry.channel.unit
                                )
                                .frame(height: 120)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                WaveformMinMaxView(
                    waveform: viewModel.waveform,
                    showGrid: viewModel.showGrid,
                    startSeconds: viewModel.visibleStartSeconds,
                    durationSeconds: viewModel.visibleDurationSeconds,
                    unit: viewModel.selectedChannelUnit
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%dh %02dm %02ds", h, m, s)
        } else if m > 0 {
            return String(format: "%dm %02ds", m, s)
        } else {
            return String(format: "%.1fs", seconds)
        }
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
