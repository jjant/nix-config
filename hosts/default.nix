# Every host this flake configures, keyed by config name.
#
# Plain data, not a module. The flake derives its home-manager and darwin
# configurations, flake checks, the CI build matrix and `activate`'s host
# detection from it; ssh.nix, zed.nix and vscode.nix take their dev desk lists
# from the hosts that have a `hostname`. Adding a host is one entry here.
#
#   system    Nix platform; also picks the CI runner.
#   hostname  Linux cloud desktops only: the FQDN behind the ssh alias, which
#             is the config name. `activate` matches its short form against
#             `hostname -s`, and the config name becomes STARSHIP_HOST_ALIAS,
#             which `code`/`zed` on the desk use to attach the Mac's editor.
#             Darwin hosts have their entry point in ./<name>.nix instead.
{
  mac-m1.system = "aarch64-darwin";

  al2-x86_64 = {
    system = "x86_64-linux";
    hostname = "dev-dsk-jjantdev-1a-4f02b3bf.eu-west-1.amazon.com";
  };
  al2-aarch64 = {
    system = "aarch64-linux";
    hostname = "dev-dsk-jjantdev-1a-51a25ad7.eu-west-1.amazon.com";
  };
  al2023-x86_64 = {
    system = "x86_64-linux";
    hostname = "dev-dsk-jjantdev-1a-0e9604fc.eu-west-1.amazon.com";
  };
}
