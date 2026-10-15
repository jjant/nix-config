builtins.mapAttrs (_: host: host // { system = "${host.arch}-${host.os}"; }) {
  mac-m1 = {
    os = "darwin";
    arch = "aarch64";
  };

  al2-x86_64 = {
    os = "linux";
    arch = "x86_64";
    hostname = "dev-dsk-jjantdev-1a-4f02b3bf.eu-west-1.amazon.com";
  };
  al2-aarch64 = {
    os = "linux";
    arch = "aarch64";
    hostname = "dev-dsk-jjantdev-1a-51a25ad7.eu-west-1.amazon.com";
  };
  al2023-x86_64 = {
    os = "linux";
    arch = "x86_64";
    hostname = "dev-dsk-jjantdev-1a-0e9604fc.eu-west-1.amazon.com";
  };
  bigmem = {
    os = "linux";
    arch = "x86_64";
    hostname = "dev-dsk-jjantdev-1a-0a3b1663.eu-west-1.amazon.com";
  };
}
