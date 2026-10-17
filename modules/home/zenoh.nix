{
  pkgs,
  lib,
  zenoh-ts,
  ...
}:
let
  # Standalone zenoh router + remote-api (WebSocket) plugin, for zenoh-ts
  # clients. Not in nixpkgs; built from the `zenoh-ts` flake input (pinned in
  # flake.lock). It embeds its own zenoh, so its version needn't match
  # `pkgs.zenoh`.
  zenoh-bridge-remote-api = pkgs.rustPlatform.buildRustPackage {
    pname = "zenoh-bridge-remote-api";
    inherit ((lib.importTOML "${zenoh-ts}/Cargo.toml").workspace.package) version;

    src = zenoh-ts;

    # Vendor from upstream's own Cargo.lock; its git deps (zenoh itself) are
    # fetched by the rev pinned there, so no hashes live in this repo.
    cargoLock = {
      lockFile = "${zenoh-ts}/Cargo.lock";
      allowBuiltinFetchGit = true;
    };

    cargoBuildFlags = [
      "--package"
      "zenoh-bridge-remote-api"
    ];

    doCheck = false;

    meta = {
      description = "Zenoh bridge exposing the remote API over WebSockets";
      homepage = "https://github.com/eclipse-zenoh/zenoh-ts";
      license = with lib.licenses; [
        epl20
        asl20
      ];
      mainProgram = "zenoh-bridge-remote-api";
    };
  };
in
{
  home.packages = [
    # zenohd + z_* examples + rest/storage-manager plugins
    pkgs.zenoh
    zenoh-bridge-remote-api
  ];

  # zenohd doesn't search its own store `lib/` for plugins, but does search
  # ~/.zenoh/lib (ahead of /opt/homebrew/lib and /usr/lib). Link each bundled
  # plugin there so `--rest-http-port` etc. load the matching build.
  home.file.".zenoh/lib" = {
    source = "${pkgs.zenoh}/lib";
    recursive = true;
  };
}
