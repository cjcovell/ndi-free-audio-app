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
