{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.zig_0_16
    pkgs.zls_0_16
  ];

  # ZLS must use the matching compiler on whichever host runs the server,
  # including remote editor sessions. Each host gets its own Nix store path.
  xdg.configFile."zls.json".text = builtins.toJSON {
    zig_exe_path = lib.getExe pkgs.zig_0_16;
  };

  # ZLS uses known-folders' native macOS path; alias it to the XDG config.
  # https://github.com/ziglibs/known-folders/blob/d6d03830968cca6b7b9f24fd97ee348346a6905d/known-folders.zig#L627
  home.file."Library/Application Support/zls.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/zls.json";
  };
}
