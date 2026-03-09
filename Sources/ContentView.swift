import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                Text("NDI Free Audio")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Error banner
            if let error = appState.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { appState.errorMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))

                Divider()
            }

            switch appState.mode {
            case .idle:
                idleView
            case .listening(let source, let output):
                activeView(
                    mode: "Listening",
                    icon: "speaker.wave.2.fill",
                    detail: "\(source) → \(output)"
                )
            case .broadcasting(let input, let name):
                activeView(
                    mode: "Broadcasting",
                    icon: "mic.fill",
                    detail: "\(input) as \"\(name)\""
                )
            }
        }
        .frame(width: 280)
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 0) {
            // Listen section
            VStack(alignment: .leading, spacing: 6) {
                Label("Listen to NDI Source", systemImage: "speaker.wave.2")
                    .font(.system(size: 12, weight: .semibold))

                if appState.availableSources.isEmpty {
                    Text("Scanning for sources...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Picker("Source", selection: $appState.selectedSource) {
                        Text("Select source...").tag("")
                        ForEach(appState.availableSources, id: \.self) { source in
                            Text(source).tag(source)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                }

                Picker("Output", selection: $appState.selectedOutputDevice) {
                    Text("Select output...").tag("")
                    ForEach(appState.outputDevices, id: \.self) { device in
                        Text(device).tag(device)
                    }
                }
                .labelsHidden()
                .controlSize(.small)

                Button(action: {
                    appState.onStartListening?(appState.selectedSource, appState.selectedOutputDevice)
                }) {
                    Text("Start Listening")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .disabled(appState.selectedOutputDevice.isEmpty || appState.selectedSource.isEmpty)
            }
            .padding(12)

            Divider()

            // Broadcast section
            VStack(alignment: .leading, spacing: 6) {
                Label("Broadcast Input Device", systemImage: "mic")
                    .font(.system(size: 12, weight: .semibold))

                Picker("Input", selection: $appState.selectedInputDevice) {
                    Text("Select input...").tag("")
                    ForEach(appState.inputDevices, id: \.self) { device in
                        Text(device).tag(device)
                    }
                }
                .labelsHidden()
                .controlSize(.small)

                TextField("NDI source name", text: $appState.ndiSourceName)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .font(.system(size: 11))

                Button(action: {
                    let input = appState.selectedInputDevice
                    let name = appState.ndiSourceName.isEmpty ? input : appState.ndiSourceName
                    appState.onStartBroadcasting?(input, name)
                }) {
                    Text("Start Broadcasting")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(appState.selectedInputDevice.isEmpty)
            }
            .padding(12)

            Divider()

            // Quit
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Active View

    private func activeView(mode: String, icon: String, detail: String) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                // Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text(mode)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }

                // Inline pickers to switch on the fly
                if case .listening = appState.mode {
                    Picker("Source", selection: Binding(
                        get: { appState.selectedSource },
                        set: { newVal in
                            appState.selectedSource = newVal
                            appState.onStop?()
                            appState.onStartListening?(newVal, appState.selectedOutputDevice)
                        }
                    )) {
                        ForEach(appState.availableSources, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)

                    Picker("Output", selection: Binding(
                        get: { appState.selectedOutputDevice },
                        set: { newVal in
                            appState.selectedOutputDevice = newVal
                            appState.onStop?()
                            appState.onStartListening?(appState.selectedSource, newVal)
                        }
                    )) {
                        ForEach(appState.outputDevices, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                }

                if case .broadcasting = appState.mode {
                    Picker("Input", selection: Binding(
                        get: { appState.selectedInputDevice },
                        set: { newVal in
                            appState.selectedInputDevice = newVal
                            let name = appState.ndiSourceName.isEmpty ? newVal : appState.ndiSourceName
                            appState.onStop?()
                            appState.onStartBroadcasting?(newVal, name)
                        }
                    )) {
                        ForEach(appState.inputDevices, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                }

                // Level meter
                VStack(alignment: .leading, spacing: 4) {
                    Text("Levels")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    AudioMeterView(levels: appState.audioLevels.activeChannels())
                        .frame(height: max(24, CGFloat(max(appState.audioLevels.activeChannels().channelCount, 2)) * 13))
                }

                // Stop button
                Button(action: {
                    appState.onStop?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop")
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(12)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }
}
