#!/usr/bin/env bash
# Niri Window Startup Layout Script
# Launches applications and positions them on specific workspaces
#
# Usage: ./startup-layout.sh
# Add to niri config: spawn-at-startup "/path/to/startup-layout.sh"

set -euo pipefail

# Wait for niri to be ready
sleep 2

# Helper: Find window ID by title substring (waits up to 10 seconds)
find_window_by_title() {
    local title_match="$1"
    local timeout=10
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local window_id
        window_id=$(niri msg -j windows | jq -r --arg t "$title_match" '.[] | select(.title | contains($t)) | .id' | head -1)
        if [ -n "$window_id" ]; then
            echo "$window_id"
            return 0
        fi
        sleep 0.5
        elapsed=$((elapsed + 1))
    done
    return 1
}

# Helper: Launch app, wait for window, move to workspace
launch_and_place() {
    local app_cmd="$1"
    local title_match="$2"
    local target_workspace="$3"
    local target_monitor="$4"
    
    echo "Launching: $app_cmd (looking for '$title_match')"
    
    # Launch the app
    eval "$app_cmd" &
    sleep 2
    
    # Find the window
    local window_id
    if window_id=$(find_window_by_title "$title_match"); then
        echo "  Found window ID: $window_id"
        
        # Focus the window
        niri msg action focus-window --id "$window_id"
        sleep 0.2
        
        # Move to target monitor first (if not already there)
        niri msg action focus-monitor "$target_monitor"
        sleep 0.1
        
        # Move column to target workspace
        niri msg action move-column-to-workspace "$target_workspace"
        sleep 0.3
        
        echo "  Moved to workspace $target_workspace on $target_monitor"
    else
        echo "  WARNING: Could not find window for '$title_match'"
    fi
}

echo "=== Starting Niri Window Layout Script ==="

# --- Launch PHPStorm first (goes to workspace 13, column 1) ---
launch_and_place "phpstorm" "storage" 13 "DP-5"

# --- Launch Antigravity windows ---

# storage - workspace 13, column 2 (same workspace as PHPStorm)
launch_and_place "antigravity ~/Projects/sybita/frankenphp/storage" "storage - Antigravity" 13 "DP-5"

# api-structure - workspace 10, column 1
launch_and_place "antigravity ~/Projects/sybita/concept/api-structure" "api-structure" 10 "DP-5"

# infrastructure - workspace 10, column 2 (same workspace as api-structure)
launch_and_place "antigravity ~/Projects/sybita/infrastructure" "infrastructure" 10 "DP-5"

# Nixos-Setup - workspace 1, column 2
launch_and_place "antigravity ~/Nixos-Setup" "Nixos-Setup" 1 "DP-5"

echo "=== Layout script completed ==="
