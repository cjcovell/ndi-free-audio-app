import SwiftUI

struct AudioMeterView: View {
    var levels: AudioLevels

    private let minDB: Float = -60.0
    private let maxDB: Float = 0.0
    private let barHeight: CGFloat = 10
    private let barSpacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: barSpacing) {
            if levels.channelCount == 0 {
                Text("No audio signal")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(0..<levels.channelCount, id: \.self) { ch in
                    channelMeter(
                        rms: levels.rms[ch],
                        peak: levels.peak[ch],
                        peakHold: levels.peakHold[ch],
                        label: channelLabel(ch)
                    )
                }
            }
        }
    }

    private func channelMeter(rms: Float, peak: Float, peakHold: Float, label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.3))

                    // RMS level bar with gradient
                    RoundedRectangle(cornerRadius: 2)
                        .fill(meterGradient)
                        .frame(width: barWidth(for: rms, in: geo.size.width))

                    // Peak hold indicator
                    if peakHold > minDB {
                        Rectangle()
                            .fill(peakHold > -3 ? Color.red : Color.white.opacity(0.8))
                            .frame(width: 2)
                            .offset(x: barWidth(for: peakHold, in: geo.size.width) - 1)
                    }
                }
            }
            .frame(height: barHeight)

            Text(String(format: "%+.0f", peak))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(peak > -3 ? .red : .secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func barWidth(for db: Float, in totalWidth: CGFloat) -> CGFloat {
        let normalized = (db - minDB) / (maxDB - minDB)
        return CGFloat(max(0, min(1, normalized))) * totalWidth
    }

    private func channelLabel(_ ch: Int) -> String {
        if levels.channelCount == 1 { return "M" }
        if levels.channelCount == 2 { return ch == 0 ? "L" : "R" }
        return "\(ch + 1)"
    }

    private var meterGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .green, .yellow, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
