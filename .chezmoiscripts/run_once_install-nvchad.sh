#!/usr/bin/env bash
# =============================================================================
# run_once_install-nvchad.sh
# =============================================================================
# Description: Installs NvChad (Neovim configuration framework)
# OS Support: Cross-platform (macOS, Linux, BSD)
# Run with: chezmoi apply (runs automatically once)
# Note: No OS prefix - runs on all platforms
#
# What this script does:
#   - Checks if NvChad is already installed at ~/.config/nvim
#   - If not, clones NvChad from GitHub
#   - Uses shallow clone (--depth 1) for faster installation
#
# Prerequisites:
#   - git must be installed
#   - neovim must be installed
#
# After installation:
#   - Launch nvim for first-time setup
#   - NvChad will automatically install plugins
# =============================================================================

echo "Checking for NvChad..."

# Check for NvChad's init.lua specifically, not just the nvim directory
# This allows chezmoi to create the config directory structure first
if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    echo "Installing NvChad..."

    # Remove any existing partial nvim config (except our lua/ directory)
    if [ -d "$HOME/.config/nvim" ]; then
        # Backup our custom config
        if [ -d "$HOME/.config/nvim/lua" ]; then
            mv "$HOME/.config/nvim/lua" "$HOME/.config/nvim-lua-backup"
        fi
    fi

    # Clone NvChad starter template
    git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1

    # Restore our custom config
    if [ -d "$HOME/.config/nvim-lua-backup" ]; then
        cp -r "$HOME/.config/nvim-lua-backup/"* "$HOME/.config/nvim/lua/"
        rm -rf "$HOME/.config/nvim-lua-backup"
    fi

    echo "NvChad installed successfully!"
else
    echo "NvChad already installed, skipping..."
fi
