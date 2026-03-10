NDI_SDK = /Library/NDI SDK for Apple
APP_NAME = NDI Audio Minecart.app
APP_DIR = /Applications/$(APP_NAME)
BINARY = NDIAudioMinecart
BRIDGING_HEADER = NDI-Bridging-Header.h
SWIFT_SOURCES = $(wildcard Sources/*.swift)
PKG_ID = com.ndi.audiominecart
PKG_VERSION = 2.0

.PHONY: build install clean uninstall package

build: $(BINARY)

$(BINARY): $(SWIFT_SOURCES) $(BRIDGING_HEADER)
	swiftc \
		-import-objc-header $(BRIDGING_HEADER) \
		-I"$(NDI_SDK)/include" \
		-L"$(NDI_SDK)/lib/macOS" \
		-lndi \
		-Xlinker -rpath -Xlinker "$(NDI_SDK)/lib/macOS" \
		-framework AppKit \
		-framework SwiftUI \
		-framework AVFoundation \
		-framework CoreAudio \
		-o $(BINARY) \
		$(SWIFT_SOURCES)

install: build
	@echo "Installing $(APP_NAME)..."
	@mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	@cp $(BINARY) "$(APP_DIR)/Contents/MacOS/$(BINARY)"
	@cp Info.plist "$(APP_DIR)/Contents/Info.plist"
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp Resources/AppIcon.icns "$(APP_DIR)/Contents/Resources/AppIcon.icns"; \
	fi
	@echo "Installed to $(APP_DIR)"

uninstall:
	@rm -rf "$(APP_DIR)"
	@echo "Uninstalled $(APP_NAME)"

clean:
	@rm -f $(BINARY)

package: build
	@echo "Building installer package..."
	@rm -rf build/staging build/pkg
	@mkdir -p "build/staging/Applications/$(APP_NAME)/Contents/MacOS"
	@mkdir -p "build/staging/Applications/$(APP_NAME)/Contents/Resources"
	@mkdir -p build/pkg
	@cp $(BINARY) "build/staging/Applications/$(APP_NAME)/Contents/MacOS/$(BINARY)"
	@cp Info.plist "build/staging/Applications/$(APP_NAME)/Contents/Info.plist"
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp Resources/AppIcon.icns "build/staging/Applications/$(APP_NAME)/Contents/Resources/AppIcon.icns"; \
	fi
	@pkgbuild \
		--root build/staging \
		--identifier $(PKG_ID) \
		--version $(PKG_VERSION) \
		--scripts scripts \
		build/pkg/NDIAudioMinecart-component.pkg
	@productbuild \
		--package build/pkg/NDIAudioMinecart-component.pkg \
		--identifier $(PKG_ID) \
		--version $(PKG_VERSION) \
		"build/NDIAudioMinecart-$(PKG_VERSION).pkg"
	@rm -rf build/staging build/pkg
	@echo "Package built: build/NDIAudioMinecart-$(PKG_VERSION).pkg"
