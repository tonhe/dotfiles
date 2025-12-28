#!/usr/bin/env bash
# =============================================================================
# run_once_darwin_setup-mtr.sh
# =============================================================================
# Description: Configure mtr to run without root/sudo on macOS
# OS Support: macOS only (Darwin)
# Run with: chezmoi apply (runs automatically once on macOS)
# Note: The "darwin" prefix ensures this only runs on macOS
#
# What this script does:
#   - Finds mtr-packet binary (location depends on architecture)
#   - Sets ownership to root:wheel
#   - Sets setuid bit so mtr can access raw sockets without sudo
#
# Why this is needed:
#   mtr requires raw socket access for ICMP packets
#   Setting setuid allows non-root users to run mtr
# =============================================================================

# Safety check: Only run on macOS (defense in depth)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping mtr setup (not running on macOS)"
    exit 0
fi

echo "Configuring mtr permissions..."

# Determine mtr path based on architecture
if [[ $(uname -m) == "arm64" ]]; then
    MTR_PATH="/opt/homebrew/sbin/mtr-packet"
else
    MTR_PATH="/usr/local/sbin/mtr-packet"
fi

if [ -f "$MTR_PATH" ]; then
    echo "Found mtr at: $MTR_PATH"

    # Set ownership to root and set setuid bit
    sudo chown root:wheel "$MTR_PATH"
    sudo chmod u+s "$MTR_PATH"

    echo "mtr configured successfully! You can now run 'mtr' without sudo."
else
    echo "Warning: mtr not found at $MTR_PATH"
    echo "Make sure mtr is installed via Homebrew first: brew install mtr"
fi
