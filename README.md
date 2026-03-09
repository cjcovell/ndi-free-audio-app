# NDI Free Audio App for macOS

A simple macOS app wrapper for [NDI Free Audio](https://docs.ndi.video/all/developing-with-ndi/utilities/free-audio) that provides a native GUI for selecting audio devices and NDI sources — no Terminal required.

## Features

- **Listen to NDI Source** — Scans your network for NDI audio sources, lets you pick one and an output device, then runs silently in the background
- **Broadcast Input Device** — Pick a local audio input to broadcast as an NDI source on your network
- **Background operation** — No Terminal window; uses native macOS dialogs and notifications
- **Stop/start management** — Relaunch the app while running to stop the current session

## Prerequisites

- macOS
- [NDI SDK for Apple](https://ndi.video/for-developers/ndi-sdk/) installed at `/Library/NDI SDK for Apple/`
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/cjcovell/ndi-free-audio-app.git
cd ndi-free-audio-app
make install
```

This compiles the NDI source finder, builds the `.app` bundle, and installs it to `/Applications/NDI Free Audio.app`.

## Uninstall

```bash
make uninstall
```

## Usage

Open **NDI Free Audio** from Applications, Launchpad, or Spotlight. Choose a mode, select your devices, and it runs in the background. Reopen the app to stop it.
