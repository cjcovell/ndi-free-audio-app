import Foundation
import Combine

enum AppMode: Equatable {
    case idle
    case listening(source: String, outputDevice: String)
    case broadcasting(inputDevice: String, ndiName: String)
}

struct AudioLevels: Equatable {
    var rms: [Float]
    var peak: [Float]
    var peakHold: [Float]
    var channelCount: Int

    static let silence = AudioLevels(rms: [], peak: [], peakHold: [], channelCount: 0)

    /// Returns a copy with only channels that have signal above the threshold
    func activeChannels(threshold: Float = -80) -> AudioLevels {
        guard channelCount > 0 else { return self }
        var activeIndices: [Int] = []
        for ch in 0..<channelCount {
            if peak[ch] > threshold { activeIndices.append(ch) }
        }
        // Always show at least 2 channels
        if activeIndices.isEmpty {
            let count = min(channelCount, 2)
            return AudioLevels(
                rms: Array(rms.prefix(count)),
                peak: Array(peak.prefix(count)),
                peakHold: Array(peakHold.prefix(count)),
                channelCount: count
            )
        }
        return AudioLevels(
            rms: activeIndices.map { rms[$0] },
            peak: activeIndices.map { peak[$0] },
            peakHold: activeIndices.map { peakHold[$0] },
            channelCount: activeIndices.count
        )
    }
}

class AppState: ObservableObject {
    @Published var mode: AppMode = .idle
    @Published var audioLevels: AudioLevels = .silence
    @Published var availableSources: [String] = []
    @Published var inputDevices: [String] = []
    @Published var outputDevices: [String] = []
    @Published var selectedSource: String = ""
    @Published var selectedOutputDevice: String = ""
    @Published var selectedInputDevice: String = ""
    @Published var ndiSourceName: String = ""

    // Action callbacks — set by AppDelegate
    var onStartListening: ((String, String) -> Void)?
    var onStartBroadcasting: ((String, String) -> Void)?
    var onStop: (() -> Void)?

    // Smoothing constants
    private let attackCoeff: Float = 0.6   // fast attack
    private let releaseCoeff: Float = 0.05 // slow release
    private let peakDecayRate: Float = 0.3 // dB per update for peak hold

    func updateLevelsWithPeakHold(_ new: AudioLevels) {
        let count = new.channelCount
        guard count > 0 else { return }

        var smoothedRms = [Float](repeating: -60, count: count)
        var smoothedPeak = [Float](repeating: -60, count: count)
        var peakHold = [Float](repeating: -60, count: count)

        for ch in 0..<count {
            let prevRms = ch < audioLevels.rms.count ? audioLevels.rms[ch] : -60.0
            let prevPeak = ch < audioLevels.peak.count ? audioLevels.peak[ch] : -60.0
            let prevHold = ch < audioLevels.peakHold.count ? audioLevels.peakHold[ch] : -60.0

            // Smooth RMS: fast attack, slow release
            if new.rms[ch] > prevRms {
                smoothedRms[ch] = prevRms + attackCoeff * (new.rms[ch] - prevRms)
            } else {
                smoothedRms[ch] = prevRms + releaseCoeff * (new.rms[ch] - prevRms)
            }

            // Smooth peak similarly
            if new.peak[ch] > prevPeak {
                smoothedPeak[ch] = prevPeak + attackCoeff * (new.peak[ch] - prevPeak)
            } else {
                smoothedPeak[ch] = prevPeak + releaseCoeff * (new.peak[ch] - prevPeak)
            }

            // Peak hold: capture new peaks, slowly decay
            if new.peak[ch] > prevHold {
                peakHold[ch] = new.peak[ch]
            } else {
                peakHold[ch] = prevHold - peakDecayRate
            }
        }

        audioLevels = AudioLevels(
            rms: smoothedRms, peak: smoothedPeak,
            peakHold: peakHold, channelCount: count
        )
    }
}
