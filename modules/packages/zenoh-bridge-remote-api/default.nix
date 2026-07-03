{ lib
, rustPlatform
, fetchFromGitHub
}:

# The Nix equivalent of `cargo install --git`: build zenoh-bridge-remote-api
# from source. It isn't on crates.io or nixpkgs, so we point buildRustPackage
# at the upstream repo (github.com/eclipse-zenoh/zenoh-ts) at a release tag.
#
# The vendored Cargo.lock pins the whole `zenoh` crate family to a git source
# (github.com/eclipse-zenoh/zenoh.git, branch release/<version>), so cargoHash
# alone can't be used; instead cargoLock.outputHashes pins that one git dep.
#
# To bump: update `version` + `src.hash`, refresh ./Cargo.lock from the tag
# (curl the raw Cargo.lock), and update the outputHashes entry.
rustPlatform.buildRustPackage rec {
  pname = "zenoh-bridge-remote-api";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "eclipse-zenoh";
    repo = "zenoh-ts";
    rev = version;
    hash = "sha256-6LzXGKRxrKnK01NCyb/gU8C+kQpjMkwwbvUZ60c22E8=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "zenoh-1.9.0" = "sha256-sFHUphFu5a+buSa3GQvSmGo8SFtn3V5ZqTOnWMPlvs8=";
    };
  };

  # Only build the bridge binary, not the rest of the zenoh-ts workspace.
  buildAndTestSubdir = "zenoh-bridge-remote-api";

  # No test suite worth running for a downstream binary build.
  doCheck = false;

  meta = {
    description = "Standalone zenohd statically linked with zenoh-plugin-remote-api, for WebSocket access to a zenoh network";
    homepage = "https://github.com/eclipse-zenoh/zenoh-ts";
    license = with lib.licenses; [ epl20 asl20 ];
    mainProgram = "zenoh-bridge-remote-api";
  };
}
