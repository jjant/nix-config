# Dev desktop ssh aliases -> full internal hostnames.
#
# Plain data, not a home-manager module: imported directly by ssh.nix (the
# wssh host blocks), zed.nix (remote picker) and vscode.nix (Remote-SSH
# platform), so adding a desk here is enough for all three.
{
  "al2-x86_64" = "dev-dsk-jjantdev-1a-4f02b3bf.eu-west-1.amazon.com";
  "al2-aarch64" = "dev-dsk-jjantdev-1a-51a25ad7.eu-west-1.amazon.com";
  "al2023-x86_64" = "dev-dsk-jjantdev-1a-0e9604fc.eu-west-1.amazon.com";
}
