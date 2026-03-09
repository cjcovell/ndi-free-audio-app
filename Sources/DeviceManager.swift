import Foundation

struct DeviceManager {
    let inputDevices: [String]
    let outputDevices: [String]

    init() {
        let binaryPath = "/Library/NDI SDK for Apple/bin/Application.NDI.FreeAudio"
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = ["--help"]
        proc.standardOutput = pipe
        proc.standardError = pipe
        try? proc.run()
        proc.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        var inputs: [String] = []
        var outputs: [String] = []
        var section = ""

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "Input Devices:" {
                section = "input"
                continue
            } else if trimmed == "Output Devices:" {
                section = "output"
                continue
            } else if trimmed.isEmpty {
                section = ""
                continue
            }

            if section == "input" || section == "output" {
                // Format: "    N : Device Name "
                if let colonRange = line.range(of: " : ") {
                    var device = String(line[colonRange.upperBound...])
                        .trimmingCharacters(in: .whitespaces)
                    // Strip "[default]" annotation — it's not part of the actual device name
                    if device.hasSuffix("[default]") {
                        device = device.replacingOccurrences(of: " [default]", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    }
                    if !device.isEmpty {
                        if section == "input" {
                            inputs.append(device)
                        } else {
                            outputs.append(device)
                        }
                    }
                }
            }
        }

        inputDevices = inputs
        outputDevices = outputs
    }
}
