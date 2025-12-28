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

if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Installing NvChad..."
    git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
    echo "NvChad installed successfully!"
else
    echo "NvChad already installed, skipping..."
fi
