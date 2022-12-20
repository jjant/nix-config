# nix-config

This repository holds the nix configuration for my hosts.

## Usage

Install [Nix][Nix].

#### Home Manager

For home-manager-only systems such as `odyssey`, use:

```bash
home-manager --flake .#odyssey switch
```

If you don't yet have [home-manager][home-manager] installed, you can use `nix-shell` to temporarily get it:

```bash
nix-shell -p home-manager
home-manager --flake .#odyssey switch --extra-experimental-features "flakes nix-command" --impure
```

[home-manager]: https://github.com/nix-community/home-manager/
[Nix]: https://nixos.org/download.html
