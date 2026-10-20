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
      # The full hostname rather than the ssh alias: every alias's
      # ProxyCommand (../modules/home/ssh.nix) runs /usr/local/bin/wssh, which
      # only the Mac has, while the full hostname works everywhere (through
      # WSSH's own ssh config on the Mac, directly between desks). It also
      # tells hostctl on each desk which host it is.
      { destination = host.hostname; }
  ) hosts;
}
