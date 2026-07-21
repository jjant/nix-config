# Apple's built-in OpenSSH server (macOS "Remote Login"), enabled declaratively
# so a Cloud Desktop can reach this Mac back over the reverse tunnel
# (modules/home/ssh.nix: `RemoteForward 2022 localhost:22`) and invoke the Mac's
# native `open` (modules/home/bin/open.sh) or open VS Code attached back to the
# desk over Remote-SSH (modules/home/bin/code.sh), via a locked-down forced
# command.
#
# Policy: enabling Remote Login on a managed Mac is officially sanctioned by IT
# ("Enable secure shell (SSH) in macOS",
# it.amazon.com/en/articles/setup/laptop-setup/enable-secure-shell-in-macos);
# applying it needs local admin rights the first time.
#
# Containment: key-only auth, no passwords. The authorized key is additionally
# pinned with:
#   - from="127.0.0.1,::1" — usable only over the loopback reverse tunnel, never
#     from the network. This is what actually contains the daemon: macOS's
#     launchd owns the :22 socket and binds all interfaces regardless of the
#     ListenAddress lines below (they are best-effort), so the `from=` clause is
#     the real network guard for this key.
#   - command="…/mac-open-recv" — a forced receiver that can ONLY run the `open`
#     flow, never an arbitrary shell, even though the login user authenticates.
#   - restrict — no port/agent/X11 forwarding, no PTY (the flow needs none).
{ pkgs, ... }:
let
  # The forced-command receiver. Built with writeShellApplication (not the
  # resholve helper in modules/home/bin) because it must call macOS's own
  # /usr/bin/{open,tar,xattr,...} by absolute path rather than Nix-store
  # rewrites. writeShellApplication pins a modern bash and runs shellcheck.
  macOpenRecv = pkgs.writeShellApplication {
    name = "mac-open-recv";
    # Pinned tools for the receiver's PATH (sshd's bare forced-command
    # environment has no user profile):
    #  - zstd: decompress the `file` transfer stream — macOS's libarchive has
    #    no built-in zstd (see mac-open-recv.sh).
    #  - vscode: the `code` CLI for the Remote-SSH flow; same pkgs.vscode the
    #    user profile installs (modules/home/vscode.nix via useGlobalPkgs).
    runtimeInputs = [
      pkgs.zstd
      pkgs.vscode
    ];
    text = builtins.readFile ./mac-open-recv.sh;
  };
in
{
  services.openssh.enable = true;

  services.openssh.extraConfig = ''
    ListenAddress 127.0.0.1
    ListenAddress ::1
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';

  # Only this key may authenticate, only over the loopback tunnel, and only to
  # run mac-open-recv. The key is the Mac's 1Password Ed25519 identity presented
  # from the dev desk via the forwarded agent (`ssh-add -L` on the Mac).
  users.users.jjantdev.openssh.authorizedKeys.keys = [
    ''restrict,from="127.0.0.1,::1",command="${macOpenRecv}/bin/mac-open-recv" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwNd/RtI0W1muIkgF/84DZLPKNUH/e+jnnEwnGrewAL amzn-mbp-14-m1''
  ];
}
