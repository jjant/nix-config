{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support"
    else
      config.xdg.configHome;
in
{
  home.packages = [
    pkgs.zig_0_16
    pkgs.zls_0_16
  ];

  # ZLS must use the matching compiler on whichever host runs the server,
  # including remote editor sessions. Each host gets its own Nix store path.
  home.file."${configDir}/zls.json".text = builtins.toJSON {
    zig_exe_path = lib.getExe pkgs.zig_0_16;
  };
}
