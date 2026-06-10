# Mac host (darwin + home-manager)
{ self, nixpkgs, nix-darwin, home-manager, vimPlugins }:
nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  pkgs = import nixpkgs {
    system = "aarch64-darwin";
    config.allowUnfree = true;
  };
  modules = [
    { system.configurationRevision = self.rev or self.dirtyRev or null; }
    ../modules/darwin
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        extraSpecialArgs = { inherit vimPlugins; };
        useGlobalPkgs = true;
        useUserPackages = true;
        users.jjantdev = {
          home.stateVersion = "23.11";
          home.homeDirectory = nixpkgs.lib.mkForce "/Users/jjantdev";
          imports = [
            ../modules/home
            ../modules/darwin/alacritty.nix
            ({ pkgs, ... }: { home.packages = [ pkgs.htop ]; })
          ];
        };
      };
    }
  ];
}
