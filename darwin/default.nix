{ pkgs
, config
, lib
, ...
}: {
  imports = [
    ./skhd.nix
    ./yabai.nix
  ];

  environment = {
    systemPackages = [
      pkgs.vim
      pkgs.neovim
    ];
    systemPath = [
      "/opt/homebrew/bin"
    ];
    shells = [
      pkgs.zsh
      pkgs.fish
    ];
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [
    "root"
    "jjantdev"
  ];
  nix.settings.substituters = [
    "https://jjant-nix.cachix.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "jjant-nix.cachix.org-1:g3Dup2VOxdS2kNwIxoQ7JVl0W/mhrTHv7jvFHOYAFd4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  programs.fish.enable = true;
  # programs.fish.loginShellInit = ''
  #   fish_add_path --append "$HOME/.nix-profile/bin"
  #   fish_add_path --append "/etc/profiles/per-user/$USER/bin"
  #   fish_add_path --append "/nix/var/nix/profiles/default/bin"
  #   fish_add_path --append "/run/current-system/sw/bin"
  # '';

  # See: https://github.com/LnL7/nix-darwin/issues/122
  programs.fish.loginShellInit =
    let
      # This naive quoting is good enough in this case. There shouldn't be any
      # double quotes in the input string, and it needs to be double quoted in case
      # it contains a space (which is unlikely!)
      dquote = str: "\"" + str + "\"";

      makeBinPathList = map (path: path + "/bin");
    in
    ''
      fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList config.environment.profiles)}
      set fish_user_paths $fish_user_paths

      # Amazon stuff
      fish_add_path --append "$HOME/.toolbox/bin"

      # Personal scripts
      # TODO: set up XDG variables with home-manager.
      #  then replace $HOME/.config with config.xdg.configHome (nix value).
      fish_add_path --append "$HOME/.config/bin"

      # Rust binaries
      fish_add_path --append "$HOME/.cargo/bin"
      # Rodar
      fish_add_path --append "$HOME/.rodar/bin"
    '';
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # My configs
  system.primaryUser = "jjantdev";
  system.defaults.dock.mru-spaces = false;
  system.defaults.universalaccess.mouseDriverCursorSize = 1.75;
  system.defaults.trackpad.TrackpadRightClick = true;
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.10;
    autohide-time-modifier = 2.0;
  };

  # Allow using TouchID with sudo.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Make Finder killable
  system.defaults.finder.QuitMenuItem = true;

  homebrew = {
    enable = true;
    brewPrefix = "/opt/homebrew/bin/";

    taps = [
      # See: https://github.com/epk/SF-Mono-Nerd-Font
      "epk/epk"
      "smithy-lang/tap"
      "eclipse-zenoh/homebrew-zenoh"
    ];

    brews = [
      "smithy-cli"
      "zenoh"
    ];

    casks = [
      {
        name = "lunar";
        greedy = true;
      }
      {
        name = "raycast";
        greedy = true;
      }
      {
        name = "1password";
        greedy = true;
      }
      {
        name = "1password-cli";
        greedy = true;
      }
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "docker-desktop";
        greedy = true;
      }
      # Installs "SFMono Nerd Font" font
      {
        name = "font-sf-mono-nerd-font";
        greedy = true;
      }
      {
        name = "graphiql";
        greedy = true;
      }
      {
        name = "wireshark-app";
        greedy = true;
      }
    ];
  };
}
