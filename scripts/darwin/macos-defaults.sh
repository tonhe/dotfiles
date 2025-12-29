#!/usr/bin/env bash
# =============================================================================
# macos-defaults.sh - Sensible macOS System Defaults
# =============================================================================

# =============================================================================
# Module Metadata
# =============================================================================
MODULE_NAME="macOS System Defaults"
MODULE_DESC="Configure sensible macOS defaults for better UX"
MODULE_DEPS=()
MODULE_ORDER=40
MODULE_CATEGORY="configuration"

# State file to track if defaults have been applied
STATE_FILE="$HOME/.macos-defaults-applied"

# =============================================================================
# Module Functions
# =============================================================================

is_installed() {
    [[ -f "$STATE_FILE" ]]
}

get_version() {
    if is_installed; then
        cat "$STATE_FILE" 2>/dev/null || echo "applied"
    else
        echo "not applied"
    fi
}

install() {

    # Close System Preferences to prevent override
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

    # Start spinner for applying all defaults
    start_spinner "Applying macOS system defaults"

    # =============================================================================
    # General UI/UX
    # =============================================================================

    # Dark Mode
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

    # Icon size: 16 (very small!)
    defaults write com.apple.dock tilesize -int 16

    # Magnification: enabled
    defaults write com.apple.dock magnification -bool true

    # Magnification size: 128 (maximum)
    defaults write com.apple.dock largesize -int 128

    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" " 2>/dev/null || true

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

    # Disable sharing focus across devices
    defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
    defaults write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false

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

    # Enable two-finger tap/click for right-click
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

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

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Enable spring loading for directories
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    defaults write NSGlobalDomain com.apple.springing.delay -float 0

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Disable disk image verification
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    # Automatically open a new Finder window when a volume is mounted
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    # Show item info near icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    # Snap-to-grid for icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    # Increase grid spacing for icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    # Increase the size of icons on the desktop and in other icon views
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    # Show the ~/Library folder
    chflags nohidden ~/Library 2>/dev/null || true

    # Show the /Volumes folder
    sudo chflags nohidden /Volumes 2>/dev/null || true

    # =============================================================================
    # Dock
    # =============================================================================

    # Set the icon size of Dock items
    defaults write com.apple.dock tilesize -int 36

    # Change minimize/maximize window effect
    defaults write com.apple.dock mineffect -string "scale"

    # Minimize windows into their application's icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Show indicator lights for open applications
    defaults write com.apple.dock show-process-indicators -bool true

    # Disable Dashboard
    defaults write com.apple.dashboard mcx-disabled -bool true

    # Don't show Dashboard as a Space
    defaults write com.apple.dock dashboard-in-overlay -bool true

    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0

    # Speed up the animation when hiding/showing the Dock
    defaults write com.apple.dock autohide-time-modifier -float 0

    # Auto-hide the Dock
    #defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # Don't show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false

    # =============================================================================
    # Safari & WebKit
    # =============================================================================
    # Note: Safari preferences may fail to write due to sandboxing in newer macOS versions.
    # These settings are best configured manually in Safari's preferences.

    # Add a context menu item for showing the Web Inspector in web views
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true 2>/dev/null || true

    # Safari-specific settings (may fail on sandboxed systems, errors suppressed)
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true 2>/dev/null || true
    defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true 2>/dev/null || true
    defaults write com.apple.Safari AutoFillFromAddressBook -bool false 2>/dev/null || true
    defaults write com.apple.Safari AutoFillPasswords -bool false 2>/dev/null || true
    defaults write com.apple.Safari AutoFillCreditCardData -bool false 2>/dev/null || true
    defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false 2>/dev/null || true
    defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true 2>/dev/null || true
    defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true 2>/dev/null || true

    # =============================================================================
    # Spotlight
    # =============================================================================

    # Disable Spotlight indexing for any volume that gets mounted
    sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes" 2>/dev/null || true

    # Change indexing order and disable some search results
    defaults write com.apple.spotlight orderedItems -array \
        '{"enabled" = 1;"name" = "APPLICATIONS";}' \
        '{"enabled" = 0;"name" = "SYSTEM_PREFS";}' \
        '{"enabled" = 0;"name" = "DIRECTORIES";}' \
        '{"enabled" = 0;"name" = "PDF";}' \
        '{"enabled" = 0;"name" = "FONTS";}' \
        '{"enabled" = 0;"name" = "DOCUMENTS";}' \
        '{"enabled" = 0;"name" = "MESSAGES";}' \
        '{"enabled" = 1;"name" = "CONTACT";}' \
        '{"enabled" = 0;"name" = "EVENT_TODO";}' \
        '{"enabled" = 0;"name" = "IMAGES";}' \
        '{"enabled" = 0;"name" = "BOOKMARKS";}' \
        '{"enabled" = 0;"name" = "MUSIC";}' \
        '{"enabled" = 0;"name" = "MOVIES";}' \
        '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
        '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
        '{"enabled" = 0;"name" = "SOURCE";}' \
        '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
        '{"enabled" = 0;"name" = "MENU_OTHER";}' \
        '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
        '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
        '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
        '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

    # Load new settings by restarting Spotlight
    killall mds 2>/dev/null || true
    sudo mdutil -i on / 2>/dev/null || true
    sudo mdutil -E / 2>/dev/null || true

    # =============================================================================
    # Activity Monitor
    # =============================================================================

    # Show the main window when launching
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    # Visualize CPU usage in the Dock icon
    defaults write com.apple.ActivityMonitor IconType -int 5

    # Show all processes
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    # Sort by CPU usage
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0

    # =============================================================================
    # Terminal
    # =============================================================================

    # Enable Secure Keyboard Entry in Terminal.app
    defaults write com.apple.terminal SecureKeyboardEntry -bool true

    # Disable line marks
    defaults write com.apple.Terminal ShowLineMarks -int 0

    # Only use UTF-8 in Terminal.app
    defaults write com.apple.terminal StringEncodings -array 4

    # Close Terminal windows when shell exits cleanly
    defaults write com.apple.Terminal ShellExitAction -int 2


    # =============================================================================
    # Time Machine
    # =============================================================================

    # Prevent Time Machine from prompting to use new hard drives as backup volume
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    # =============================================================================
    # TextEdit
    # =============================================================================

    # Use plain text mode for new TextEdit documents
    defaults write com.apple.TextEdit RichText -int 0

    # Open and save files as UTF-8 in TextEdit
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

    # =============================================================================
    # Screenshots
    # =============================================================================

    # Save screenshots to dedicated folder
    mkdir -p "${HOME}/Pictures/Screenshots"
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

    # Save screenshots in PNG format
    defaults write com.apple.screencapture type -string "png"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # =============================================================================
    # Convenience Symlinks
    # =============================================================================

    # Create symlink to iCloud Drive for easier access
    if [[ ! -L "$HOME/iCloudDrive" ]] && [[ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]]; then
        ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/iCloudDrive"
    fi

    # Mark as applied
    date +%Y-%m-%d > "$STATE_FILE"

    # Stop spinner before showing results
    stop_spinner

    log_success "macOS defaults applied successfully"
    log_warn "Restart required for all changes to take effect"
    log_info "Some settings will take effect after logging out and back in"

    # Restart affected applications
    for app in "Activity Monitor" "Dock" "Finder" "SystemUIServer"; do
        killall "${app}" &>/dev/null || true
    done

    return 0
}

