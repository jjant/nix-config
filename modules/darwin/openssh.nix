# Apple's built-in OpenSSH server (macOS "Remote Login"), enabled declaratively
# so a Cloud Desktop can reach this Mac back over the reverse tunnel
# (modules/home/ssh.nix: `RemoteForward 2022 localhost:22`) and invoke the Mac's
# native `open` (modules/home/bin/open.sh).
#
# Policy: enabling Remote Login on a managed Mac is officially sanctioned by IT
# ("Enable secure shell (SSH) in macOS",
# it.amazon.com/en/articles/setup/laptop-setup/enable-secure-shell-in-macos);
# applying it needs local admin rights the first time.
#
# Hardened to loopback only: the reverse tunnel's final hop is the Mac
# connecting to its own 127.0.0.1:22, so sshd never needs to be reachable from
# the network. Key-only auth, no passwords.
{ ... }:
{
  services.openssh.enable = true;

  services.openssh.extraConfig = ''
    ListenAddress 127.0.0.1
    ListenAddress ::1
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';

  # Only these keys may authenticate — the identity presented from the dev desk
  # via the forwarded 1Password agent. Fill in from `ssh-add -L` on the Mac.
  # Until a key is added here, no SSH login succeeds (fail-closed).
  users.users.jjantdev.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwNd/RtI0W1muIkgF/84DZLPKNUH/e+jnnEwnGrewAL amzn-mbp-14-m1"
  ];
}
