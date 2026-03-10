# NDI Audio Minecart: Rename & .pkg Installer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename the app from "NDI Minecart" to "NDI Audio Minecart" and create a macOS .pkg installer with prerequisite checks and Login Item setup.

**Architecture:** Two independent workstreams — a straightforward rename across all project files, then building a .pkg installer using `pkgbuild`/`productbuild` with shell scripts for preflight (prerequisite checks) and postflight (Login Item registration). A pre-built AppIcon.icns replaces the dynamic icon generation in the Makefile.

**Tech Stack:** Make, shell scripts (bash), `pkgbuild`, `productbuild`, `osascript`, `sips`, `iconutil`

---

### Task 1: Rename — Makefile and .gitignore

**Files:**
- Modify: `Makefile:2-4`
- Modify: `.gitignore:1`

**Step 1: Update Makefile app name and binary**

Change lines 2-4 in `Makefile`:
```makefile
APP_NAME = NDI Audio Minecart.app
APP_DIR = /Applications/$(APP_NAME)
BINARY = NDIAudioMinecart
```

**Step 2: Update .gitignore**

Replace line 1 in `.gitignore`:
```
NDIAudioMinecart
```

**Step 3: Build to verify rename compiles**

Run: `make build`
Expected: Produces `NDIAudioMinecart` binary with no errors

**Step 4: Clean up old binary**

Run: `rm -f NDIMinecart`

**Step 5: Commit**

```bash
git add Makefile .gitignore
git commit -m "feat: rename binary and app bundle to NDI Audio Minecart"
```

---

### Task 2: Rename — Info.plist

**Files:**
- Modify: `Info.plist:6,8,10,20`

**Step 1: Update all name references in Info.plist**

Line 6 — CFBundleExecutable:
```xml
	<string>NDIAudioMinecart</string>
```

Line 8 — CFBundleIdentifier:
```xml
	<string>com.ndi.audiominecart</string>
```

Line 10 — CFBundleName:
```xml
	<string>NDI Audio Minecart</string>
```

Line 20 — NSMicrophoneUsageDescription:
```xml
	<string>NDI Audio Minecart needs microphone access to broadcast audio over NDI.</string>
```

**Step 2: Commit**

```bash
git add Info.plist
git commit -m "feat: update Info.plist for NDI Audio Minecart rename"
```

---

### Task 3: Rename — Swift source files

**Files:**
- Modify: `Sources/ContentView.swift:12`
- Modify: `Sources/AppDelegate.swift:43,140`

**Step 1: Update ContentView header text**

Line 12 in `Sources/ContentView.swift`:
```swift
                Text("NDI Audio Minecart")
```

**Step 2: Update AppDelegate accessibility descriptions**

Line 43 in `Sources/AppDelegate.swift`:
```swift
                accessibilityDescription: "NDI Audio Minecart"
```

Line 140 in `Sources/AppDelegate.swift`:
```swift
                accessibilityDescription: "NDI Audio Minecart"
```

**Step 3: Build to verify**

Run: `make build`
Expected: Compiles successfully

**Step 4: Commit**

```bash
git add Sources/ContentView.swift Sources/AppDelegate.swift
git commit -m "feat: update UI strings for NDI Audio Minecart rename"
```

---

### Task 4: Rename — Documentation

**Files:**
- Modify: `README.md` (all occurrences of "NDI Minecart")
- Modify: `CLAUDE.md` (all occurrences of "NDI Minecart" and "NDIMinecart")

**Step 1: Update README.md**

Replace all occurrences:
- "# NDI Minecart" → "# NDI Audio Minecart"
- "NDI Minecart" → "NDI Audio Minecart" (throughout)
- "ndi-minecart" → "ndi-audio-minecart" (clone URL)
- "`/Applications/NDI Minecart.app`" → "`/Applications/NDI Audio Minecart.app`"

**Step 2: Update CLAUDE.md**

Replace all occurrences:
- "NDIMinecart" → "NDIAudioMinecart" (binary references)
- "NDI Minecart" → "NDI Audio Minecart" (display name references)
- "/Applications/NDI Minecart.app" → "/Applications/NDI Audio Minecart.app"

**Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: update documentation for NDI Audio Minecart rename"
```

---

### Task 5: Generate and commit pre-built AppIcon.icns

**Files:**
- Create: `Resources/AppIcon.icns`
- Modify: `Makefile:7,32-50`

**Step 1: Create Resources directory and generate icon**

```bash
mkdir -p Resources
NDI_LOGO="/Library/NDI SDK for Apple/documentation/brand-assets/1. NDI/1.1 NDI Logo/Light/NDI Logo Master - Light@5x.png"
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
sips -z 16 16     "$NDI_LOGO" --out "$ICONSET/icon_16x16.png"      > /dev/null 2>&1
sips -z 32 32     "$NDI_LOGO" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null 2>&1
sips -z 32 32     "$NDI_LOGO" --out "$ICONSET/icon_32x32.png"      > /dev/null 2>&1
sips -z 64 64     "$NDI_LOGO" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null 2>&1
sips -z 128 128   "$NDI_LOGO" --out "$ICONSET/icon_128x128.png"    > /dev/null 2>&1
sips -z 256 256   "$NDI_LOGO" --out "$ICONSET/icon_128x128@2x.png" > /dev/null 2>&1
sips -z 256 256   "$NDI_LOGO" --out "$ICONSET/icon_256x256.png"    > /dev/null 2>&1
sips -z 512 512   "$NDI_LOGO" --out "$ICONSET/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 512 512   "$NDI_LOGO" --out "$ICONSET/icon_512x512.png"    > /dev/null 2>&1
sips -z 1024 1024 "$NDI_LOGO" --out "$ICONSET/icon_512x512@2x.png" > /dev/null 2>&1
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
```

**Step 2: Simplify Makefile install target**

Remove the `NDI_LOGO` variable (line 7) and replace the icon generation block (lines 32-50) with:

```makefile
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp Resources/AppIcon.icns "$(APP_DIR)/Contents/Resources/AppIcon.icns"; \
	fi
```

The full `install` target becomes:
```makefile
install: build
	@echo "Installing $(APP_NAME)..."
	@mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	@cp $(BINARY) "$(APP_DIR)/Contents/MacOS/$(BINARY)"
	@cp Info.plist "$(APP_DIR)/Contents/Info.plist"
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp Resources/AppIcon.icns "$(APP_DIR)/Contents/Resources/AppIcon.icns"; \
	fi
	@echo "Installed to $(APP_DIR)"
```

**Step 3: Verify install still works**

Run: `make clean && make install`
Expected: App installs to `/Applications/NDI Audio Minecart.app` with icon

**Step 4: Commit**

```bash
git add Resources/AppIcon.icns Makefile
git commit -m "feat: add pre-built AppIcon.icns, simplify Makefile install"
```

---

### Task 6: Create preflight script (prerequisite checks)

**Files:**
- Create: `scripts/preflight.sh`

**Step 1: Write preflight script**

```bash
#!/bin/bash
# Preflight script for NDI Audio Minecart .pkg installer
# Checks for required prerequisites before installation

set -e

NDI_SDK_PATH="/Library/NDI SDK for Apple"
NDI_DOWNLOAD_URL="https://ndi.video/for-developers/ndi-sdk/"

# Check for Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    osascript -e 'display dialog "Xcode Command Line Tools are required.\n\nClick OK to install them. After installation completes, run this installer again." buttons {"OK"} default button "OK" with title "NDI Audio Minecart Installer" with icon caution'
    xcode-select --install
    exit 1
fi

# Check for NDI SDK
if [ ! -d "$NDI_SDK_PATH" ]; then
    osascript -e "display dialog \"NDI SDK for Apple is required but not installed.\n\nPlease download and install it from:\n${NDI_DOWNLOAD_URL}\n\nAfter installing the SDK, run this installer again.\" buttons {\"Open Download Page\", \"Cancel\"} default button \"Open Download Page\" with title \"NDI Audio Minecart Installer\" with icon caution" 2>/dev/null
    BUTTON=$?
    if [ $BUTTON -eq 0 ]; then
        open "$NDI_DOWNLOAD_URL"
    fi
    exit 1
fi

# Check for NDI FreeAudio binary
if [ ! -f "$NDI_SDK_PATH/bin/Application.NDI.FreeAudio" ]; then
    osascript -e 'display dialog "NDI SDK is installed but the FreeAudio binary was not found.\n\nPlease reinstall the NDI SDK for Apple." buttons {"OK"} default button "OK" with title "NDI Audio Minecart Installer" with icon caution'
    exit 1
fi

exit 0
```

**Step 2: Make executable**

Run: `chmod +x scripts/preflight.sh`

**Step 3: Test the script manually**

Run: `bash scripts/preflight.sh && echo "PASS"`
Expected: PASS (assuming prerequisites are installed on dev machine)

**Step 4: Commit**

```bash
git add scripts/preflight.sh
git commit -m "feat: add preflight script for prerequisite checks"
```

---

### Task 7: Create postflight script (Login Item)

**Files:**
- Create: `scripts/postflight.sh`

**Step 1: Write postflight script**

```bash
#!/bin/bash
# Postflight script for NDI Audio Minecart .pkg installer
# Adds the app as a Login Item so it launches at startup

