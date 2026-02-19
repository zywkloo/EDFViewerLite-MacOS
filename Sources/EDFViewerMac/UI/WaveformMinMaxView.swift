import SwiftUI

struct WaveformMinMaxView: View {
    let waveform: DownsampledWaveform
    let showGrid: Bool
    let startSeconds: Double
    let durationSeconds: Double
    let unit: String

    var body: some View {
        Canvas { context, size in
            guard !waveform.mins.isEmpty, waveform.mins.count == waveform.maxs.count else { return }

            let minValue = waveform.mins.min() ?? -1
            let maxValue = waveform.maxs.max() ?? 1
            // Ensure a minimum visible range so flat data shows as a centered line
            let rawSpan = maxValue - minValue
            let span: Float
            let adjustedMin: Float
            if rawSpan < 0.001 {
                let center = (minValue + maxValue) / 2
                span = max(1.0, abs(center) * 0.1)
                adjustedMin = center - span / 2
            } else {
                span = rawSpan
                adjustedMin = minValue
            }

            // Draw grid if enabled
            if showGrid {
                drawGrid(context: &context, size: size, minValue: adjustedMin, span: span)
            }

            // Draw waveform as connected min/max envelope + midline
            let count = waveform.mins.count
            let xStep = size.width / CGFloat(count)

            func yFor(_ value: Float) -> CGFloat {
                size.height * (1 - CGFloat((value - adjustedMin) / span))
            }

            // Fill the min/max envelope
            var envelope = Path()
            // Forward along maxs (top edge)
            envelope.move(to: CGPoint(x: 0, y: yFor(waveform.maxs[0])))
            for i in 1..<count {
                envelope.addLine(to: CGPoint(x: CGFloat(i) * xStep, y: yFor(waveform.maxs[i])))
            }
            // Backward along mins (bottom edge)
            for i in stride(from: count - 1, through: 0, by: -1) {
                envelope.addLine(to: CGPoint(x: CGFloat(i) * xStep, y: yFor(waveform.mins[i])))
            }
            envelope.closeSubpath()
            context.fill(envelope, with: .color(.accentColor.opacity(0.3)))

            // Stroke the midline connecting midpoints
            var midline = Path()
            let firstMid = (waveform.mins[0] + waveform.maxs[0]) / 2
            midline.move(to: CGPoint(x: 0, y: yFor(firstMid)))
            for i in 1..<count {
                let mid = (waveform.mins[i] + waveform.maxs[i]) / 2
                midline.addLine(to: CGPoint(x: CGFloat(i) * xStep, y: yFor(mid)))
            }
            context.stroke(midline, with: .color(.accentColor), lineWidth: 1)
        }
        .drawingGroup()
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize, minValue: Float, span: Float) {
        let gridColor = Color.gray.opacity(0.3)
        let labelColor = Color.gray.opacity(0.7)

        // Horizontal grid lines (amplitude)
        let hLineCount = 5
        for i in 0...hLineCount {
            let fraction = CGFloat(i) / CGFloat(hLineCount)
            let y = size.height * fraction
            let value = minValue + span * Float(1 - fraction)

            var hPath = Path()
            hPath.move(to: CGPoint(x: 0, y: y))
            hPath.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(hPath, with: .color(gridColor), lineWidth: 0.5)

            let label = formatValue(value, unit: unit)
            let text = Text(label).font(.system(size: 9)).foregroundColor(labelColor)
            context.draw(context.resolve(text), at: CGPoint(x: 4, y: y - 6), anchor: .topLeading)
        }

        // Vertical grid lines (time)
        let vLineCount = max(1, Int(durationSeconds))
        let timeStep = durationSeconds / Double(vLineCount)
        for i in 0...vLineCount {
            let fraction = CGFloat(Double(i) * timeStep / durationSeconds)
            let x = size.width * fraction

            var vPath = Path()
            vPath.move(to: CGPoint(x: x, y: 0))
            vPath.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(vPath, with: .color(gridColor), lineWidth: 0.5)

            let t = startSeconds + Double(i) * timeStep
            let label = String(format: "%.1fs", t)
            let text = Text(label).font(.system(size: 9)).foregroundColor(labelColor)
            context.draw(context.resolve(text), at: CGPoint(x: x + 2, y: size.height - 14), anchor: .topLeading)
        }
    }

    private func formatValue(_ value: Float, unit: String) -> String {
        if abs(value) >= 100 {
            return String(format: "%.0f %@", value, unit)
        } else if abs(value) >= 1 {
            return String(format: "%.1f %@", value, unit)
        } else {
            return String(format: "%.3f %@", value, unit)
        }
    }
}
