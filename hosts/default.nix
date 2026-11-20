builtins.mapAttrs (_: host: host // { system = "${host.arch}-${host.os}"; }) {
  mac-m1 = {
    os = "darwin";
    arch = "aarch64";
  };

  bigboy = {
    os = "linux";
    arch = "x86_64";
    hostname = "dev-dsk-jjantdev-1a-39ac0ed3.eu-west-1.amazon.com";
    # Runs the atuin sync server (modules/home/atuin-server.nix).
    atuinServer = true;
  };
}
