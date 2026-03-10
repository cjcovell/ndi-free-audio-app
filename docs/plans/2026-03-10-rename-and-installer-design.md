# NDI Audio Minecart: Rename & .pkg Installer Design

**Goal:** Rename the app from "NDI Minecart" to "NDI Audio Minecart" and create a macOS .pkg installer with prerequisite checking and Login Item setup.

## Part 1: Rename to "NDI Audio Minecart"

Update all references across the project:
- Display name: **NDI Audio Minecart**
- Binary: **NDIAudioMinecart**
- Bundle ID: **com.ndi.audiominecart**
- App bundle: **NDI Audio Minecart.app**
- Files affected: Makefile, Info.plist, ContentView.swift, AppDelegate.swift, README.md, CLAUDE.md, .gitignore

## Part 2: Pre-built App Icon

- Generate `AppIcon.icns` once from the NDI SDK logo and commit it to `Resources/`
- Remove the icon generation logic from the Makefile — just copy the committed icon during install

## Part 3: .pkg Installer

### Prerequisite checks (preflight script)

1. **Xcode CLI Tools** — if missing, trigger `xcode-select --install`, wait for completion, then continue
2. **NDI SDK** at `/Library/NDI SDK for Apple/` — if missing, show dialog with download link to the NDI website and abort installation

### Installation steps

1. Run `make build` to compile the binary
2. Create the `.app` bundle structure in `/Applications/NDI Audio Minecart.app`
3. Copy binary, Info.plist, and pre-built AppIcon.icns

### Post-install

- Add the app as a Login Item via `osascript`

### Makefile additions

- New `package` target that builds the `.pkg` using `pkgbuild` and `productbuild`
- Preflight/postflight scripts in a `scripts/` directory

## Out of Scope

- Code signing / notarization (future work)
- DMG or Homebrew distribution
