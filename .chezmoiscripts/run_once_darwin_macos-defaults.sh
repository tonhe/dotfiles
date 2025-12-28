#!/usr/bin/env bash
# =============================================================================
# run_once_darwin_macos-defaults.sh
# =============================================================================
# Description: Sets sensible macOS defaults for better UX and productivity
# OS Support: macOS only (Darwin)
# Run with: chezmoi apply (runs automatically once on macOS)
# Note: The "darwin" prefix ensures this only runs on macOS
#
# What this script does:
#   - Disables annoying UI features (boot sound, smart quotes, auto-correct)
#   - Enables power-user features (tap to click, fast key repeat, show hidden files)
#   - Configures Finder (show extensions, path bar, no .DS_Store on network)
#   - Optimizes Dock (smaller icons, faster animations, no recent apps)
#   - Enables developer features in Safari
#   - Creates convenient symlink to iCloud Drive
# =============================================================================

# Safety check: Only run on macOS (defense in depth)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping macOS defaults (not running on macOS)"
    exit 0
fi

echo "Setting macOS defaults..."

# Close System Preferences to prevent override
osascript -e 'tell application "System Preferences" to quit'

# Ask for admin password upfront
sudo -v

# Keep-alive: update existing sudo timestamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# =============================================================================
# General UI/UX
# =============================================================================

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# =============================================================================
# Trackpad, Mouse, Keyboard
# =============================================================================

# Trackpad: enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable full keyboard access for all controls (Tab in dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# =============================================================================
# Finder
# =============================================================================

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

# =============================================================================
# Dock
# =============================================================================

# Set the icon size of Dock items
defaults write com.apple.dock tilesize -int 48

# Minimize windows into their application's icon
#defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Speed up the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Auto-hide the Dock
#defaults write com.apple.dock autohide -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# =============================================================================
# Safari & WebKit
# =============================================================================

# Enable the Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# =============================================================================
# Terminal & iTerm2
# =============================================================================

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Don't display the annoying prompt when quitting iTerm
#defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# =============================================================================
# Activity Monitor
# =============================================================================

# Show the main window when launching
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# =============================================================================
# Screenshots
# =============================================================================

# Save screenshots to a dedicated folder
#mkdir -p "${HOME}/Screenshots"
#defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# Convenience Symlinks
# =============================================================================

# Create symlink to iCloud Drive for easier access
if [ ! -e "${HOME}/iCloudDrive" ]; then
    ln -s "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/iCloudDrive"
    echo "Created symlink: ~/iCloudDrive -> iCloud Drive"
else
    echo "Symlink ~/iCloudDrive already exists, skipping..."
fi

# =============================================================================
# Kill affected applications
# =============================================================================

echo "Restarting affected applications..."

for app in "Activity Monitor" \
    "Dock" \
    "Finder" \
    "Safari" \
    "SystemUIServer"; do
    killall "${app}" &>/dev/null || true
done

echo "Done! Note that some changes require a logout/restart to take effect."
