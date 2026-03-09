NDI_SDK = /Library/NDI SDK for Apple
APP_NAME = NDI Minecart.app
APP_DIR = /Applications/$(APP_NAME)
BINARY = NDIMinecart
BRIDGING_HEADER = NDI-Bridging-Header.h
SWIFT_SOURCES = $(wildcard Sources/*.swift)
NDI_LOGO = $(NDI_SDK)/documentation/brand-assets/1. NDI/1.1 NDI Logo/Light/NDI Logo Master - Light@5x.png

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
	@# Generate app icon from NDI SDK logo if available
	@if [ -f "$(NDI_LOGO)" ]; then \
		ICONSET=$$(mktemp -d)/AppIcon.iconset; \
		mkdir -p "$$ICONSET"; \
		sips -z 16 16     "$(NDI_LOGO)" --out "$$ICONSET/icon_16x16.png"      > /dev/null 2>&1; \
		sips -z 32 32     "$(NDI_LOGO)" --out "$$ICONSET/icon_16x16@2x.png"   > /dev/null 2>&1; \
		sips -z 32 32     "$(NDI_LOGO)" --out "$$ICONSET/icon_32x32.png"      > /dev/null 2>&1; \
		sips -z 64 64     "$(NDI_LOGO)" --out "$$ICONSET/icon_32x32@2x.png"   > /dev/null 2>&1; \
		sips -z 128 128   "$(NDI_LOGO)" --out "$$ICONSET/icon_128x128.png"    > /dev/null 2>&1; \
		sips -z 256 256   "$(NDI_LOGO)" --out "$$ICONSET/icon_128x128@2x.png" > /dev/null 2>&1; \
		sips -z 256 256   "$(NDI_LOGO)" --out "$$ICONSET/icon_256x256.png"    > /dev/null 2>&1; \
		sips -z 512 512   "$(NDI_LOGO)" --out "$$ICONSET/icon_256x256@2x.png" > /dev/null 2>&1; \
		sips -z 512 512   "$(NDI_LOGO)" --out "$$ICONSET/icon_512x512.png"    > /dev/null 2>&1; \
		sips -z 1024 1024 "$(NDI_LOGO)" --out "$$ICONSET/icon_512x512@2x.png" > /dev/null 2>&1; \
		iconutil -c icns "$$ICONSET" -o "$(APP_DIR)/Contents/Resources/AppIcon.icns"; \
		echo "App icon generated from NDI SDK logo."; \
	else \
		echo "NDI SDK logo not found, skipping icon."; \
	fi
	@echo "Installed to $(APP_DIR)"

uninstall:
	@rm -rf "$(APP_DIR)"
	@echo "Uninstalled $(APP_NAME)"

clean:
	@rm -f $(BINARY)
