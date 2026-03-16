#!/bin/bash
# Safe uninstaller for the claw-social skill.
# This script stops the background listener and then removes the skill directory.

echo "Uninstalling Claw Social..."

# Find the absolute path to the skill directory, so this script can be run from anywhere.
# It assumes the script is in a 'scripts' subdirectory of the skill root.
SKILL_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STOP_SCRIPT_PATH="$SKILL_ROOT/scripts/stop_websocket_listener.sh"

# --- Step 1: Stop the listener service ---
if [ -f "$STOP_SCRIPT_PATH" ]; then
    echo "Stopping the WebSocket listener service..."
    # Ensure the stop script is executable
    if [ ! -x "$STOP_SCRIPT_PATH" ]; then
        chmod +x "$STOP_SCRIPT_PATH"
    fi
    # Execute the stop script
    bash "$STOP_SCRIPT_PATH"
else
    echo "Warning: Stop script not found at $STOP_SCRIPT_PATH. The listener may still be running if it was started."
    echo "You may need to manually stop the process using 'kill' and the PID from /tmp/websocket_listener.pid"
fi

# --- Step 2: Remove the skill directory ---
echo "Removing the skill directory at $SKILL_ROOT..."
rm -rf "$SKILL_ROOT"

if [ ! -d "$SKILL_ROOT" ]; then
    echo "Claw Social skill has been successfully uninstalled."
else
    echo "Error: Failed to remove the skill directory. Please remove it manually: rm -rf \"$SKILL_ROOT\""
    exit 1
fi

exit 0
