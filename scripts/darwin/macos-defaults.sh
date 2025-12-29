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

    # GENERAL UI/UX

    sudo nvram SystemAudioVolume=" " 2>/dev/null || true

    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false


    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false


    defaults write com.apple.finder AppleShowAllFiles -bool true

    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true

    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    defaults write NSGlobalDomain com.apple.springing.delay -float 0

    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

    chflags nohidden ~/Library 2>/dev/null || true

    sudo chflags nohidden /Volumes 2>/dev/null || true


    defaults write com.apple.dock tilesize -int 36

    defaults write com.apple.dock mineffect -string "scale"

    defaults write com.apple.dock minimize-to-application -bool true

    defaults write com.apple.dock show-process-indicators -bool true

    defaults write com.apple.dashboard mcx-disabled -bool true

    defaults write com.apple.dock dashboard-in-overlay -bool true

    defaults write com.apple.dock autohide-delay -float 0

    defaults write com.apple.dock autohide-time-modifier -float 0

    defaults write com.apple.dock autohide -bool true

    defaults write com.apple.dock showhidden -bool true

    defaults write com.apple.dock show-recents -bool false


    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    defaults write com.apple.Safari AutoFillFromAddressBook -bool false
    defaults write com.apple.Safari AutoFillPasswords -bool false
    defaults write com.apple.Safari AutoFillCreditCardData -bool false
    defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

    defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

    defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true


    sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes" 2>/dev/null || true

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


    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    defaults write com.apple.ActivityMonitor IconType -int 5

    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0


    defaults write com.apple.terminal SecureKeyboardEntry -bool true

    defaults write com.apple.Terminal ShowLineMarks -int 0


    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true


    defaults write com.apple.TextEdit RichText -int 0

    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4


    mkdir -p "${HOME}/Pictures/Screenshots"
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

    defaults write com.apple.screencapture type -string "png"

    defaults write com.apple.screencapture disable-shadow -bool true


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
