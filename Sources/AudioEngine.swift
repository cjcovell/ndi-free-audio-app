import AVFoundation
import CoreAudio

class AudioEngine {
    private var engine: AVAudioEngine?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func startMetering(inputDeviceName: String) {
        stopMetering()

        engine = AVAudioEngine()
        guard let engine = engine else { return }

        // Try to set the input device by name
        if let deviceID = findAudioDevice(named: inputDeviceName, isInput: true) {
            let inputUnit = engine.inputNode.audioUnit!
            var devID = deviceID
            AudioUnitSetProperty(
                inputUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global, 0,
                &devID, UInt32(MemoryLayout<AudioDeviceID>.size)
            )
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let levels = self.computeLevels(buffer: buffer)
            DispatchQueue.main.async { [weak self] in
                self?.appState?.updateLevelsWithPeakHold(levels)
            }
        }

        do {
            try engine.start()
        } catch {
            self.engine = nil
        }
    }

    func stopMetering() {
        if let engine = engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        DispatchQueue.main.async { [weak self] in
            self?.appState?.audioLevels = .silence
        }
    }

    private func computeLevels(buffer: AVAudioPCMBuffer) -> AudioLevels {
        let channels = Int(buffer.format.channelCount)
        let frames = Int(buffer.frameLength)
        guard let floatData = buffer.floatChannelData, channels > 0, frames > 0 else {
            return .silence
        }

        var rms = [Float](repeating: -60, count: channels)
        var peak = [Float](repeating: -60, count: channels)

        for ch in 0..<channels {
            var sumSquares: Float = 0
            var maxAbs: Float = 0
            let channelData = floatData[ch]
            for s in 0..<frames {
                let sample = channelData[s]
                sumSquares += sample * sample
                let absSample = Swift.abs(sample)
                if absSample > maxAbs { maxAbs = absSample }
            }
            let rmsLinear = sqrt(sumSquares / Float(frames))
            rms[ch] = 20.0 * log10(max(rmsLinear, 1e-10))
            peak[ch] = 20.0 * log10(max(maxAbs, 1e-10))
        }

        return AudioLevels(rms: rms, peak: peak, peakHold: peak, channelCount: channels)
    }

    private func findAudioDevice(named name: String, isInput: Bool) -> AudioDeviceID? {
        var propAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propAddress, 0, nil, &dataSize
        )

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propAddress, 0, nil, &dataSize, &devices
        )

        for device in devices {
            var nameSize: UInt32 = 0
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectGetPropertyDataSize(device, &nameAddress, 0, nil, &nameSize)

            var cfName: Unmanaged<CFString>?
            AudioObjectGetPropertyData(device, &nameAddress, 0, nil, &nameSize, &cfName)
            let deviceName = cfName?.takeRetainedValue() as String? ?? ""

            if deviceName == name {
                // Verify it's actually an input/output device
                let scope: AudioObjectPropertyScope = isInput
                    ? kAudioDevicePropertyScopeInput
                    : kAudioDevicePropertyScopeOutput
                var streamAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreams,
                    mScope: scope,
                    mElement: kAudioObjectPropertyElementMain
                )
                var streamSize: UInt32 = 0
                AudioObjectGetPropertyDataSize(device, &streamAddress, 0, nil, &streamSize)
                if streamSize > 0 { return device }
            }
        }

        return nil
    }
}
