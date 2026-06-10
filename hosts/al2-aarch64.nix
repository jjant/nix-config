# Amazon Linux 2 cloud desktop (aarch64)
{ nixpkgs, home-manager, vimPlugins, ... }:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "aarch64-linux";
    config.allowUnfree = true;
  };
  extraSpecialArgs = { inherit vimPlugins; };
  modules = [
    ../modules/home
    {
      home = {
        username = "jjantdev";
        homeDirectory = "/home/jjantdev";
        stateVersion = "23.11";
      };
    }
  ];
}
