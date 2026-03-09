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

        // Load devices
        let devices = DeviceManager()
        appState.inputDevices = devices.inputDevices
        appState.outputDevices = devices.outputDevices

        // Wire up action callbacks
        appState.onStartListening = { [unowned self] source, output in
            self.startListening(source: source, outputDevice: output)
        }
        appState.onStartBroadcasting = { [unowned self] input, name in
            self.startBroadcasting(inputDevice: input, ndiName: name)
        }
        appState.onStop = { [unowned self] in
            self.stop()
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
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Actions

    func startListening(source: String, outputDevice: String) {
        processManager.startListening(source: source, outputDevice: outputDevice)
        appState.mode = .listening(source: source, outputDevice: outputDevice)

        if !source.isEmpty {
            ndiBridge.startMetering(sourceName: source)
        }

        updateIcon(active: true)
    }

    func startBroadcasting(inputDevice: String, ndiName: String) {
        processManager.startBroadcasting(inputDevice: inputDevice, ndiName: ndiName)
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
