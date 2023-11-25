{ pkgs, lib, ... }: {
  services.nix-daemon.enable = true;

  services.yabai.enable = true;
  # services.yabai.enableScriptingAddition = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.jjantdev = { pkgs, ... }: {
    home.stateVersion = "22.11";
    home.homeDirectory = lib.mkForce "/Users/jjantdev";

    programs.htop.enable = true;
  };

  # Requires installing homebrew by hand
  # See: https://mac.install.guide/homebrew/index.html
  homebrew = {
    enable = true;
  };
}