APP_PATH="/Applications/NDI Audio Minecart.app"

if [ -d "$APP_PATH" ]; then
    osascript -e "
        tell application \"System Events\"
            if not (exists login item \"NDI Audio Minecart\") then
                make login item at end with properties {path:\"$APP_PATH\", hidden:false}
            end if
        end tell
    " 2>/dev/null || true
fi

exit 0
```

**Step 2: Make executable**

Run: `chmod +x scripts/postflight.sh`

**Step 3: Commit**

```bash
git add scripts/postflight.sh
git commit -m "feat: add postflight script for Login Item registration"
```

---

### Task 8: Add `package` target to Makefile

**Files:**
- Modify: `Makefile` (add new target)

**Step 1: Add package target**

Add after the `uninstall` target in the Makefile:

```makefile
PKG_ID = com.ndi.audiominecart
PKG_VERSION = 2.0

package: build
	@echo "Building installer package..."
	@# Create staging directory
	@rm -rf build/staging build/pkg
	@mkdir -p build/staging/Applications/NDI\ Audio\ Minecart.app/Contents/MacOS
	@mkdir -p build/staging/Applications/NDI\ Audio\ Minecart.app/Contents/Resources
	@mkdir -p build/pkg
	@cp $(BINARY) "build/staging/Applications/NDI Audio Minecart.app/Contents/MacOS/$(BINARY)"
	@cp Info.plist "build/staging/Applications/NDI Audio Minecart.app/Contents/Info.plist"
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp Resources/AppIcon.icns "build/staging/Applications/NDI Audio Minecart.app/Contents/Resources/AppIcon.icns"; \
	fi
	@# Build component package
	@pkgbuild \
		--root build/staging \
		--identifier $(PKG_ID) \
		--version $(PKG_VERSION) \
		--scripts scripts \
		build/pkg/NDIAudioMinecart-component.pkg
	@# Build product archive with distribution
	@productbuild \
		--package build/pkg/NDIAudioMinecart-component.pkg \
		--identifier $(PKG_ID) \
		--version $(PKG_VERSION) \
		"build/NDIAudioMinecart-$(PKG_VERSION).pkg"
	@rm -rf build/staging build/pkg
	@echo "Package built: build/NDIAudioMinecart-$(PKG_VERSION).pkg"
```

**Step 2: Add `build/` to .gitignore**

Append to `.gitignore`:
```
build/
```

**Step 3: Update .PHONY line**

```makefile
.PHONY: build install clean uninstall package
```

**Step 4: Test package build**

Run: `make package`
Expected: Produces `build/NDIAudioMinecart-2.0.pkg`

**Step 5: Verify the .pkg installs correctly**

Run: `open build/NDIAudioMinecart-2.0.pkg`
Expected: macOS installer wizard opens, shows prerequisite checks, installs to /Applications

**Step 6: Commit**

```bash
git add Makefile .gitignore
git commit -m "feat: add make package target for .pkg installer"
```

---

### Task 9: Update documentation for installer

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`

**Step 1: Add installer section to README.md**

Add after the existing Install section:

```markdown
## Install (Package Installer)

Download the latest `.pkg` from [Releases](https://github.com/cjcovell/ndi-audio-minecart/releases) and double-click to run the installer. It will:

1. Check for Xcode Command Line Tools (prompts to install if missing)
2. Check for the NDI SDK for Apple (opens download page if missing)
3. Install the app to `/Applications/NDI Audio Minecart.app`
4. Add NDI Audio Minecart as a Login Item (launches at startup)

### Build the installer from source

```bash
make package
```

This produces `build/NDIAudioMinecart-2.0.pkg`.
```

**Step 2: Update CLAUDE.md build commands**

Add `make package` to the build commands section:

```bash
make package   # Build .pkg installer to build/
```

**Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: add installer documentation"
```

---

### Task 10: Final verification

**Step 1: Clean build and full test**

```bash
make clean
make build
make install
make package
```
Expected: All targets succeed

**Step 2: Test .pkg installer on clean state**

```bash
make uninstall
open build/NDIAudioMinecart-2.0.pkg
```
Expected: Installer runs, checks prereqs, installs app, adds Login Item

**Step 3: Verify app launches**

Run: `open "/Applications/NDI Audio Minecart.app"`
Expected: Menu bar icon appears, popover shows "NDI Audio Minecart" header

**Step 4: Verify Login Item was added**

Run: `osascript -e 'tell application "System Events" to get the name of every login item'`
Expected: Output includes "NDI Audio Minecart"
