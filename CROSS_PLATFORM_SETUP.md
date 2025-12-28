# Cross-Platform Dotfiles Setup

This document explains the cross-platform setup for these dotfiles.

## OS Support

**macOS (Darwin)** - Fully supported
**Linux (APT-based)** - Debian, Ubuntu, Pop!_OS, Linux Mint, etc.
**Other Linux** - Not yet implemented (DNF, YUM, Pacman)

## How It Works

### Automatic OS Detection

The dotfiles automatically detect your OS and run the appropriate setup:

1. **macOS:**
   - Installs Xcode Command Line Tools
   - Installs Homebrew
   - Installs packages from `Brewfile`
   - Runs macOS-specific scripts (prefixed with `darwin_`)

2. **Linux (APT):**
   - Detects package manager (apt, dnf, yum, pacman)
   - Installs packages from `Aptfile` (APT only for now)
   - Skips macOS-specific scripts
   - Runs cross-platform scripts

### Script Naming Convention

Chezmoi uses file prefixes to control which scripts run on which OS:

- `run_once_darwin_*.sh` - **macOS only** (e.g., `run_once_darwin_macos-defaults.sh`)
- `run_once_linux_*.sh` - **Linux only** (none currently)
- `run_once_*.sh` - **All platforms** (e.g., `run_once_install-nvchad.sh`)

### Defense in Depth

Every OS-specific script also has a guard at the top:

```bash
# Safety check: Only run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping (not running on macOS)"
    exit 0
fi
```

This ensures scripts won't break if run manually.

## File Structure

```
dotfiles-new/
├── bootstrap.sh              # Cross-platform bootstrap script
├── Brewfile                  # macOS packages (via Homebrew)
├── Aptfile                   # Linux packages (APT-based distros)
├── dot_tmux.conf            # Cross-platform tmux config
├── dot_zshrc                # Cross-platform zsh config
├── dot_gitconfig.tmpl       # Cross-platform git config
└── .chezmoiscripts/
    ├── run_once_darwin_macos-defaults.sh          # macOS only
    ├── run_once_darwin_remove-bloatware.sh        # macOS only
    ├── run_once_darwin_setup-mtr.sh               # macOS only
    ├── run_once_darwin_setup-terminal-profile.sh  # macOS only
    └── run_once_install-nvchad.sh                 # All platforms
```

## Current Scripts

### macOS Only (darwin_*)

| Script | What It Does |
|--------|--------------|
| `run_once_darwin_macos-defaults.sh` | Sets macOS system preferences (Finder, Dock, keyboard, etc.) |
| `run_once_darwin_remove-bloatware.sh` | Removes unwanted macOS apps (GarageBand, iMovie, etc.) |
| `run_once_darwin_setup-mtr.sh` | Configures mtr permissions for Homebrew installation |
| `run_once_darwin_setup-terminal-profile.sh` | Imports Solarized Dark Terminal.app profile |

### Cross-Platform

| Script | What It Does |
|--------|--------------|
| `run_once_install-nvchad.sh` | Installs NvChad (Neovim config) - works on macOS & Linux |

## Package Equivalents

### Fully Cross-Platform (Same on macOS & Linux)

These install with the same command everywhere:

- git, tmux, neovim, zsh, curl, wget
- nmap, masscan, wireshark, tcpdump
- mtr, iperf3, socat
- openvpn, wireguard-tools
- openssl, httpie
- iftop, bmon
- hydra, hashcat, john, sqlmap, nikto, aircrack-ng
- jq, tree, ripgrep, fzf

### Platform-Specific Packages

Some tools have different package names or need manual installation:

| Tool | macOS (Homebrew) | Linux (APT) |
|------|------------------|-------------|
| DNS tools | `bind` | `dnsutils` |
| Modern find | `fd` | `fd-find` (command: `fdfind`) |
| Modern ls | `eza` | Manual install needed |
| Git delta | `delta` | Manual install needed |
| Bandwidth monitor | `bandwhich` | Manual install needed |
| GitHub CLI | `gh` | Manual install or PPA |
| Lazy git | `lazygit` | Manual install needed |
| Dog DNS | `dog` | Manual install needed |
| AWS CLI | `awscli` | `pip3 install awscli` |
| Terraform | `terraform` | Manual download |

### macOS Casks (No Linux Equivalent)

