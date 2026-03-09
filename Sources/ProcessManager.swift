import Foundation

class ProcessManager {
    private var process: Process?
    private let binaryPath = "/Library/NDI SDK for Apple/bin/Application.NDI.FreeAudio"

    var isRunning: Bool { process?.isRunning ?? false }

    func startListening(source: String, outputDevice: String) {
        let args = ["-output", outputDevice, "-output_name", source]
        launch(arguments: args)
    }

    func startBroadcasting(inputDevice: String, ndiName: String?) {
        var args = ["-input", inputDevice]
        if let name = ndiName, !name.isEmpty {
            args += ["-input_name", name]
        }
        launch(arguments: args)
    }

    func stop() {
        process?.terminate()
        process?.waitUntilExit()
        process = nil
    }

    private func launch(arguments: [String]) {
        stop()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = arguments
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            process = proc
        } catch {
            // silently fail
        }
    }
}
