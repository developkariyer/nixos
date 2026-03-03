#!/usr/bin/env bash
# Antigravity Auto-Retry Watcher
# Watches for the "Retry" button dialog via pixel template matching
# and clicks it immediately using ydotool (kernel-level input injection).
#
# Usage:
#   Setup:   ./watcher.sh setup    (capture reference image of Retry button)
#   Run:     ./watcher.sh           (start watching)

CONFIG_DIR="$HOME/.config/autoretry"
TEMPLATE="$CONFIG_DIR/retry_template.png"
SCREENSHOT="/tmp/autoretry_screenshot.png"
RESULT="/tmp/autoretry_result"
LOG="$CONFIG_DIR/watcher.log"

# Poll every 10 seconds
POLL_INTERVAL=10
# Cooldown after clicking to avoid double-clicks
COOLDOWN=15
# RMSE threshold: 0 = perfect match, higher = more fuzzy
THRESHOLD=0.15

export YDOTOOL_SOCKET="/run/ydotoold/socket"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"
}

setup() {
    echo "=== Auto-Retry Template Capture ==="
    echo ""
    echo "1. Make the 'Agent terminated due to error' dialog visible"
    echo "2. Press Enter here when ready"
    echo "3. Then click-drag to select JUST the Retry button"
    echo ""
    read -rp "Press Enter when dialog is visible..."

    mkdir -p "$CONFIG_DIR"
    grim -g "$(slurp)" "$TEMPLATE"

    echo ""
    echo "Template saved to: $TEMPLATE"
    echo "Size: $(magick identify -format '%wx%h' "$TEMPLATE")"
    echo ""
    echo "Run './watcher.sh' to start watching."
}

watch() {
    if [[ ! -f "$TEMPLATE" ]]; then
        echo "ERROR: No template image found at $TEMPLATE"
        echo "Run './watcher.sh setup' first to capture the Retry button."
        exit 1
    fi

    mkdir -p "$CONFIG_DIR"
    log "Watcher started. Template: $(magick identify -format '%wx%h' "$TEMPLATE")"
    log "Polling every ${POLL_INTERVAL}s, cooldown ${COOLDOWN}s, threshold ${THRESHOLD}"

    while true; do
        log "Polling..."

        # Capture full screen
        if ! grim "$SCREENSHOT" 2>/dev/null; then
            log "WARN: grim capture failed, retrying..."
            sleep "$POLL_INTERVAL"
            continue
        fi

        # Subimage search: find template within screenshot
        # Output format: "663.571 (0.0101254) @ 47,28 [0.234199]"
        metric=$(magick compare -metric RMSE -subimage-search \
            "$TEMPLATE" "$SCREENSHOT" "${RESULT}.png" 2>&1 || true)

        log "Compare output: $metric"

        # Extract normalized RMSE from parentheses: (0.0101254)
        rmse=$(echo "$metric" | grep -oP '\([\d.]+\)' | head -1 | tr -d '()' || echo "1")

        # Extract position from "@ X,Y"
        pos=$(echo "$metric" | grep -oP '@ \d+,\d+' | head -1 || echo "")

        log "RMSE=$rmse, position=$pos"

        # Compare with threshold
        is_match=$(awk "BEGIN { print ($rmse < $THRESHOLD) ? 1 : 0 }" 2>/dev/null || echo "0")

        if [[ "$is_match" == "1" && -n "$pos" ]]; then
            # Parse X,Y from "@ X,Y"
            x=$(echo "$pos" | grep -oP '\d+' | head -1)
            y=$(echo "$pos" | grep -oP '\d+' | tail -1)

            # Calculate center of the matched button
            tw=$(magick identify -format "%w" "$TEMPLATE")
            th=$(magick identify -format "%h" "$TEMPLATE")
            cx=$((x + tw / 2))
            cy=$((y + th / 2))

            log "MATCH! Clicking center ($cx,$cy)..."

            # Move mouse to button center and click
            ydotool mousemove --absolute -x "$cx" -y "$cy"
            sleep 0.3
            ydotool click 0xC0

            log "Clicked. Cooldown ${COOLDOWN}s..."
            sleep "$COOLDOWN"
        else
            log "No match (RMSE=$rmse, threshold=$THRESHOLD)"
        fi

        # Clean up temp files
        rm -f "$SCREENSHOT" "${RESULT}.png" "${RESULT}-0.png" "${RESULT}-1.png" 2>/dev/null

        sleep "$POLL_INTERVAL"
    done
}

case "${1:-watch}" in
    setup) setup ;;
    watch|"") watch ;;
    *) echo "Usage: $0 [setup|watch]" ;;
esac
