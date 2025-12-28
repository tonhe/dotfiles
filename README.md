# Dotfiles 2.0

```
    ____        __  ____  __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/

    ___            __      __                   ___   ____
   / _ )___  ___  / /____ / /________ ____     |__ \ / __ \
  / _  / _ \/ _ \/ __(_-</ __/ __/ _ `/ _ \    __/ // / / /
 /____/\___/\___/\__/___/\__/_/  \_,_/ .__/   / __// /_/ /
                                    /_/      /___(_)____/
```

My personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

**Cross-platform support:** macOS (Darwin) and Linux (APT-based distros)

## What's Included

- **Shell**: Zsh with modern CLI tools (eza, bat, ripgrep, fzf, zoxide)
- **Editor**: Neovim with [NVChad](https://nvchad.com/)
- **Terminal Multiplexer**: Tmux with sensible defaults and extensive inline documentation
- **Prompt**: [Starship](https://starship.rs/) cross-shell prompt
- **macOS**: Sensible system defaults, bloatware removal, Terminal.app profile
- **Linux**: APT package support with cross-platform package equivalents
- **Fonts**: Nerd Fonts for icons and ligatures
- **Documentation**: All configuration files include detailed inline comments explaining every setting

## Quick Start

### Fresh Install (macOS or Linux)

**Preview what would be installed (dry-run mode):**
```bash
./bootstrap.sh --dry-run
```

**Full installation:**
```bash
./bootstrap.sh
```

**Or via curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/YOURUSERNAME/dotfiles/main/bootstrap.sh | bash
```

### Already Have Homebrew & Chezmoi

```bash
chezmoi init --apply YOURUSERNAME
```

## Bootstrap Script Features

The enhanced `bootstrap.sh` script provides:

- **Colorized output** with progress bars and spinners
- **Smart package detection** (Homebrew on macOS, APT on Linux)
- **Dry-run mode** (`--dry-run` or `--preview`) to preview changes without installing
- **Status indicators** for installed, skipped, and already-present items
- **Elapsed time tracking**
- **Step-by-step progress** (7 steps on macOS, 6 on Linux)
- **Cross-platform support** with automatic OS detection

**Options:**
- `--dry-run` or `--preview` - Preview what would be installed without making changes
- `--help` or `-h` - Show help message

### What It Looks Like

The bootstrap script features a beautiful interface with:
- ASCII art banner on startup
- Color-coded status messages:
  - Blue diamond `◆` - Items to be installed (dry-run)
  - Green checkmark `✓` - Successfully installed / Already present
  - Yellow warning `⚠` - Skipped items
  - Gray circle `○` - Skipped in dry-run mode
- Progress boxes showing current step (e.g., "STEP 3/7: Installing Homebrew")
- Completion summary with elapsed time
- Next steps box with clear instructions

## Structure

```
.
├── bootstrap.sh                   # Enhanced setup script (cross-platform)
├── Brewfile                       # Homebrew packages (macOS)
├── Aptfile                        # APT packages (Linux)
├── CROSS_PLATFORM_SETUP.md        # Cross-platform documentation
├── .chezmoi.toml.tmpl             # Chezmoi config template
├── dot_zshrc                      # Zsh configuration
├── dot_gitconfig.tmpl             # Git config (templated)
├── dot_gitignore_global           # Global gitignore
├── dot_tmux.conf                  # Tmux configuration (extensively documented)
├── dot_config/
│   ├── nvim/                      # Neovim config (NVChad)
│   └── starship.toml              # Starship prompt config
└── .chezmoiscripts/
    ├── run_once_darwin_macos-defaults.sh          # macOS system preferences
    ├── run_once_darwin_remove-bloatware.sh        # Remove unwanted macOS apps
    ├── run_once_darwin_setup-mtr.sh               # Configure mtr permissions
    ├── run_once_darwin_setup-terminal-profile.sh  # Import Terminal.app profile
    └── run_once_install-nvchad.sh                 # NVChad setup (cross-platform)
```

**Naming Convention:**
- `run_once_darwin_*.sh` - macOS-only scripts
- `run_once_linux_*.sh` - Linux-only scripts
- `run_once_*.sh` - Cross-platform scripts

## Chezmoi Basics

```bash
# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Edit a managed file
chezmoi edit ~/.zshrc

# Add a new file to be managed
chezmoi add ~/.some-config

# Update from remote
chezmoi update

# Re-run scripts
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## Customization

### Machine-Specific Config

The `.chezmoi.toml.tmpl` prompts for:
- Your name and email (for git)
- GitHub username
- Machine type (personal/work)

Work machines get additional git config for SSH.

### Local Overrides

Add machine-specific shell config to `~/.zshrc.local` (not tracked).

### Brewfile

Edit `Brewfile` to add/remove packages for your setup.

## Key Bindings

### Tmux (prefix: Ctrl-Space)

| Binding | Action |
|---------|--------|
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `Alt + ↑/↓/←/→` | Navigate panes (prefix-free) |
| `Shift + ←/→` | Switch windows (prefix-free) |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + c` | New window |
| `prefix + r` | Reload config |
| `prefix + I` | Install plugins |
| `Ctrl-v` | Toggle rectangle selection (copy mode) |

### Zsh Aliases

| Alias | Command |
|-------|---------|
| `ll` | `eza -la --icons --git` |
| `lg` | `lazygit` |
| `v` | `nvim` |
| `cza` | `chezmoi apply` |
| `cze` | `chezmoi edit` |

## Cross-Platform Support

### macOS (Darwin)
- Installs Xcode Command Line Tools
- Installs Homebrew and packages from `Brewfile`
- Applies macOS system preferences
- Removes bloatware apps
- Sets up Terminal.app profile

### Linux (APT-based)
- Detects package manager (currently supports APT)
- Installs packages from `Aptfile`
- Skips macOS-specific scripts
- Runs cross-platform setup scripts

See [CROSS_PLATFORM_SETUP.md](CROSS_PLATFORM_SETUP.md) for detailed documentation.

## Post-Install Steps

1. **Restart terminal** (or `source ~/.zshrc` / `source ~/.bashrc`)
2. **Open Neovim** - plugins install automatically
3. **Start tmux** - press `prefix + I` to install plugins
4. **macOS only**: Restart your Mac for system defaults to take full effect
5. **Review pending changes**: `chezmoi diff`
6. **Apply any remaining changes**: `chezmoi apply`

## License

MIT
