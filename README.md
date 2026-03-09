# NDI Minecart App for macOS

A native macOS menu bar app for [NDI Minecart](https://docs.ndi.video/all/developing-with-ndi/utilities/free-audio) — listen to NDI audio sources or broadcast local audio inputs over NDI, with real-time level meters.

## Features

- **Menu bar app** — Lives in the macOS menu bar with no Dock icon; click the waveform icon to open
- **Listen to NDI sources** — Auto-discovers NDI audio sources on your network, routes audio to any output device
- **Broadcast audio inputs** — Send any local input device (mic, interface, etc.) as an NDI source
- **Real-time level meters** — Per-channel VU meters with RMS bars, peak hold indicators, and dBFS readout
- **Live device switching** — Change sources, inputs, or outputs on the fly without stopping
- **Multichannel support** — Automatically filters silent channels for clean meter display

## Prerequisites

- macOS
- [NDI SDK for Apple](https://ndi.video/for-developers/ndi-sdk/) installed at `/Library/NDI SDK for Apple/`
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/cjcovell/ndi-minecart.git
cd ndi-minecart
make install
```

This compiles the Swift source, builds the `.app` bundle with an icon, and installs it to `/Applications/NDI Minecart.app`.

## Uninstall

```bash
make uninstall
```

## Usage

1. Launch **NDI Minecart** from Applications, Launchpad, or Spotlight
2. Click the waveform icon in the menu bar to open the popover
3. **To listen**: Select an NDI source and output device, then click **Start Listening**
4. **To broadcast**: Select an input device, optionally set an NDI source name, then click **Start Broadcasting**
5. While active, use the inline pickers to switch devices without stopping
6. Click **Stop** to end the session

## How It Works

The app uses the `Application.NDI.FreeAudio` binary from the NDI SDK for all audio routing. Level metering is handled separately — NDI audio receive for listen mode, and AVAudioEngine input taps for broadcast mode. NDI source discovery uses the NDI C API directly.
