import Foundation

enum SignalProcessing {
    static func downsampleMinMax(_ samples: [Float], bucketCount: Int) -> DownsampledWaveform {
        guard !samples.isEmpty, bucketCount > 0 else {
            return DownsampledWaveform(mins: [], maxs: [])
        }

        let step = max(1, samples.count / bucketCount)
        var mins: [Float] = []
        var maxs: [Float] = []
        mins.reserveCapacity(bucketCount)
        maxs.reserveCapacity(bucketCount)

        var index = 0
        while index < samples.count {
            let end = min(samples.count, index + step)
            var minValue = samples[index]
            var maxValue = samples[index]

            if index + 1 < end {
                for value in samples[(index + 1)..<end] {
                    minValue = min(minValue, value)
                    maxValue = max(maxValue, value)
                }
            }

            mins.append(minValue)
            maxs.append(maxValue)
            index = end
        }

        return DownsampledWaveform(mins: mins, maxs: maxs)
    }
}
