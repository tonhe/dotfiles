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
    log_info "Applying macOS system defaults..."

    # Close System Preferences to prevent override
    osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

    log_section "GENERAL UI/UX"

    log_info "Disabling boot sound..."
    sudo nvram SystemAudioVolume=" " 2>/dev/null || true

    log_info "Expanding save/print panels by default..."
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    log_info "Setting save location to disk (not iCloud)..."
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    log_info "Disabling automatic termination of inactive apps..."
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    log_info "Disabling auto-correct features..."
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    log_section "TRACKPAD, MOUSE, KEYBOARD"

    log_info "Enabling tap to click..."
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    log_info "Enabling full keyboard access..."
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    log_info "Setting fast key repeat rate..."
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    log_info "Disabling press-and-hold for key repeat..."
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    log_section "FINDER"

    log_info "Showing hidden files..."
    defaults write com.apple.finder AppleShowAllFiles -bool true

    log_info "Showing all filename extensions..."
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    log_info "Showing status and path bars..."
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true

    log_info "Keeping folders on top when sorting..."
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    log_info "Searching current folder by default..."
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    log_info "Disabling extension change warning..."
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    log_info "Enabling spring loading for directories..."
    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    defaults write NSGlobalDomain com.apple.springing.delay -float 0

    log_info "Avoiding creation of .DS_Store files on network/USB volumes..."
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    log_info "Using list view in all Finder windows by default..."
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    log_info "Disabling disk image verification..."
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    log_info "Automatically opening a new Finder window when a volume is mounted..."
    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    log_info "Showing item info near icons on desktop and in other views..."
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    log_info "Enabling snap-to-grid for icons..."
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    log_info "Increasing grid spacing for icons..."
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    log_info "Increasing icon size..."
    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    log_info "Showing Library folder..."
    chflags nohidden ~/Library 2>/dev/null || true

    log_info "Showing /Volumes folder..."
    sudo chflags nohidden /Volumes 2>/dev/null || true

    log_section "DOCK"

    log_info "Setting Dock icon size..."
    defaults write com.apple.dock tilesize -int 36

    log_info "Changing minimize/maximize window effect..."
    defaults write com.apple.dock mineffect -string "scale"

    log_info "Minimizing windows into application icon..."
    defaults write com.apple.dock minimize-to-application -bool true

    log_info "Showing indicator lights for open applications..."
    defaults write com.apple.dock show-process-indicators -bool true

    log_info "Disabling Dashboard..."
    defaults write com.apple.dashboard mcx-disabled -bool true

    log_info "Removing Dashboard from Spaces..."
    defaults write com.apple.dock dashboard-in-overlay -bool true

    log_info "Removing auto-hiding Dock delay..."
    defaults write com.apple.dock autohide-delay -float 0

    log_info "Removing animation when hiding/showing Dock..."
    defaults write com.apple.dock autohide-time-modifier -float 0

    log_info "Auto-hiding Dock..."
    defaults write com.apple.dock autohide -bool true

    log_info "Making Dock icons of hidden applications translucent..."
    defaults write com.apple.dock showhidden -bool true

    log_info "Disabling recent applications in Dock..."
    defaults write com.apple.dock show-recents -bool false

    log_section "SAFARI & WEBKIT"

    log_info "Enabling Safari debug menu..."
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

    log_info "Enabling Safari Develop menu and Web Inspector..."
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    log_info "Adding context menu item for showing Web Inspector..."
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    log_info "Disabling auto-filling..."
    defaults write com.apple.Safari AutoFillFromAddressBook -bool false
    defaults write com.apple.Safari AutoFillPasswords -bool false
    defaults write com.apple.Safari AutoFillCreditCardData -bool false
    defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

    log_info "Enabling 'Do Not Track'..."
    defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

    log_info "Updating extensions automatically..."
    defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

    log_section "SPOTLIGHT"

    log_info "Disabling Spotlight indexing for any volume that gets mounted..."
    sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes" 2>/dev/null || true

    log_info "Changing indexing order and disabling some search results..."
    defaults write com.apple.spotlight orderedItems -array \
        '{"enabled" = 1;"name" = "APPLICATIONS";}' \
        '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
        '{"enabled" = 1;"name" = "DIRECTORIES";}' \
        '{"enabled" = 1;"name" = "PDF";}' \
        '{"enabled" = 1;"name" = "FONTS";}' \
        '{"enabled" = 0;"name" = "DOCUMENTS";}' \
        '{"enabled" = 0;"name" = "MESSAGES";}' \
        '{"enabled" = 0;"name" = "CONTACT";}' \
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

    # Loading new settings
    killall mds 2>/dev/null || true
    sudo mdutil -i on / 2>/dev/null || true
    sudo mdutil -E / 2>/dev/null || true

    log_section "ACTIVITY MONITOR"

    log_info "Showing main window when launching Activity Monitor..."
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    log_info "Visualizing CPU usage in Dock icon..."
    defaults write com.apple.ActivityMonitor IconType -int 5

    log_info "Showing all processes in Activity Monitor..."
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    log_info "Sorting Activity Monitor results by CPU usage..."
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0

    log_section "TERMINAL"

    log_info "Enabling Secure Keyboard Entry in Terminal..."
    defaults write com.apple.terminal SecureKeyboardEntry -bool true

    log_info "Disabling line marks in Terminal..."
    defaults write com.apple.Terminal ShowLineMarks -int 0

    log_section "TIME MACHINE"

    log_info "Preventing Time Machine from prompting to use new hard drives as backup..."
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    log_section "TEXT EDIT"

    log_info "Using plain text mode for new TextEdit documents..."
    defaults write com.apple.TextEdit RichText -int 0

    log_info "Opening and saving files as UTF-8 in TextEdit..."
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

    log_section "SCREENSHOTS"

    log_info "Saving screenshots to ~/Pictures/Screenshots..."
    mkdir -p "${HOME}/Pictures/Screenshots"
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

    log_info "Saving screenshots in PNG format..."
    defaults write com.apple.screencapture type -string "png"

    log_info "Disabling shadow in screenshots..."
    defaults write com.apple.screencapture disable-shadow -bool true

    log_section "MISC"

    log_info "Creating iCloud Drive symlink..."
    if [[ ! -L "$HOME/iCloud" ]] && [[ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]]; then
        ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/iCloud"
        log_success "iCloud symlink created at ~/iCloud"
    fi

    # Mark as applied
    date +%Y-%m-%d > "$STATE_FILE"

    log_success "macOS defaults applied successfully"
    log_warn "Restart required for all changes to take effect"
    log_info "Some settings will take effect after logging out and back in"

    # Restart affected applications
    log_info "Restarting affected applications..."
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
    log_info "Re-applying macOS defaults..."
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
