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
        # Skip Remote-SSH's "what OS is this host?" prompt for the dev-desk
        # aliases (modules/home/ssh.nix) that the desks' `code` command
        # (modules/home/bin/code.sh) attaches back to.
        "remote.SSH.remotePlatform" = {
          "al2-x86_64" = "linux";
          "al2-aarch64" = "linux";
          "al2023-x86_64" = "linux";
        };
        # Never prompt for Workspace Trust. Folders opened from the cloud
        # desks over Remote-SSH (the `code` flow above) would otherwise ask
        # on every new folder, and VS Code can't scope this per remote:
        # security.workspace.trust.enabled is application-scoped (ignored in
        # remote/workspace settings) and the trusted-folder list lives in
        # VS Code's internal state DB, not settings.json. Everything opened
        # on this Mac is our own code, so trust it all.
        "security.workspace.trust.enabled" = false;
        "workbench.colorTheme" = "Dracula Theme";
      };

      # Marketplace extensions from the nix-vscode-extensions overlay.
      extensions = with pkgs.vscode-marketplace; [
        # Theme
        dracula-theme.theme-dracula

        # Nix (nix-ide supersedes bbenoist.nix + nixfmt-vscode)
        jnoortheen.nix-ide

        # Remote-SSH: edit on the cloud desks from this Mac. Also what the
        # desks' `code` command drives (modules/home/bin/code.sh -> the
        # mac-open-recv `code` mode -> vscode-remote:// URIs).
        ms-vscode-remote.remote-ssh

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
