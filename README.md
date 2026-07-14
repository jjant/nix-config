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
├── flake.nix           # Inputs, Linux hosts (mkHome), apps
├── hosts/
│   └── mac-m1.nix      # Darwin host entry point
└── modules/
    ├── home/           # Shared home-manager modules (all hosts)
    │   ├── fish.nix, git.nix, neovim/, tmux/, starship.nix, bin/
    └── darwin/         # macOS-only (system defaults, homebrew, skhd, yabai)
```

The Linux cloud desktops are generated in `flake.nix` by a small `mkHome`
helper — they only differ in platform and prompt tag.

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

Homebrew itself is installed and owned by nix-homebrew during activation
(including trust for our non-official taps), so there's no manual Homebrew step.

1. Install Nix: `curl -L https://nixos.org/nix/install | sh`
2. Clone this repo and activate:
   ```bash
   git clone https://github.com/jjant/nix-darwin.git ~/personal/nix-darwin
   cd ~/personal/nix-darwin
   # The official installer doesn't enable flakes yet, so the very first run
   # needs them passed to the outer `nix`; activate propagates them to the
   # nested `nix run nix-darwin` call. Subsequent runs can use `nix run .#activate`.
   nix --extra-experimental-features "nix-command flakes" run .#activate
   ```
3. Change default shell: `chsh -s /run/current-system/sw/bin/fish`
4. Disable SIP for Yabai: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection
5. Open **Raycast** once manually to finish its setup — the Homebrew cask only
   downloads the app; it needs a first manual launch (grant permissions, etc.)
   before it works.

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
