import Foundation

class ProcessManager {
    private var process: Process?
    private let binaryPath = "/Library/NDI SDK for Apple/bin/Application.NDI.FreeAudio"

    var isRunning: Bool { process?.isRunning ?? false }

    /// Start listening to an NDI source, routing audio to a local output device.
    /// CLI flags: -output = local output device, -output_name = NDI source to receive from.
    @discardableResult
    func startListening(source: String, outputDevice: String) -> Bool {
        let args = ["-output", outputDevice, "-output_name", source]
        return launch(arguments: args)
    }

    @discardableResult
    func startBroadcasting(inputDevice: String, ndiName: String?) -> Bool {
        var args = ["-input", inputDevice]
        if let name = ndiName, !name.isEmpty {
            args += ["-input_name", name]
        }
        return launch(arguments: args)
    }

    func stop() {
        process?.terminate()
        process?.waitUntilExit()
        process = nil
    }

    private func launch(arguments: [String]) -> Bool {
        stop()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = arguments
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            process = proc
            return true
        } catch {
            return false
        }
    }
}
