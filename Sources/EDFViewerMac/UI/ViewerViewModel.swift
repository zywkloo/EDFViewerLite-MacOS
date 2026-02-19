import Foundation

@MainActor
final class ViewerViewModel: ObservableObject {
    @Published var channels: [ChannelInfo] = []
    @Published var selectedChannelID: Int?
    @Published var waveform: DownsampledWaveform = .init(mins: [], maxs: [])
    @Published var openedFileURL: URL?
    @Published var errorMessage: String?
    @Published var showGrid: Bool = true
    @Published var debugInfo: String = ""

    @Published var visibleStartSeconds: Double = 0
    @Published var visibleDurationSeconds: Double = 10

    private var reader: EDFReading?
    private let makeReader: (URL) throws -> EDFReading

    init(makeReader: @escaping (URL) throws -> EDFReading = RealEDFReader.init) {
        self.makeReader = makeReader
    }

    var selectedChannelUnit: String {
        guard let id = selectedChannelID,
              let ch = channels.first(where: { $0.id == id }) else { return "" }
        return ch.unit
    }

    func openFile(url: URL) {
        Task {
            do {
                let createdReader = try makeReader(url)
                reader = createdReader
                channels = createdReader.channels
                selectedChannelID = createdReader.channels.first?.id
                openedFileURL = url
                visibleStartSeconds = 0
                visibleDurationSeconds = min(10, createdReader.fileDurationSeconds)
                errorMessage = nil
                debugInfo = "duration=\(createdReader.fileDurationSeconds)s, \(createdReader.channels.count)ch"
                await refreshWaveform(pixelWidth: 1400)
            } catch {
                errorMessage = "Failed to open EDF/BDF file: \(error.localizedDescription)"
                debugInfo = "OPEN ERROR: \(error)"
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
            debugInfo = "no reader or channel"
            return
        }

        do {
            let window = try await reader.readWindow(
                channelID: channelID,
                startSeconds: visibleStartSeconds,
                durationSeconds: visibleDurationSeconds
            )

            let ds = SignalProcessing.downsampleMinMax(window.samples, bucketCount: max(10, pixelWidth))
            waveform = ds

            // Debug info
            let sMin = window.samples.min() ?? 0
            let sMax = window.samples.max() ?? 0
            debugInfo = "ch\(channelID): \(window.samples.count) samples, range [\(String(format: "%.2f", sMin)) .. \(String(format: "%.2f", sMax))], ds=\(ds.mins.count) buckets"
            print("[EDF-V] \(debugInfo)")
        } catch {
            errorMessage = "Failed to read signal window: \(error.localizedDescription)"
            debugInfo = "READ ERROR: \(error)"
            print("[EDF-V] READ ERROR: \(error)")
        }
    }
}
