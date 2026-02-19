import SwiftUI

struct WaveformMinMaxView: View {
    let waveform: DownsampledWaveform

    var body: some View {
        Canvas { context, size in
            guard !waveform.mins.isEmpty, waveform.mins.count == waveform.maxs.count else { return }

            let minValue = waveform.mins.min() ?? -1
            let maxValue = waveform.maxs.max() ?? 1
            let span = max(0.001, maxValue - minValue)

            let xStep = size.width / CGFloat(waveform.mins.count)
            var path = Path()

            for i in waveform.mins.indices {
                let x = CGFloat(i) * xStep
                let top = size.height * (1 - CGFloat((waveform.maxs[i] - minValue) / span))
                let bottom = size.height * (1 - CGFloat((waveform.mins[i] - minValue) / span))
                path.move(to: CGPoint(x: x, y: top))
                path.addLine(to: CGPoint(x: x, y: bottom))
            }

            context.stroke(path, with: .color(.accentColor), lineWidth: 1)
        }
        .drawingGroup()
    }
}
