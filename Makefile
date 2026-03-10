NDI_SDK = /Library/NDI SDK for Apple
APP_NAME = NDI Audio Minecart.app
APP_DIR = /Applications/$(APP_NAME)
BINARY = NDIAudioMinecart
BRIDGING_HEADER = NDI-Bridging-Header.h
SWIFT_SOURCES = $(wildcard Sources/*.swift)

.PHONY: build install clean uninstall

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
