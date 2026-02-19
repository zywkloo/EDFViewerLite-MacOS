import Foundation

@MainActor
final class ViewerViewModel: ObservableObject {
    @Published var channels: [ChannelInfo] = []
    @Published var selectedChannelID: Int?
    @Published var waveform: DownsampledWaveform = .init(mins: [], maxs: [])
    @Published var openedFileURL: URL?
    @Published var errorMessage: String?

    @Published var visibleStartSeconds: Double = 0
    @Published var visibleDurationSeconds: Double = 10

    private var reader: EDFReading?
    private let makeReader: (URL) throws -> EDFReading

    init(makeReader: @escaping (URL) throws -> EDFReading = MockEDFReader.init) {
        self.makeReader = makeReader
    }

    func openFile(url: URL) {
        Task {
            do {
                let createdReader = try makeReader(url)
                reader = createdReader
                channels = createdReader.channels
                selectedChannelID = createdReader.channels.first?.id
                openedFileURL = url
                errorMessage = nil
                await refreshWaveform(pixelWidth: 1400)
            } catch {
                errorMessage = "Failed to open EDF/BDF file: \(error.localizedDescription)"
            }
        }
    }

    func zoom(by factor: Double, pixelWidth: Int) async {
        visibleDurationSeconds = max(0.25, min(60, visibleDurationSeconds * factor))
        await refreshWaveform(pixelWidth: pixelWidth)
    }

    func pan(by deltaSeconds: Double, pixelWidth: Int) async {
        visibleStartSeconds = max(0, visibleStartSeconds + deltaSeconds)
        await refreshWaveform(pixelWidth: pixelWidth)
    }

    func selectChannel(_ id: Int, pixelWidth: Int) async {
        selectedChannelID = id
        await refreshWaveform(pixelWidth: pixelWidth)
    }

    func refreshWaveform(pixelWidth: Int) async {
        guard let reader, let channelID = selectedChannelID else {
            waveform = .init(mins: [], maxs: [])
            return
        }

        do {
            let window = try await reader.readWindow(
                channelID: channelID,
                startSeconds: visibleStartSeconds,
                durationSeconds: visibleDurationSeconds
            )
            waveform = SignalProcessing.downsampleMinMax(window.samples, bucketCount: max(10, pixelWidth))
        } catch {
            errorMessage = "Failed to read signal window: \(error.localizedDescription)"
        }
    }
}
