# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make build      # Compile the binary (NDIFreeAudio)
make install    # Build + create .app bundle in /Applications/NDI Free Audio.app
make clean      # Remove compiled binary
make uninstall  # Remove .app from /Applications
```

The build uses `swiftc` directly (no Xcode project/SPM). All Swift sources in `Sources/` are compiled together with the NDI bridging header.

## Prerequisites

- NDI SDK for Apple installed at `/Library/NDI SDK for Apple/`
- Xcode Command Line Tools

## Architecture

This is a native macOS **menu bar app** (LSUIElement, no Dock icon) built with SwiftUI hosted in an NSPopover. There is no Xcode project — it compiles with `swiftc` via the Makefile.

### Key Components

- **`main.swift`** — App entry point. Creates NSApplication and AppDelegate manually (no @main attribute).
- **`AppDelegate.swift`** — Owns the NSStatusItem (menu bar icon), NSPopover, and coordinates all managers. Wires action callbacks into AppState.
- **`AppState.swift`** — Central ObservableObject. Holds UI state (mode, device lists, selections, audio levels) and action callbacks. The `AppMode` enum (idle/listening/broadcasting) drives the entire UI. Contains level smoothing logic (attack/release/peak-hold).
- **`ContentView.swift`** — SwiftUI popover UI. Switches between idle view (source/device pickers + start buttons) and active view (live pickers + meters + stop button). Fixed width of 280pt.
- **`AudioMeterView.swift`** — Per-channel VU meter rendering with RMS bars, peak hold indicators, and dBFS readout. Uses a green→yellow→red gradient.
- **`ProcessManager.swift`** — Wraps the NDI SDK's `Application.NDI.FreeAudio` CLI binary for actual audio routing. The app does NOT implement audio routing itself.
- **`NDIBridge.swift`** — Direct NDI C API usage via the bridging header. Handles source discovery (find loop on background Thread) and audio receive for listen-mode level metering.
- **`AudioEngine.swift`** — AVAudioEngine-based input tap for broadcast-mode level metering. Matches input devices by name using CoreAudio property queries.
- **`DeviceManager.swift`** — Parses `--help` output from the NDI FreeAudio binary to enumerate available input/output devices.

### Important Patterns

- **Audio routing vs. metering are separate**: `ProcessManager` handles actual audio routing by launching the NDI FreeAudio CLI binary. Level metering is independent — `NDIBridge` receives NDI audio for listen mode, `AudioEngine` taps the local input for broadcast mode.
- **Callback-based actions**: AppState uses closure properties (`onStartListening`, `onStartBroadcasting`, `onStop`) set by AppDelegate, keeping the view layer decoupled from business logic.
- **NDI C API access**: The bridging header (`NDI-Bridging-Header.h`) imports `Processing.NDI.Lib.h`. NDI types like `NDIlib_find_instance_t` and `NDIlib_recv_instance_t` are used directly in Swift.
- **Background threads**: NDI source discovery and audio metering run on manually managed `Thread` instances (not GCD), posting updates back to main via `DispatchQueue.main.async`.
