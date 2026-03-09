#!/bin/bash

NDI="/Library/NDI SDK for Apple/bin/Application.NDI.FreeAudio"
NDI_FIND="$(dirname "$0")/ndi-find"
PID_FILE="/tmp/ndi-free-audio.pid"

# --- Check if already running ---
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    ACTION=$(osascript -e '
        set theChoice to button returned of (display dialog "NDI Free Audio is currently running." buttons {"Stop", "OK"} default button 2 with title "NDI Free Audio")
        return theChoice
    ' 2>/dev/null)
    if [ "$ACTION" = "Stop" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
        osascript -e 'display notification "Stopped" with title "NDI Free Audio"'
    fi
    exit 0
fi

# --- Parse audio devices from help output ---
HELP=$("$NDI" --help 2>&1)

INPUT_DEVICES=()
OUTPUT_DEVICES=()
in_input=false
in_output=false
while IFS= read -r line; do
    if [[ "$line" == "Input Devices:" ]]; then
        in_input=true; in_output=false; continue
    elif [[ "$line" == "Output Devices:" ]]; then
        in_input=false; in_output=true; continue
    elif [[ -z "$line" ]]; then
        in_input=false; in_output=false; continue
    fi
    device=$(echo "$line" | sed 's/^[[:space:]]*[0-9]* : //' | sed 's/[[:space:]]*$//')
    if [[ -n "$device" ]]; then
        if $in_input; then INPUT_DEVICES+=("$device"); fi
        if $in_output; then OUTPUT_DEVICES+=("$device"); fi
    fi
done <<< "$HELP"

# --- Choose mode ---
MODE=$(osascript -e '
    set theChoice to button returned of (display dialog "What would you like to do?" buttons {"Cancel", "Listen to NDI Source", "Broadcast Input Device"} default button 2 with title "NDI Free Audio")
    return theChoice
' 2>/dev/null)

if [[ -z "$MODE" || "$MODE" == "Cancel" ]]; then
    exit 0
fi

# ===================
# LISTEN MODE
# ===================
if [[ "$MODE" == "Listen to NDI Source" ]]; then

    # Show scanning dialog while searching for NDI sources
    osascript -e 'display notification "Scanning for NDI sources on your network..." with title "NDI Free Audio"'

    # Scan for NDI sources
    RAW_SOURCES=$("$NDI_FIND" 2>/dev/null)
    # Deduplicate
    SOURCES=($(echo "$RAW_SOURCES" | sort -u))

    if [[ ${#SOURCES[@]} -eq 0 ]]; then
        # No sources found — let user type one manually
        SOURCE=$(osascript -e '
            set theResult to text returned of (display dialog "No NDI sources found on the network." & return & return & "Enter an NDI source name manually (or leave blank to auto-connect):" default answer "" with title "NDI Free Audio")
            return theResult
        ' 2>/dev/null)
    else
        # Build AppleScript list of sources
        SRC_LIST=""
        for s in "${SOURCES[@]}"; do
            if [[ -n "$SRC_LIST" ]]; then
                SRC_LIST="$SRC_LIST, \"$s\""
            else
                SRC_LIST="\"$s\""
            fi
        done

        SOURCE=$(osascript -e "
            set srcList to {$SRC_LIST}
            set theChoice to choose from list srcList with prompt \"Select an NDI source to listen to:\" with title \"NDI Free Audio\" default items {item 1 of srcList}
            if theChoice is false then return \"__CANCEL__\"
            return item 1 of theChoice
        " 2>/dev/null)

        if [[ "$SOURCE" == "__CANCEL__" ]]; then
            exit 0
        fi
    fi

    # Pick output device
    OUT_LIST=""
    for d in "${OUTPUT_DEVICES[@]}"; do
        if [[ -n "$OUT_LIST" ]]; then
            OUT_LIST="$OUT_LIST, \"$d\""
        else
            OUT_LIST="\"$d\""
        fi
    done

    OUTPUT_DEV=$(osascript -e "
        set devList to {$OUT_LIST}
        set theChoice to choose from list devList with prompt \"Select audio output device:\" with title \"NDI Free Audio\" default items {item 1 of devList}
        if theChoice is false then return \"__CANCEL__\"
        return item 1 of theChoice
    " 2>/dev/null)

    if [[ -z "$OUTPUT_DEV" || "$OUTPUT_DEV" == "__CANCEL__" ]]; then
        exit 0
    fi

    # Build command
    CMD=("$NDI" -output "$OUTPUT_DEV")
    if [[ -n "$SOURCE" ]]; then
        CMD+=(-output_name "$SOURCE")
    fi

    # Run in background
    "${CMD[@]}" &>/dev/null &
    echo $! > "$PID_FILE"

    osascript -e "display notification \"Listening${SOURCE:+ to $SOURCE} on $OUTPUT_DEV\" with title \"NDI Free Audio\""

# ===================
# BROADCAST MODE
# ===================
elif [[ "$MODE" == "Broadcast Input Device" ]]; then

    # Pick input device
    IN_LIST=""
    for d in "${INPUT_DEVICES[@]}"; do
        if [[ -n "$IN_LIST" ]]; then
            IN_LIST="$IN_LIST, \"$d\""
        else
            IN_LIST="\"$d\""
        fi
    done

    INPUT_DEV=$(osascript -e "
        set devList to {$IN_LIST}
        set theChoice to choose from list devList with prompt \"Select input device to broadcast:\" with title \"NDI Free Audio\" default items {item 1 of devList}
        if theChoice is false then return \"__CANCEL__\"
        return item 1 of theChoice
    " 2>/dev/null)

    if [[ -z "$INPUT_DEV" || "$INPUT_DEV" == "__CANCEL__" ]]; then
        exit 0
    fi

    # Optionally name the NDI source
    NDI_NAME=$(osascript -e "
        set theResult to text returned of (display dialog \"Name for this NDI source on the network:\" default answer \"$INPUT_DEV\" with title \"NDI Free Audio\")
        return theResult
    " 2>/dev/null)

    # Build command
    CMD=("$NDI" -input "$INPUT_DEV")
    if [[ -n "$NDI_NAME" ]]; then
        CMD+=(-input_name "$NDI_NAME")
    fi

    # Run in background
    "${CMD[@]}" &>/dev/null &
    echo $! > "$PID_FILE"

    osascript -e "display notification \"Broadcasting '$INPUT_DEV' as '${NDI_NAME:-$INPUT_DEV}'\" with title \"NDI Free Audio\""
fi
