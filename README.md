# NDI Audio Minecart

A native macOS menu bar app that sends and receives audio over [NDI](https://ndi.video/), with real-time level meters. Built on top of the [NDI Free Audio](https://docs.ndi.video/all/developing-with-ndi/utilities/free-audio) utility from the NDI SDK.

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
git clone https://github.com/cjcovell/ndi-audio-minecart.git
cd ndi-audio-minecart
make install
```

This compiles the Swift source, builds the `.app` bundle with an icon, and installs it to `/Applications/NDI Audio Minecart.app`.

## Install (Package Installer)

Download the latest `.pkg` from [Releases](https://github.com/cjcovell/ndi-audio-minecart/releases) and double-click to run the installer. It will:

1. Check for the NDI SDK for Apple (opens download page if missing)
2. Install the app to `/Applications/NDI Audio Minecart.app`
3. Add NDI Audio Minecart as a Login Item (launches at startup)

### Build the installer from source

```bash
make package
```

This produces `build/NDIAudioMinecart-2.0.pkg`.

## Uninstall

```bash
make uninstall
```

## Usage

1. Launch **NDI Audio Minecart** from Applications, Launchpad, or Spotlight
2. Click the waveform icon in the menu bar to open the popover
3. **To listen**: Select an NDI source and output device, then click **Start Listening**
4. **To broadcast**: Select an input device, optionally set an NDI source name, then click **Start Broadcasting**
5. While active, use the inline pickers to switch devices without stopping
6. Click **Stop** to end the session

## How It Works

The app wraps the `Application.NDI.FreeAudio` CLI binary from the NDI SDK for all audio routing. Level metering is handled independently — NDI audio receive for listen mode, and AVAudioEngine input taps for broadcast mode. NDI source discovery uses the NDI C API directly via a Swift bridging header.
