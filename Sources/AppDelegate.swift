import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var appState = AppState()
    var processManager = ProcessManager()
    var ndiBridge: NDIBridge!
    var audioEngine: AudioEngine!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Set up managers
        ndiBridge = NDIBridge(appState: appState)
        audioEngine = AudioEngine(appState: appState)

        if !ndiBridge.isInitialized {
            appState.errorMessage = "NDI SDK failed to initialize"
        }

        // Load devices asynchronously
        refreshDevices()

        // Wire up action callbacks
        appState.onStartListening = { [weak self] source, output in
            self?.startListening(source: source, outputDevice: output)
        }
        appState.onStartBroadcasting = { [weak self] input, name in
            self?.startBroadcasting(inputDevice: input, ndiName: name)
        }
        appState.onStop = { [weak self] in
            self?.stop()
        }

        // Set up status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "NDI Free Audio"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Set up popover
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(appState: appState)
        )

        // Start NDI source discovery
        ndiBridge.startFinding()

        // Close popover on outside click
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop()
        ndiBridge.stopFinding()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            // Refresh devices each time the popover opens
            refreshDevices()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Device Management

    private func refreshDevices() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let devices = DeviceManager()
            DispatchQueue.main.async {
                self?.appState.inputDevices = devices.inputDevices
                self?.appState.outputDevices = devices.outputDevices
            }
        }
    }

    // MARK: - Actions

    func startListening(source: String, outputDevice: String) {
        guard processManager.startListening(source: source, outputDevice: outputDevice) else {
            appState.errorMessage = "Failed to start — is the NDI SDK installed?"
            return
        }
        appState.errorMessage = nil
        appState.mode = .listening(source: source, outputDevice: outputDevice)

        if !source.isEmpty {
            ndiBridge.startMetering(sourceName: source)
        }

        updateIcon(active: true)
    }

    func startBroadcasting(inputDevice: String, ndiName: String) {
        guard processManager.startBroadcasting(inputDevice: inputDevice, ndiName: ndiName) else {
            appState.errorMessage = "Failed to start — is the NDI SDK installed?"
            return
        }
        appState.errorMessage = nil
        appState.mode = .broadcasting(inputDevice: inputDevice, ndiName: ndiName)
        audioEngine.startMetering(inputDeviceName: inputDevice)
        updateIcon(active: true)
    }

    func stop() {
        processManager.stop()
        ndiBridge.stopMetering()
        audioEngine.stopMetering()
        appState.mode = .idle
        appState.audioLevels = .silence
        updateIcon(active: false)
    }

    private func updateIcon(active: Bool) {
        if let button = statusItem.button {
            let symbolName = active ? "waveform.circle.fill" : "waveform"
            button.image = NSImage(
                systemSymbolName: symbolName,
                accessibilityDescription: "NDI Free Audio"
            )
        }
    }
}