uninstall() {
    log_warn "Reverting macOS defaults is not recommended"
    log_info "Most settings can be changed manually in System Preferences"

    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log_success "State file removed"
    fi

    return 0
}

reconfigure() {
    rm -f "$STATE_FILE"
    install
}

verify() {
    if ! is_installed; then
        log_warn "macOS defaults have not been applied"
        return 1
    fi

    # Check a few key settings
    local tap_to_click=$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 2>/dev/null || echo "0")
    local show_hidden=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "0")

    if [[ "$tap_to_click" == "1" ]] && [[ "$show_hidden" == "1" ]]; then
        log_success "macOS defaults are applied and active"
        return 0
    else
        log_warn "Some macOS defaults may not be active (restart required)"
        return 1
    fi
}

# =============================================================================
# Module Execution Handler
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "${NORD0}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        LIB_DIR="$(cd "${SCRIPT_DIR}/../../lib" && pwd)"
        source "${LIB_DIR}/colors.sh"
        source "${LIB_DIR}/logger.sh"
        source "${LIB_DIR}/ui.sh"
        source "${LIB_DIR}/utils.sh"
        source "${LIB_DIR}/state.sh"
    fi

    case "${1:-}" in
        check) is_installed; exit $? ;;
        version) get_version; exit $? ;;
        install) install; exit $? ;;
        uninstall) uninstall; exit $? ;;
        reconfigure) reconfigure; exit $? ;;
        verify) verify; exit $? ;;
        info)
            echo "Name: ${MODULE_NAME}"
            echo "Description: ${MODULE_DESC}"
            echo "Category: ${MODULE_CATEGORY}"
            echo "Order: ${MODULE_ORDER}"
            echo "Dependencies: ${MODULE_DEPS[*]}"
            exit 0
            ;;
        *) echo "Usage: $0 {check|version|install|uninstall|reconfigure|verify|info}"; exit 1 ;;
    esac
fi