These are macOS applications, not available on Linux:

- `claude-code`, `bartender`, `firefox`, `discord`, `tailscale`
- `visual-studio-code`, `1password`
- Fonts: `font-*-nerd-font` (need manual install on Linux)
- Mac App Store apps (Xcode, Amphetamine, etc.)

## Testing Instructions

### Testing on macOS

```bash
# Clone your dotfiles repo
git clone https://github.com/YOURUSERNAME/dotfiles.git ~/dotfiles-test
cd ~/dotfiles-test

# Run bootstrap
./bootstrap.sh

# Expected behavior:
# - Installs Homebrew
# - Installs packages from Brewfile
# - Runs darwin_* scripts
# - Skips Aptfile
```

### Testing on Linux (APT-based)

```bash
# Clone your dotfiles repo
git clone https://github.com/YOURUSERNAME/dotfiles.git ~/dotfiles-test
cd ~/dotfiles-test

# Run bootstrap
./bootstrap.sh

# Expected behavior:
# - Detects apt package manager
# - Installs packages from Aptfile
# - Skips darwin_* scripts
# - Runs cross-platform scripts
```

### Dry Run (Safer Testing)

If you want to test without actually changing your system:

```bash
# Review what bootstrap.sh will do
cat bootstrap.sh

# Review what packages will be installed
# macOS:
cat Brewfile

# Linux:
cat Aptfile

# Review what scripts will run
ls -la .chezmoiscripts/

# On macOS, these will run:
ls -la .chezmoiscripts/run_once_darwin_*

# On Linux, only this will run:
ls -la .chezmoiscripts/run_once_install-nvchad.sh
```

## Notes for APT-Based Linux

### Packages That Need Manual Installation

The `Aptfile` includes notes about packages that need manual installation:

1. **eza** (modern ls replacement)
   ```bash
   # Download from https://github.com/eza-community/eza/releases
   ```

2. **delta** (git diff tool)
   ```bash
   # Download from https://github.com/dandavison/delta/releases
   ```

3. **bandwhich** (bandwidth monitor)
   ```bash
   # Download from https://github.com/imsnif/bandwhich/releases
   ```

4. **GitHub CLI**
   ```bash
   # See https://github.com/cli/cli/blob/trunk/docs/install_linux.md
   ```

5. **Nerd Fonts**
   ```bash
   mkdir -p ~/.local/share/fonts
   cd ~/.local/share/fonts
   wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
   unzip FiraCode.zip
   fc-cache -fv
   ```

### Alternative Package Managers

If a package isn't in apt, you can also try:

- **Snap:** `snap install <package>`
- **Flatpak:** `flatpak install <package>`
- **Pip:** `pip3 install --user <package>`
- **Cargo:** `cargo install <package>` (Rust tools)

## Future Expansion

When you're ready to support more Linux distros, create:

- `Dnffile` - Fedora/RHEL package equivalents
- `Pacmanfile` - Arch Linux package equivalents
- Update `bootstrap.sh` to auto-select the right file

## Troubleshooting

### Linux: "Package not found"

Some packages have different names on different Ubuntu versions:

```bash
# If a package fails, search for it:
apt search <package-name>

# Or check if it needs a PPA:
# Example for GitHub CLI:
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages
```

### Linux: "fd-find vs fd"

On Debian/Ubuntu, the `fd` tool is installed as `fdfind` to avoid conflicts:

```bash
# Create an alias in your .zshrc or .bashrc:
alias fd='fdfind'
```

### macOS: Homebrew path issues

If brew commands aren't found after installation:

```bash
# For Apple Silicon:
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel:
eval "$(/usr/local/bin/brew shellenv)"
```

## Documentation

All scripts have extensive inline documentation:

- **What they do** - High-level description
- **OS support** - Which platforms they run on
- **Prerequisites** - What needs to be installed first
- **Why certain steps are needed** - Rationale for each action

Example from `run_once_darwin_macos-defaults.sh`:

```bash
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
#   ...
```

## Summary

Your dotfiles are now **cross-platform ready** with:

- Smart OS detection
- Platform-specific package lists
- OS-specific scripts with naming convention
- Defense-in-depth guards
- Comprehensive documentation
- APT-based Linux support

Test on your APT-based Linux systems and expand to other distros when needed!
