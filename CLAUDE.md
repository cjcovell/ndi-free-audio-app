# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make build      # Compile the binary (NDIAudioMinecart)
make install    # Build + create .app bundle in /Applications/NDI Audio Minecart.app
make clean      # Remove compiled binary
make uninstall  # Remove .app from /Applications
```

The build uses `swiftc` directly (no Xcode project/SPM). All Swift sources in `Sources/` are compiled together with the NDI bridging header. After installing, kill and relaunch the app to pick up changes.

## Prerequisites

- NDI SDK for Apple installed at `/Library/NDI SDK for Apple/`
- Xcode Command Line Tools

## Architecture

Native macOS **menu bar app** (LSUIElement, no Dock icon) built with SwiftUI hosted in an NSPopover. Compiles with `swiftc` via the Makefile — there is no Xcode project.

### Key Components

- **`main.swift`** — App entry point. Creates NSApplication and AppDelegate manually (no @main attribute).
- **`AppDelegate.swift`** — Owns the NSStatusItem (menu bar icon), NSPopover, and coordinates all managers. Wires action callbacks into AppState. Refreshes device lists asynchronously on popover open.
- **`AppState.swift`** — Central ObservableObject. Holds UI state (mode, device lists, selections, audio levels, error message) and action callbacks. The `AppMode` enum (idle/listening/broadcasting) drives the entire UI. Contains level smoothing logic (attack/release/peak-hold with -60 dB floor).
- **`ContentView.swift`** — SwiftUI popover UI. Switches between idle view (source/device pickers + start buttons) and active view (live pickers + meters + stop button). Includes dismissible error banner. Fixed width of 280pt. Uses continuous corner radius (macOS Tahoe style).
- **`AudioMeterView.swift`** — Per-channel VU meter rendering with RMS bars, peak hold indicators, and dBFS readout. Uses a green-yellow-red gradient with continuous corner radius.
- **`ProcessManager.swift`** — Wraps the NDI SDK's `Application.NDI.FreeAudio` CLI binary for actual audio routing. Returns success/failure so callers can surface errors. The app does NOT implement audio routing itself.
- **`NDIBridge.swift`** — Direct NDI C API usage via the bridging header. Handles source discovery (find loop on background Thread) and audio receive for listen-mode level metering. Checks `NDIlib_initialize()` return value before any NDI operations.
- **`AudioEngine.swift`** — AVAudioEngine-based input tap for broadcast-mode level metering. Matches input devices by name using CoreAudio property queries.
- **`DeviceManager.swift`** — Parses `--help` output from the NDI FreeAudio binary to enumerate available input/output devices. Called asynchronously from a background queue.

### Important Patterns

- **Audio routing vs. metering are separate**: `ProcessManager` handles actual audio routing by launching the NDI FreeAudio CLI binary as a child process. Level metering is independent — `NDIBridge` receives NDI audio for listen mode, `AudioEngine` taps the local input for broadcast mode. Force-killing the app will orphan the child process.
- **Thread safety**: NDIBridge uses `NSLock` to protect all shared state (`recvInstance`, `findInstance`, stop flags) and `DispatchSemaphore` for thread join on teardown. Background threads are `Thread` instances; synchronization and main-thread dispatch use GCD.
- **Callback-based actions**: AppState uses closure properties (`onStartListening`, `onStartBroadcasting`, `onStop`) set by AppDelegate, keeping the view layer decoupled from business logic.
- **NDI C API access**: The bridging header (`NDI-Bridging-Header.h`) imports `Processing.NDI.Lib.h`. NDI types like `NDIlib_find_instance_t` and `NDIlib_recv_instance_t` are used directly in Swift. SourceKit will show errors for NDI symbols — these resolve at build time via the bridging header.
- **Error surfacing**: `AppState.errorMessage` drives a dismissible banner in ContentView. ProcessManager launch failures and NDI init failures both set this.
