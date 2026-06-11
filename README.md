# nix-config

Nix configurations for all my hosts.

| Host | Platform | Type | Use |
|------|----------|------|-----|
| mac-m1 | aarch64-darwin | nix-darwin | Work laptop |
| al2-x86_64 | x86_64-linux | home-manager | Cloud desktop (AL2) |
| al2-aarch64 | aarch64-linux | home-manager | Cloud desktop (AL2) |
| al2023-x86_64 | x86_64-linux | home-manager | Cloud desktop (AL2023) |

## Structure

```
.
├── flake.nix
├── hosts/              # Per-host entry points
│   ├── mac-m1.nix
│   ├── al2-x86_64.nix
│   ├── al2-aarch64.nix
│   └── al2023-x86_64.nix
└── modules/
    ├── home/           # Shared home-manager modules (all hosts)
    │   ├── fish.nix, git.nix, neovim/, tmux/, starship.nix, bin/
    └── darwin/         # macOS-only (system defaults, homebrew, skhd, yabai)
```

## Usage

### Apply config (any host)

```bash
nix run .#activate
```

Auto-detects Darwin vs AL2 vs AL2023 and applies the right config. Works for both first-time setup and subsequent updates.

### Update flake inputs

```bash
nix run .#update
```

## First-time setup

### macOS

1. Install [Homebrew](https://brew.sh/)
2. Install Nix: `curl -L https://nixos.org/nix/install | sh`
3. Clone this repo and activate:
   ```bash
   git clone https://github.com/jjant/nix-darwin.git ~/personal/nix-darwin
   cd ~/personal/nix-darwin
   nix run .#activate
   ```
4. Change default shell: `chsh -s /run/current-system/sw/bin/fish`
5. Disable SIP for Yabai: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection

### Cloud desktops (AL2 / AL2023)

1. Install Nix:
   ```bash
   NIX_BUILD_GROUP_ID="$(awk -F' ' '$1 == "SYS_GID_MIN" { print $2 }' /etc/login.defs)" \
   NIX_FIRST_BUILD_UID="$(awk -F' ' '$1 == "SYS_UID_MIN" { print $2 }' /etc/login.defs)" \
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```
2. Enable flakes:
   ```bash
   mkdir -p ~/.config/nix && echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   ```
3. Activate:
   ```bash
   nix run github:jjant/nix-darwin#activate
   ```
