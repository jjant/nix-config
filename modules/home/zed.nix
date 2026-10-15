{ pkgs, lib, ... }:
{
  # Mac-only import (hosts/mac-m1.nix). mac-app-util exposes Zed.app to
  # Spotlight; the Linux desks get bin/zed.sh instead of a GUI installation.
  programs.zed-editor = {
    enable = true;
    extensions = [ "zig" ];
    userSettings = {
      auto_update = false;
      # Use the ZLS managed by Nix on the host running the server.
      lsp.zls.binary = {
        path = "zls";
        arguments = [ ];
      };
      # Reuse the WSSH aliases in ssh.nix. Zed installs its matching headless
      # server on the desk automatically when first connecting.
      ssh_connections = map (host: { inherit host; }) (
        lib.attrNames (lib.filterAttrs (_: host: host ? hostname) (import ../../hosts))
      );
    };
    # Cycle tabs in positional order instead of the default MRU tab switcher.
    # cmd-1..8 select tab N and cmd-9 the last one, as in browsers. Zed's
    # default (from VS Code) focuses pane N, splitting if it doesn't exist.
    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-tab" = "pane::ActivateNextItem";
          "ctrl-shift-tab" = "pane::ActivatePreviousItem";
          "cmd-9" = "pane::ActivateLastItem";
        }
        // lib.listToAttrs (
          lib.genList (
            i:
            lib.nameValuePair "cmd-${toString (i + 1)}" [
              "pane::ActivateItem"
              i
            ]
          ) 8
        );
      }
    ];
  };

  # nixpkgs names the CLI `zeditor`; provide the upstream `zed` spelling too.
  home.packages = [
    (pkgs.writeShellScriptBin "zed" ''
      exec ${lib.getExe pkgs.zed-editor} "$@"
    '')
  ];
}
