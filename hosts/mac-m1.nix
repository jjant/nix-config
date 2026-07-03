# Mac host (darwin + home-manager)
{ self, nixpkgs, nix-darwin, nix-homebrew, home-manager, vimPlugins }:
nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  pkgs = import nixpkgs {
    system = "aarch64-darwin";
    config.allowUnfree = true;
  };
  modules = [
    { system.configurationRevision = self.rev or self.dirtyRev or null; }
    { nix.registry.nixpkgs.flake = nixpkgs; nix.registry.p.flake = nixpkgs; }
    ../modules/darwin
    nix-homebrew.darwinModules.nix-homebrew
    {
      # nix-homebrew installs and owns Homebrew itself; the nix-darwin
      # `homebrew.*` options only manage packages on top via `brew bundle`.
      # This removes the manual "install Homebrew" bootstrap step and lets us
      # declaratively trust our non-official taps (required since Homebrew 6).
      nix-homebrew = {
        enable = true;
        user = "jjantdev";
        # Adopt an existing Homebrew install if present; otherwise install
        # fresh. Lets a brand-new Mac skip installing Homebrew by hand.
        autoMigrate = true;
        # Homebrew 6+ refuses to load formulae/casks from non-official taps
        # unless trusted. Trust the taps this config uses.
        trust.taps = [
          "epk/epk"
          "smithy-lang/tap"
          "eclipse-zenoh/zenoh"
          "goreleaser/tap"
        ];
      };
    }
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
