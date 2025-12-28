# Dotfiles

```
    ____        __  ____  __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/

```

Personal dotfiles with modular bash-based installation system.

**Platform Support:** macOS (Darwin) | Linux (coming soon)

## What's Included

- **Shell**: Zsh with modern CLI tools (eza, bat, ripgrep, fzf, zoxide)
- **Editor**: Neovim with [NVChad](https://nvchad.com/)
- **Terminal Multiplexer**: Tmux with sensible defaults and extensive inline documentation
- **Prompt**: [Starship](https://starship.rs/) cross-shell prompt
- **macOS**: Sensible system defaults, bloatware removal, custom Terminal.app theme
- **Utilities**: 25+ custom scripts in `~/bin/`
- **Documentation**: All configuration files include detailed inline comments

## Quick Start

### Fresh macOS Install

One-line remote installation:

```bash
curl -fsSL https://raw.githubusercontent.com/tonhe/dotfiles/main/bootstrap.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/tonhe/dotfiles.git ~/.dotfiles/repo
cd ~/.dotfiles/repo
./bootstrap.sh
```

The bootstrap will:
1. Install Xcode Command Line Tools
2. Install Homebrew and all packages
3. Install NvChad (Neovim config)
4. Apply macOS system preferences
5. Copy all dotfiles to your home directory
6. Set up `~/bin/` with custom scripts

### Maintenance Mode

After initial installation, run `bootstrap.sh` again for an interactive menu:

```bash
cd ~/.dotfiles/repo
./bootstrap.sh
```

Options include:
- **Update** - Pull latest changes and reconfigure
- **Reconfigure** - Re-run specific modules
- **Verify** - Check installation status
- **Show Log** - View detailed logs

## Structure

```
.
├── bootstrap.sh              # Main installation script
├── Brewfile                  # Homebrew packages (macOS)
├── lib/                      # Core libraries (colors, logging, UI, etc.)
├── scripts/                  # Installation modules
│   ├── all/                  # Cross-platform modules
│   │   ├── dotfiles.sh       # Copies config files and scripts
│   │   └── nvchad.sh         # NvChad setup
│   └── darwin/               # macOS-specific modules
│       ├── xcode-cli.sh      # Xcode CLI Tools
│       ├── homebrew.sh       # Homebrew installation
│       ├── macos-defaults.sh # System preferences
│       ├── setup-mtr.sh      # MTR network tool setup
│       ├── terminal-profile.sh # Terminal theme
│       └── remove-bloatware.sh # Remove unwanted apps
├── dot_zshrc                 # Zsh configuration
├── dot_tmux.conf             # Tmux config (heavily documented)
├── dot_config/               # XDG config directory
│   ├── nvim/                 # Neovim config
│   ├── alacritty/            # Alacritty terminal config
│   └── starship.toml         # Starship prompt
└── private_bin/              # Custom scripts → ~/bin/
```

## Customization

### Local Shell Overrides

Create `~/.zshrc.local` for machine-specific configuration (not tracked):

```bash
# Example: Custom aliases or environment variables
export EDITOR="code"
alias myproject="cd ~/Projects/myproject"
```

### Package Management

Edit `Brewfile` to add or remove packages:

```ruby
# Add your own packages
brew "your-package"
cask "your-app"
```

Then run `brew bundle` or re-run the bootstrap.

## Key Bindings

### Tmux (Prefix: Ctrl-Space)

| Binding | Action |
|---------|--------|
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `Alt + ↑/↓/←/→` | Navigate panes (no prefix!) |
| `Shift + ←/→` | Switch windows (no prefix!) |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + c` | New window |
| `prefix + r` | Reload config |
| `prefix + I` | Install plugins |
| `Ctrl-v` | Toggle rectangle select (copy mode) |

### NvChad (Leader: Space)

| Binding | Action |
|---------|--------|
| `<leader>th` | Toggle theme picker |
| `<leader>ff` | Find files |
| `<leader>fw` | Find word (grep) |
| `<leader>fb` | Find buffers |
| `<leader>fo` | Recent files |
| `<leader>fm` | Format file |
| `<leader>ch` | Cheatsheet |
| `<leader>e` | Toggle file tree |
| `<Ctrl-n>` | Toggle file tree |
| `<Ctrl-s>` | Save file |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover docs |
| `<leader>ra` | Rename symbol |
| `<leader>ca` | Code actions |

**File Tree:**
- `a` - Create | `r` - Rename | `d` - Delete
- `x` - Cut | `c` - Copy | `p` - Paste
- `y` - Copy filename | `Y` - Copy path

### Zsh Aliases & Tools

| Command | Mapped To |
|---------|-----------|
| `ls` | `eza` (modern ls) |
| `cat` | `bat` (syntax highlighting) |
| `cd` | `zoxide` (smart jumping) |
| `vim` | `nvim` |
| `c` | `clear` |

**fzf integration:**
- `Ctrl-R` - Command history search
- `Ctrl-T` - File search
- `Alt-C` - Directory search

## Post-Install

1. **Restart terminal** or run `source ~/.zshrc`
2. **Open Neovim** - Plugins install automatically. Run `:MasonInstallAll` for LSP servers
3. **Start tmux** - Press `prefix + I` to install plugins
4. **macOS**: Restart for all system preferences to take effect

## Troubleshooting

### View logs
```bash
cat ~/.dotfiles/bootstrap.log
```

### Re-run specific module
```bash
cd ~/.dotfiles/repo
./scripts/darwin/homebrew.sh install  # Example
```

### Check module status
```bash
./scripts/all/dotfiles.sh check
./scripts/darwin/macos-defaults.sh verify
```

### Clean reinstall
```bash
rm -rf ~/.dotfiles
# Then run bootstrap again
```

## Advanced

### Dry Run
```bash
./bootstrap.sh --dry-run
```

### Non-Interactive Mode
```bash
./bootstrap.sh --non-interactive
```

### Show Execution Log
```bash
./bootstrap.sh --show-log
```

## License

MIT
