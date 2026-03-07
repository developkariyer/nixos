#!/usr/bin/env bash
# Antigravity Auto-Retry Watcher
# Detects the "Retry" dialog via OpenCV template matching per-output.
# Clicks Retry via ydotool at calculated absolute coordinates (pixels/2).
#
# Usage:
#   Setup:   ./watcher.sh setup    (capture reference of the dialog)
#   Run:     ./watcher.sh           (start watching)

CONFIG_DIR="$HOME/.config/autoretry"
TEMPLATE="$CONFIG_DIR/retry_template.png"
MATCHER="$CONFIG_DIR/matcher.py"
LOG="$CONFIG_DIR/watcher.log"

POLL_INTERVAL=5
COOLDOWN=10

# ydotool uses half-pixel coordinates (divide pixel coords by 2)
COORD_SCALE=2

# Output names and positions from niri config
OUTPUTS=()
OUTPUT_X=()
OUTPUT_Y=()
OUTPUT_W=()
OUTPUT_H=()

export YDOTOOL_SOCKET="/run/ydotoold/socket"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"
}

# Warp cursor to global origin by focusing a window on the leftmost
# monitor (triggers warp-mouse-to-focus), then slamming to (0,0)
warp_to_origin() {
    local origin="${OUTPUTS[0]}"
    local win_id
    win_id=$(niri msg --json workspaces 2>/dev/null | \
        grep -oP '"output":"'"$origin"'"[^}]*"active_window_id":\d+' | \
        head -1 | grep -oP '"active_window_id":\d+' | grep -oP '\d+')

    if [[ -n "$win_id" ]]; then
        niri msg action focus-window --id "$win_id" 2>/dev/null
        sleep 0.1
    fi

    # Slam to (0,0)
    ydotool mousemove -x -20000 -y -20000
    #sleep 0.1
}

detect_outputs() {
    OUTPUTS=()
    OUTPUT_X=()
    OUTPUT_Y=()
    OUTPUT_W=()
    OUTPUT_H=()

    local names
    names=$(niri msg --json outputs 2>/dev/null | grep -oP '"name":"[^"]*"' | sed 's/"name":"//;s/"//')

    if [[ -z "$names" ]]; then
        log "WARN: Could not detect outputs, using defaults"
        OUTPUTS=("DP-4" "DP-3" "eDP-1")
        OUTPUT_X=(0 3840 7680)
        OUTPUT_Y=(0 0 1080)
        OUTPUT_W=(3840 3840 1920)
        OUTPUT_H=(2160 2160 1080)
        return
    fi

    # Positions from niri config
    for name in $names; do
        OUTPUTS+=("$name")
        case "$name" in
            DP-4)  OUTPUT_X+=(0);    OUTPUT_Y+=(0);    OUTPUT_W+=(3840); OUTPUT_H+=(2160) ;;  # left 4K
            DP-3)  OUTPUT_X+=(3840); OUTPUT_Y+=(0);    OUTPUT_W+=(3840); OUTPUT_H+=(2160) ;;  # right 4K (ASUS)
            eDP-1) OUTPUT_X+=(7680); OUTPUT_Y+=(1080); OUTPUT_W+=(1920); OUTPUT_H+=(1080) ;;  # laptop
            *)     OUTPUT_X+=(0);    OUTPUT_Y+=(0);    OUTPUT_W+=(1920); OUTPUT_H+=(1080)
                   log "WARN: Unknown output '$name'" ;;
        esac
    done

    # Sort by X position so indices are stable (left-to-right)
    local n=${#OUTPUTS[@]}
    for ((a = 0; a < n; a++)); do
        for ((b = a + 1; b < n; b++)); do
            if (( OUTPUT_X[b] < OUTPUT_X[a] )); then
                local tmp
                tmp="${OUTPUTS[$a]}";   OUTPUTS[$a]="${OUTPUTS[$b]}";   OUTPUTS[$b]="$tmp"
                tmp="${OUTPUT_X[$a]}";  OUTPUT_X[$a]="${OUTPUT_X[$b]}"; OUTPUT_X[$b]="$tmp"
                tmp="${OUTPUT_Y[$a]}";  OUTPUT_Y[$a]="${OUTPUT_Y[$b]}"; OUTPUT_Y[$b]="$tmp"
                tmp="${OUTPUT_W[$a]}";  OUTPUT_W[$a]="${OUTPUT_W[$b]}"; OUTPUT_W[$b]="$tmp"
                tmp="${OUTPUT_H[$a]}";  OUTPUT_H[$a]="${OUTPUT_H[$b]}"; OUTPUT_H[$b]="$tmp"
            fi
        done
    done

    log "Detected ${#OUTPUTS[@]} outputs: ${OUTPUTS[*]}"
}

setup() {
    echo "=== Auto-Retry Template Capture ==="
    echo ""
    echo "1. Make the 'Agent terminated due to error' dialog visible"
    echo "2. Press Enter here when ready"
    echo "3. Select the ENTIRE dialog (title to Retry button)"
    echo ""
    read -rp "Press Enter when dialog is visible..."

    mkdir -p "$CONFIG_DIR"
    grim -g "$(slurp)" "$TEMPLATE"

    local tw th
    tw=$(magick identify -format '%w' "$TEMPLATE")
    th=$(magick identify -format '%h' "$TEMPLATE")

    echo ""
    echo "Template saved: $TEMPLATE (${tw}x${th})"
    echo "Run './watcher.sh' to start watching."
}

