import Foundation

class NDIBridge {
    private var findInstance: NDIlib_find_instance_t?
    private var recvInstance: NDIlib_recv_instance_t?
    private var findThread: Thread?
    private var meterThread: Thread?
    private var meteringStopped = false
    private var findingStopped = false
    private let lock = NSLock()
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
        NDIlib_initialize()
    }

    deinit {
        stopMetering()
        stopFinding()
        NDIlib_destroy()
    }

    // MARK: - Source Discovery

    func startFinding() {
        var createSettings = NDIlib_find_create_t()
        createSettings.show_local_sources = true
        createSettings.p_groups = nil
        createSettings.p_extra_ips = nil

        findInstance = NDIlib_find_create_v2(&createSettings)
        guard findInstance != nil else { return }

        findingStopped = false
        findThread = Thread { [weak self] in
            while let self = self, !self.findingStopped {
                guard let finder = self.findInstance else { break }

                NDIlib_find_wait_for_sources(finder, 1000)

                var count: UInt32 = 0
                let sources = NDIlib_find_get_current_sources(finder, &count)
                var names: [String] = []
                for i in 0..<Int(count) {
                    if let name = sources?[i].p_ndi_name {
                        names.append(String(cString: name))
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    self?.appState?.availableSources = names
                }
            }
        }
        findThread?.start()
    }

    func stopFinding() {
        findingStopped = true
        findThread = nil
        if let finder = findInstance {
            NDIlib_find_destroy(finder)
            findInstance = nil
        }
    }

    // MARK: - Audio Metering via NDI Recv

    func startMetering(sourceName: String) {
        stopMetering()

        // Create source — keep name alive as a Swift string, only borrow the pointer during create
        var source = NDIlib_source_t()
        sourceName.withCString { ptr in
            source.p_ndi_name = ptr
            source.p_url_address = nil

            var recvSettings = NDIlib_recv_create_v3_t()
            recvSettings.source_to_connect_to = source
            recvSettings.color_format = NDIlib_recv_color_format_UYVY_BGRA
            recvSettings.bandwidth = NDIlib_recv_bandwidth_audio_only
            recvSettings.allow_video_fields = true
            recvSettings.p_ndi_recv_name = nil

            recvInstance = NDIlib_recv_create_v3(&recvSettings)
        }

        guard recvInstance != nil else { return }

        meteringStopped = false
        meterThread = Thread { [weak self] in
            while let self = self, !self.meteringStopped {
                self.lock.lock()
                let recv = self.recvInstance
                self.lock.unlock()

                guard let recv = recv else { break }

                var audioFrame = NDIlib_audio_frame_v2_t()
                let frameType = NDIlib_recv_capture_v2(recv, nil, &audioFrame, nil, 100)

                if frameType == NDIlib_frame_type_audio &&
                   audioFrame.no_channels > 0 && audioFrame.p_data != nil {
                    let levels = NDIBridge.computeLevels(frame: audioFrame)
                    DispatchQueue.main.async { [weak self] in
                        self?.appState?.updateLevelsWithPeakHold(levels)
                    }
                    NDIlib_recv_free_audio_v2(recv, &audioFrame)
                }
            }
        }
        meterThread?.start()
    }

    func stopMetering() {
        meteringStopped = true
        // Wait for thread to stop before destroying recv
        meterThread = nil
        Thread.sleep(forTimeInterval: 0.2)

        lock.lock()
        if let recv = recvInstance {
            NDIlib_recv_destroy(recv)
            recvInstance = nil
        }
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.appState?.audioLevels = .silence
        }
    }

    // MARK: - Level Calculation

    static func computeLevels(frame: NDIlib_audio_frame_v2_t) -> AudioLevels {
        let channels = Int(frame.no_channels)
        let samples = Int(frame.no_samples)
        let stride = Int(frame.channel_stride_in_bytes) / MemoryLayout<Float>.size
        guard let data = frame.p_data, channels > 0, samples > 0 else {
            return .silence
        }

        var rms = [Float](repeating: -60, count: channels)
        var peak = [Float](repeating: -60, count: channels)

        for ch in 0..<channels {
            var sumSquares: Float = 0
            var maxAbs: Float = 0
            for s in 0..<samples {
                let sample = data[ch * stride + s]
                sumSquares += sample * sample
                let absSample = abs(sample)
                if absSample > maxAbs { maxAbs = absSample }
            }
            let rmsLinear = sqrt(sumSquares / Float(samples))
            rms[ch] = 20.0 * log10(max(rmsLinear, 1e-10))
            peak[ch] = 20.0 * log10(max(maxAbs, 1e-10))
        }

        return AudioLevels(rms: rms, peak: peak, peakHold: peak, channelCount: channels)
    }
}
