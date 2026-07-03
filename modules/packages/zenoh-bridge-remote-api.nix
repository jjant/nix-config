{ lib
, stdenv
, fetchzip
, autoPatchelfHook
}:

# zenoh-bridge-remote-api has no crates.io/nixpkgs packaging, and its
# Cargo.lock pins the whole `zenoh` crate family to a git branch rather than
# a released version, which makes building it from source with
# rustPlatform.buildRustPackage impractical to keep reproducible.
#
# Upstream (github.com/eclipse-zenoh/zenoh-ts) does publish prebuilt,
# self-contained per-platform binaries as GitHub release assets, so we fetch
# those directly instead. Bumping this package to a new release is a matter
# of updating `version` and the four `hash` fields below (one per Nix
# system) to match the new release's asset checksums, listed at:
#   https://github.com/eclipse-zenoh/zenoh-ts/releases/tag/<version>
stdenv.mkDerivation (finalAttrs: {
  pname = "zenoh-bridge-remote-api";
  version = "1.9.0";

  src =
    let
      assetFor = {
        "aarch64-darwin" = {
          system = "aarch64-apple-darwin";
          hash = "sha256-om0dydrOGemNLrM4ZdIknFAiiDhDfKNKmQ+44MOtlo8=";
        };
        "x86_64-darwin" = {
          system = "x86_64-apple-darwin";
          hash = "sha256-KDRuiJFnpBUiDt98VXvF+O9DKhG04a660tFzkQTT7/s=";
        };
        "aarch64-linux" = {
          system = "aarch64-unknown-linux-gnu";
          hash = "sha256-tV0VK4+TOjC3tZcEK7aC8iIBkUOskC2lCfnI8ONiZKE=";
        };
        "x86_64-linux" = {
          system = "x86_64-unknown-linux-gnu";
          hash = "sha256-BHLv7Uuowv1n+5sLtYkNtsP893P9dV5PLwzNuaMlrAc=";
        };
      }.${stdenv.hostPlatform.system} or (throw
        "zenoh-bridge-remote-api: no release asset for system ${stdenv.hostPlatform.system}");
    in
    fetchzip {
      url = "https://github.com/eclipse-zenoh/zenoh-ts/releases/download/${finalAttrs.version}/zenoh-ts-${finalAttrs.version}-${assetFor.system}-standalone.zip";
      hash = assetFor.hash;
      stripRoot = false;
    };

  # The archive is just the two files below at its root, no build system.
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib"
    install -m755 zenoh-bridge-remote-api "$out/bin/zenoh-bridge-remote-api"
    install -m755 libzenoh_plugin_remote_api.* "$out/lib/"

    runHook postInstall
  '';

  meta = {
    description = "Standalone zenohd statically linked with zenoh-plugin-remote-api, for WebSocket access to a zenoh network";
    homepage = "https://github.com/eclipse-zenoh/zenoh-ts";
    downloadPage = "https://github.com/eclipse-zenoh/zenoh-ts/releases";
    license = with lib.licenses; [ epl20 asl20 ];
    platforms = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    mainProgram = "zenoh-bridge-remote-api";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