watch() {
    if [[ ! -f "$TEMPLATE" ]]; then
        echo "ERROR: No template. Run './watcher.sh setup' first."
        exit 1
    fi
    if [[ ! -f "$MATCHER" ]]; then
        echo "ERROR: matcher.py not found at $MATCHER"
        exit 1
    fi

    mkdir -p "$CONFIG_DIR"

    local tw th
    tw=$(magick identify -format "%w" "$TEMPLATE")
    th=$(magick identify -format "%h" "$TEMPLATE")

    log "Watcher started. Template: ${tw}x${th}, scale: 1/${COORD_SCALE}"
    log "Outputs: ${OUTPUTS[*]}"

    # Resolve python env once (avoids nix-shell overhead per poll)
    log "Resolving Python environment..."
    local python_env
    python_env=$(nix-shell -p python3 python3Packages.opencv4 python3Packages.numpy \
        --run 'echo "$(which python3)|$PYTHONPATH"' 2>/dev/null)
    local python_bin="${python_env%%|*}"
    local python_path="${python_env#*|}"
    if [[ -z "$python_bin" || ! -x "$python_bin" ]]; then
        echo "ERROR: Could not resolve python3 via nix-shell"
        exit 1
    fi
    log "Python: $python_bin"

    while true; do
        log "Polling..."

        local found=0

        for i in "${!OUTPUTS[@]}"; do
            local output="${OUTPUTS[$i]}"
            local ox="${OUTPUT_X[$i]}"
            local oy="${OUTPUT_Y[$i]}"
            local shot="/tmp/autoretry_${output}.png"

            # Capture this output
            if ! grim -o "$output" "$shot" 2>/dev/null; then
                log "WARN: grim -o $output failed"
                continue
            fi

            # OpenCV template match (using pre-resolved python + PYTHONPATH)
            local result
            result=$(PYTHONPATH="$python_path" "$python_bin" "$MATCHER" "$TEMPLATE" "$shot" 2>/dev/null)

            if [[ "$result" == MATCH* ]]; then
                local score lx ly
                score=$(echo "$result" | awk '{print $2}')
                lx=$(echo "$result" | awk '{print $3}')
                ly=$(echo "$result" | awk '{print $4}')

                # Button position in GLOBAL pixel coords (output offset + local match + bottom-right inward)
                local btn_px=$((ox + lx + tw - 20))
                local btn_py=$((oy + ly + th - 20))

                # Convert to ydotool coordinates (pixels / 2)
                local btn_yx=$((btn_px / COORD_SCALE))
                local btn_yy=$((btn_py / COORD_SCALE))

                log "MATCH on $output! score=$score, dialog=($lx,$ly)"
                log "Click: global_px=($btn_px,$btn_py) ydotool=($btn_yx,$btn_yy)"
                found=1

                # Save focused window to restore later
                local prev_focus
                prev_focus=$(niri msg --json windows 2>/dev/null | \
                    grep -oP '"id":\d+[^}]*"is_focused":true' | \
                    grep -oP '"id":\d+' | grep -oP '\d+')

                # Warp cursor to global origin (leftmost monitor)
                warp_to_origin

                # Relative move from origin to target (effectively global absolute)
                ydotool mousemove -x "$btn_yx" -y "$btn_yy"
                #sleep 0.3
                ydotool click 0xC0

                # Restore focus
                if [[ -n "$prev_focus" ]]; then
                    niri msg action focus-window --id "$prev_focus" 2>/dev/null
                    log "Restored focus to window $prev_focus"
                fi

                break
            else
                log "$output: $result"
            fi

            rm -f "$shot" 2>/dev/null
        done

        rm -f /tmp/autoretry_*.png 2>/dev/null

        if [[ "$found" -eq 1 ]]; then
            log "Cooldown ${COOLDOWN}s..."
            sleep "$COOLDOWN"
        else
            sleep "$POLL_INTERVAL"
        fi
    done
}

detect_outputs

# Debug: move mouse to center of specified monitors
# Usage: ./watcher.sh debug 1,2,3
debug_move() {
    local monitors="$1"
    if [[ -z "$monitors" ]]; then
        echo "Usage: $0 debug 1[,2][,3]"
        echo "Monitors: 1=${OUTPUTS[0]:-?} 2=${OUTPUTS[1]:-?} 3=${OUTPUTS[2]:-?}"
        exit 1
    fi

    IFS=',' read -ra indices <<< "$monitors"

    for idx in "${indices[@]}"; do
        local i=$((idx - 1))
        if [[ $i -lt 0 || $i -ge ${#OUTPUTS[@]} ]]; then
            log "ERROR: Monitor $idx out of range (1-${#OUTPUTS[@]})"
            continue
        fi

        local output="${OUTPUTS[$i]}"
        local cx=$(( ${OUTPUT_X[$i]} + ${OUTPUT_W[$i]} / 2 ))
        local cy=$(( ${OUTPUT_Y[$i]} + ${OUTPUT_H[$i]} / 2 ))
        local yx=$(( cx / COORD_SCALE ))
        local yy=$(( cy / COORD_SCALE ))

        log "DEBUG: Moving to $output center: global=($cx,$cy) ydotool=($yx,$yy)"
        sleep 3

        # Warp cursor to global origin (leftmost monitor)
        warp_to_origin
        ydotool mousemove -x "$yx" -y "$yy"
    done

    log "DEBUG: Done."
}

case "${1:-watch}" in
    setup) setup ;;
    watch|"") watch ;;
    debug) debug_move "$2" ;;
    *) echo "Usage: $0 [setup|watch|debug 1,2,3]" ;;
esac
