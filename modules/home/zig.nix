{
  config,
  lib,
  pkgs,
  ...
}:
let
  # ZLS uses known-folders' native configuration directory on macOS.
  # https://github.com/ziglibs/known-folders/blob/d6d03830968cca6b7b9f24fd97ee348346a6905d/known-folders.zig#L627
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
