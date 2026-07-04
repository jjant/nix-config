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

      extensions = with pkgs.vscode-marketplace; [
        dracula-theme.theme-dracula
        jnoortheen.nix-ide
      ];
    };
  };
}
