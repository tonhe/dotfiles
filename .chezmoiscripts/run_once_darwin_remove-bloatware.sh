#!/usr/bin/env bash
# =============================================================================
# run_once_darwin_remove-bloatware.sh
# =============================================================================
# Description: Removes unwanted pre-installed macOS applications
# OS Support: macOS only (Darwin)
# Run with: chezmoi apply (runs automatically once on macOS)
# Note: The "darwin" prefix ensures this only runs on macOS
#
# What this script removes:
#   - Media apps: GarageBand, iMovie, Music, TV, Podcasts
#   - iWork suite: Keynote, Numbers, Pages
#   - Other: News, Stocks, Home, Maps, Chess, FaceTime
#
# WARNING: This requires sudo and will permanently delete these apps
# You can always re-download them from the Mac App Store if needed
# =============================================================================

# Safety check: Only run on macOS (defense in depth)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping bloatware removal (not running on macOS)"
    exit 0
fi

echo "Removing unwanted macOS apps..."

# List of apps to remove
APPS_TO_REMOVE=(
    "GarageBand"
    "iMovie"
    "Keynote"
    "Numbers"
    "Pages"
    "News"
    "Stocks"
    "Home"
    "Podcasts"
    "TV"
    "Music"
    "Maps"
    "Chess"
    "FaceTime"
)

for app in "${APPS_TO_REMOVE[@]}"; do
    if [ -d "/Applications/${app}.app" ]; then
        echo "Removing ${app}..."
        sudo rm -rf "/Applications/${app}.app"
        echo "✓ Removed: ${app}"
    else
        echo "⊘ Not found: ${app}"
    fi
done

echo "Bloatware removal complete!"
echo "Note: You can always re-download these apps from the Mac App Store if needed."
