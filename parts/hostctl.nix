# hostctl's inventory: how to reach each host in ../hosts/default.nix. hostctl
# reads it from the revision it compares against (`lib.hostctl.hosts`), next to
# the configurations it evaluates.
{ lib, hosts, ... }:
{
  flake.lib.hostctl.hosts = lib.mapAttrs (
    _: host:
    if host.os == "darwin" then
      {
        # From a desk, only through the reverse tunnel of an ssh session from
        # the Mac (RemoteForward 2022 in ../modules/home/ssh.nix), and only to
        # check it: its forced command answers nothing else. On the Mac, its
        # own config names it as the local host (../hosts/mac-m1.nix).
        destination = "ssh://jjantdev@localhost:2022";
        optional = true;
        note = "from a desk, only through the reverse tunnel of an ssh session from the Mac";
      }
    else
      # hostctl also uses the full hostname to identify the local desk.
      { destination = host.hostname; }
  ) hosts;
}
