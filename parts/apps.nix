# `nix run .#activate` (auto-detects the host and applies its config) and
# `nix run .#update`.
{
  self,
  lib,
  hosts,
  ...
}:
let
  # This flake as `activate` switches to it: its store path, plus the revision
  # and metadata a bare `${self}` (a `path:` flake) would drop. Without them
  # the Mac's system.configurationRevision (../hosts/mac-m1.nix) is null and
  # its system differs from the one hostctl evaluates at the same revision.
  # (A dirty tree has no revision to pass, so it still records none.)
  flake =
    "path:${self}?"
    + lib.concatStringsSep "&" (
      lib.optional (self ? rev) "rev=${self.rev}"
      ++ lib.optional (self ? lastModified) "lastModified=${toString self.lastModified}"
      ++ [ "narHash=${lib.escapeURL self.narHash}" ]
    );

  # `activate`'s hostname -> config lookup, one case arm per desk.
  desksCases = lib.concatStringsSep "\n      " (
    lib.mapAttrsToList (
      name: host: "${lib.head (lib.splitString "." host.hostname)}) host=${name} ;;"
    ) (lib.filterAttrs (_: host: host.os != "darwin" && host ? hostname) hosts)
  );
in
{
  perSystem =
    { pkgs, inputs', ... }:
    {
      apps = {
        activate = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "activate";
              # Pinned by flake.lock rather than whatever `nix run
              # home-manager` resolves through the flake registry, and
              # without a nested `nix run` that evaluates another flake.
              runtimeInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                inputs'.home-manager.packages.home-manager
                pkgs.hostname
              ];
              text = ''
                # Bootstrap for a machine with no persistent nix.conf yet:
                # NIX_CONFIG reaches the nix processes darwin-rebuild /
                # home-manager spawn (a CLI flag would not). Accepting flake
                # config here applies to this flake's nixConfig (our cache),
                # so the switch doesn't stop at the substituter prompts.
                export NIX_CONFIG="extra-experimental-features = nix-command flakes
                accept-flake-config = true"

                # Switch to the flake this app came from, not the current
                # directory: `nix run github:jjant/nix-config#activate` on a
                # fresh desk runs from $HOME, which has no flake.nix. From a
                # local clone, `nix run .#activate` makes this that clone.
                flake='${flake}'

                if [ "$(uname)" = "Darwin" ]; then
                  # Absolute path: sudo resets PATH.
                  sudo ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (lib.getExe' inputs'.nix-darwin.packages.darwin-rebuild "darwin-rebuild")} switch --flake "$flake"#mac-m1 "$@"
                else
                  # Pick the desk's config by short hostname (./hosts). The
                  # config name becomes STARSHIP_HOST_ALIAS, which `code` and
                  # `zed` use as the ssh destination back to this desk, so a
                  # guessed config would attach editors to another desk.
                  # ACTIVATE_HOST=<config> overrides the lookup.
                  host="''${ACTIVATE_HOST:-}"
                  if [ -z "$host" ]; then
                    case "$(hostname -s)" in
                      ${desksCases}
                      *)
                        echo "activate: $(hostname -s) is not in hosts/default.nix;" \
                          "add it there or set ACTIVATE_HOST=<config>" >&2
                        exit 1
                        ;;
                    esac
                  fi

                  # Move files home-manager would clobber (e.g. a fresh desk's
                  # stock ~/.zshrc) aside instead of aborting. The timestamp
                  # keeps a later conflict from tripping over an old backup.
                  home-manager switch \
                    -b "hm-backup.$(date +%Y%m%d-%H%M%S)" \
                    --flake "$flake"#"$host" "$@"
                fi
              '';
            }
          );
        };
        update = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "update" ''
              nix flake update
            ''
          );
        };
      };
    };
}
