# Amazon Linux 2 cloud desktop (x86_64)
{ nixpkgs, home-manager, vimPlugins, ... }:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
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
