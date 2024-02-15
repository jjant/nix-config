# nix-darwin

Configuration for my Darwin hosts.


| Host name  | Platform | Use |
| ------------- | ------------- | --|
| discovery  | ARM64 Darwin  | Work laptop |
| odyssey  | ARM64 Linux  | Cloud desktop |

## Installation

### Prerequisites 
- Homebrew must be installed manually. See: https://brew.sh/.


### First time setup
After doing the first `darwin-rebuild switch`:

TODO:
- Change default shell to Nix-managed fish

```terminal
chsh -s /run/current-system/sw/bin/fish
```

- Disable SIP for Yabai: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection.
