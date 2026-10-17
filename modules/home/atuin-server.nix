{ pkgs, config, ... }:
let
  # Keep in sync with the tunnels in ./atuin-tunnel.nix and
  # ../darwin/atuin-tunnel.nix.
  port = 8888;
  dataDir = "${config.xdg.dataHome}/atuin-server";
in
{
  # Self-hosted atuin sync server, enabled only on hosts with
  # `atuinServer = true` in ../../hosts/default.nix.
  #
  # Clients keep their full history locally and only push end-to-end
  # encrypted records, so the server holds nothing that isn't already on
  # every client: if this host dies, start the server elsewhere and
  # `atuin sync` re-uploads the missing records. Hence plain SQLite, no
  # replication.
  #
  # Bound to loopback only. Other machines reach it through an SSH
  # LocalForward (./atuin-tunnel.nix, ../darwin/atuin-tunnel.nix), never a
  # wider bind. Open registration is left on because only local users can
  # reach the port and records are encrypted with each client's key anyway.
  #
  # Like earlyoom, this is a user service: it runs while we're logged in
  # (no linger). Each tunnel is itself an ssh login, so the server is up
  # whenever a client can reach it.
  systemd.user.services.atuin-server = {
    Unit.Description = "Atuin sync server (loopback only)";

    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${dataDir}";
      ExecStart = "${pkgs.atuin}/bin/atuin-server start";
      Environment = [
        "ATUIN_HOST=127.0.0.1"
        "ATUIN_PORT=${toString port}"
        "ATUIN_OPEN_REGISTRATION=true"
        "ATUIN_DB_URI=sqlite://${dataDir}/server.db"
        # Keeps the server's generated server.toml out of the client's
        # ~/.config/atuin.
        "ATUIN_CONFIG_DIR=${dataDir}"
      ];
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
