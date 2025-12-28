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

```bash
curl -fsSL https://raw.githubusercontent.com/tonhe/dotfiles/refs/heads/main/bootstrap.sh | bash
```

## Structure

```
.
├── bootstrap.sh                   # Enhanced setup script (cross-platform)
├── Brewfile                       # Homebrew packages (macOS)
├── Aptfile                        # APT packages (Linux)
├── CROSS_PLATFORM_SETUP.md        # Cross-platform documentation
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

## Customization

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

### NvChad (Leader: Space)

NvChad uses the spacebar as the leader key. Here are the most commonly used keybindings:

| Binding | Action |
|---------|--------|
| `<leader>th` | Toggle theme picker |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fw` | Find word (live grep) |
| `<leader>fb` | Find buffers |
| `<leader>fo` | Find old files (recent) |
| `<leader>fz` | Find in current buffer |
| `<leader>fm` | Format file (conform.nvim) |
| `<leader>ch` | Cheatsheet |
| `<leader>e` | Toggle nvim-tree file explorer |
| `<leader>h/v/n` | New horizontal/vertical split, new buffer |
| `<leader>x` | Close buffer |
| `<Tab>` | Next buffer |
| `<Shift-Tab>` | Previous buffer |
| `<Ctrl-n>` | Toggle nvim-tree |
| `<Ctrl-s>` | Save file |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover documentation |
| `<leader>ra` | Rename symbol (LSP) |
| `<leader>ca` | Code actions |

**File Tree (nvim-tree):**
- `a` - Create file/folder
- `r` - Rename
- `d` - Delete
- `x` - Cut
- `c` - Copy
- `p` - Paste
- `y` - Copy filename
- `Y` - Copy relative path

### Zsh Aliases

| Alias | Command |
|-------|---------|
| `ls` | `ls --color` |
| `vim` | `nvim` |
| `c` | `clear` |
| `cd` | `zoxide` (smart directory jumping) |

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
2. **Open Neovim** - most plugins install automatically - run :MasonInstallAll to finish plugin installation for Python env
3. **Start tmux** - press `prefix + I` to install plugins
4. **macOS only**: Restart your Mac for system defaults to take full effect

## License

MIT
