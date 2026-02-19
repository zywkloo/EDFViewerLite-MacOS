import Foundation

struct ChannelInfo: Identifiable, Hashable {
    let id: Int
    let label: String
    let sampleRateHz: Double
    let unit: String
}

struct WaveformWindow {
    let startSeconds: Double
    let durationSeconds: Double
    let samples: [Float]
}

struct DownsampledWaveform {
    let mins: [Float]
    let maxs: [Float]
}
