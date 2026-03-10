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
