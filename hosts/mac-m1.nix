# Mac host (darwin + home-manager)
{
  self,
  nixpkgs,
  nix-darwin,
  nix-homebrew,
  home-manager,
  vimPlugins,
  nix-vscode-extensions,
  mac-app-util,
}:
let
  system = "aarch64-darwin";
in
nix-darwin.lib.darwinSystem {
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    # Adds pkgs.vscode-marketplace.* (consumed by ../modules/home/vscode.nix).
    overlays = [ nix-vscode-extensions.overlays.default ];
  };
  modules = [
    # The modern spelling. Passing `system` to `darwinSystem` instead routes
    # through a backwards-compat shim that sets the legacy `nixpkgs.system`
    # option, which upstream says "will be deprecated in the future".
    { nixpkgs.hostPlatform = system; }
    { system.configurationRevision = self.rev or self.dirtyRev or null; }
    {
      nix.registry.nixpkgs.flake = nixpkgs;
      nix.registry.p.flake = nixpkgs;
    }
    ../modules/darwin
    # Trampolines so nix-store GUI apps (VSCode, Alacritty, ...) are indexed by
    # Spotlight and appear in the Dock.
    mac-app-util.darwinModules.default
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
        sharedModules = [ mac-app-util.homeManagerModules.default ];
        users.jjantdev = {
          home.stateVersion = "23.11";
          home.homeDirectory = nixpkgs.lib.mkForce "/Users/jjantdev";
          imports = [
            ../modules/home
            ../modules/darwin/alacritty.nix
            ../modules/home/vscode.nix
            ({ pkgs, ... }: { home.packages = [ pkgs.htop ]; })
            ({ lib, ... }: {
              # Disable the Spotlight (Cmd-Space) shortcut (symbolic hotkey 64)
              # so it can be repurposed (e.g. by Raycast). `-dict-add` flips only
              # hotkey 64 and leaves the other shortcuts intact. Runs as the user.
              #
              # `enabled` must be a real boolean: a bare `{ enabled = 0; }` is
              # stored as the string "0", which macOS ignores (Spotlight stays
              # on). Write the full XML entry (enabled=false + the standard
              # Cmd-Space value) and reload settings so it applies without a
              # re-login.
              home.activation.disableSpotlightHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array></dict></dict>'
                $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
              '';
            })
          ];
        };
      };
    }
  ];
}
