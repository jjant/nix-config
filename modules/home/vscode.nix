{ pkgs, ... }:
# VS Code, installed and configured declaratively via home-manager.
#
# The app is built from nixpkgs (pkgs.vscode) and lives in the nix store,
# symlinked under ~/Applications/Home Manager Apps; mac-app-util (wired in
# hosts/mac-m1.nix) creates the trampoline that makes it visible to Spotlight
# and the Dock. Because it's a store app it does NOT self-update: bump it with
# `nix flake update` (nixpkgs) and extensions with
# `nix flake update nix-vscode-extensions`.
#
# Marketplace extensions come from the nix-vscode-extensions overlay as
# pkgs.vscode-marketplace.<publisher>.<name> (the "<publisher>.<name>" is the
# itemName from the extension's marketplace URL).
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # Serialised to settings.json.
      userSettings = {
        "editor.formatOnSave" = true;
        "editor.fontFamily" = "'SFMono Nerd Font', Menlo, monospace";
        "editor.fontSize" = 14;
        "files.trimTrailingWhitespace" = true;
        "workbench.colorTheme" = "Dracula Theme";
      };

      # Marketplace extensions from the nix-vscode-extensions overlay.
      extensions = with pkgs.vscode-marketplace; [
        # Theme
        dracula-theme.theme-dracula

        # Nix (nix-ide supersedes bbenoist.nix + nixfmt-vscode)
        jnoortheen.nix-ide

        # Rust
        rust-lang.rust-analyzer
        tamasfe.even-better-toml # TOML / Cargo.toml (taplo-backed)
        serayuzgur.crates # Cargo.toml dependency version hints
        mitsuhiko.insta # cargo-insta snapshot review

        # Python (acs-gpio-client bindings)
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-python.vscode-python-envs

        # Project-specific
        davidwang.ini-for-vscode # `ini` crate
        mrmlnc.vscode-json5 # zenoh .json5 config
        timonwong.shellcheck

        # Quality-of-life / docs
        aetonsi.disable-mru-tabs-behaviour
        bierner.markdown-mermaid
        yutengjing.vscode-archive
      ];
    };
  };
}
