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
      ssh_connections = map (host: { inherit host; }) [
        "al2-x86_64"
        "al2-aarch64"
        "al2023-x86_64"
      ];
    };
  };

  # nixpkgs names the CLI `zeditor`; provide the upstream `zed` spelling too.
  home.packages = [
    (pkgs.writeShellScriptBin "zed" ''
      exec ${lib.getExe pkgs.zed-editor} "$@"
    '')
  ];
}
