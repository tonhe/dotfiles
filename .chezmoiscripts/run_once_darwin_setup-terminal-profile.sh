#!/usr/bin/env bash
# =============================================================================
# run_once_darwin_setup-terminal-profile.sh
# =============================================================================
# Description: Import and set mySolarizedDark Terminal.app profile as default
# OS Support: macOS only (Darwin)
# Run with: chezmoi apply (runs automatically once on macOS)
# Note: The "darwin" prefix ensures this only runs on macOS
#
# What this script does:
#   - Imports the mySolarizedDark.terminal profile
#   - Sets it as the default profile for new Terminal windows
#   - Sets it as the startup profile
#
# Note: This only affects Terminal.app, not iTerm2 or other terminal emulators
# =============================================================================

# Safety check: Only run on macOS (defense in depth)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping Terminal.app setup (not running on macOS)"
    exit 0
fi

echo "Setting up Terminal profile..."

PROFILE_NAME="mySolarizedDark"
# Try to find the profile in home directory first, then in chezmoi source
if [ -f "$HOME/mySolarizedDark.terminal" ]; then
    PROFILE_PATH="$HOME/mySolarizedDark.terminal"
elif [ -f "$HOME/.local/share/chezmoi/mySolarizedDark.terminal" ]; then
    PROFILE_PATH="$HOME/.local/share/chezmoi/mySolarizedDark.terminal"
else
    PROFILE_PATH=""
fi

if [ -n "$PROFILE_PATH" ]; then
    echo "Found Terminal profile at: $PROFILE_PATH"

    # Import the profile by opening it
    open "$PROFILE_PATH"

    # Wait a moment for Terminal to process the import
    sleep 2

    # Set as default profile
    defaults write com.apple.Terminal "Default Window Settings" -string "$PROFILE_NAME"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE_NAME"

    echo "Terminal profile '$PROFILE_NAME' imported and set as default!"
    echo "Note: You may need to restart Terminal for changes to take full effect."
else
    echo "Warning: Terminal profile not found at $PROFILE_PATH"
    echo "Make sure the profile file is managed by chezmoi."
fi
