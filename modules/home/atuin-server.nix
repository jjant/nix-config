{ pkgs, config, ... }:
let
  # Keep in sync with the clients' sync_address (./default.nix) and the
  # tunnels in ./atuin-tunnel.nix and ../darwin/atuin-tunnel.nix.
  port = 8888;
  dataDir = "${config.xdg.dataHome}/atuin-server";
in
{
  # Self-hosted atuin sync server, enabled only on hosts with
  # `atuinServer = true` in ../../hosts/default.nix.
  #
  # Clients keep their full history locally and only push records encrypted
  # with the account's key, which they share and the server process never
  # receives. So the server holds nothing that isn't already on every
  # client, hence plain SQLite and no replication. If this host dies, set
  # the flag on another one, `atuin register` there again (same username,
  # existing key; flip ATUIN_OPEN_REGISTRATION on for that), `atuin login`
  # on the other clients, and `atuin sync` re-uploads everything.
  #
  # This host is a client too, so its ~/.local/share/atuin holds that key
  # next to server.db: here only file permissions protect the history, not
  # the encryption.
  #
  # Bound to loopback only. Other machines reach it through an SSH
  # LocalForward (./atuin-tunnel.nix, ../darwin/atuin-tunnel.nix), never a
  # wider bind. Registration is closed: the one account already exists, and
  # otherwise any local user could create accounts and fill server.db.
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
        "ATUIN_OPEN_REGISTRATION=false"
        "ATUIN_DB_URI=sqlite://${dataDir}/server.db"
        # Keeps the server's generated server.toml out of the client's
        # ~/.config/atuin.
        "ATUIN_CONFIG_DIR=${dataDir}"
      ];
      # server.db holds only our records: keep it private to us.
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
