{ pkgs
, config
, lib
, ...
}: {
  imports = [
    ./skhd.nix
    ./yabai.nix
  ];

  # Newer Nix installers create the `nixbld` group with GID 350 (macOS moved
  # off the old 30000 default). Match the actual GID so nix-darwin doesn't
  # abort activation over the mismatch.
  ids.gids.nixbld = 350;

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

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [
      "root"
      "jjantdev"
    ];
    substituters = [
      "https://jjant-nix.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "jjant-nix.cachix.org-1:g3Dup2VOxdS2kNwIxoQ7JVl0W/mhrTHv7jvFHOYAFd4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    max-jobs = "auto";
    cores = 0;
    always-allow-substitutes = true;
    builders-use-substitutes = true;
    connect-timeout = 5;
    auto-optimise-store = false;
  };

  programs = {
    zsh.enable = true;
    fish = {
      enable = true;
      loginShellInit =
        let
          dquote = str: "\"" + str + "\"";
          makeBinPathList = map (path: path + "/bin");
        in
        ''
          fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList config.environment.profiles)}
          set fish_user_paths $fish_user_paths

          # The Nix installer's default profile ships its own (frozen) nix and
          # lands at the front of PATH, shadowing the newer nix that nix-darwin
          # manages in /run/current-system/sw. Demote it so the managed nix wins.
          # Home-manager profiles stay ahead of the system profile, so this does
          # not shadow tools like nvim.
          fish_add_path --move --append --path "/nix/var/nix/profiles/default/bin"

          # Amazon stuff
          fish_add_path --append "$HOME/.toolbox/bin"

          # Rust binaries
          fish_add_path --append "$HOME/.cargo/bin"
          # Rodar
          fish_add_path --append "$HOME/.rodar/bin"
        '';
    };
  };

  system = {
    stateVersion = 4;
    primaryUser = "jjantdev";
    defaults = {
      dock = {
        mru-spaces = false;
        autohide = true;
        autohide-delay = 0.10;
        autohide-time-modifier = 2.0;
      };
      universalaccess.mouseDriverCursorSize = 1.75;
      trackpad.TrackpadRightClick = true;
      finder.QuitMenuItem = true;
    };
  };

  # Never let the display sleep from inactivity. (It still turns off when the
  # machine is locked manually.)
  power.sleep.display = "never";

  security.pam.services.sudo_local.touchIdAuth = true;

  homebrew = {
    enable = true;
    prefix = "/opt/homebrew";

    taps = [
      "epk/epk"
      "smithy-lang/tap"
      "eclipse-zenoh/homebrew-zenoh"
      "goreleaser/tap"
    ];

    brews = [
      "binutils"
      "dpkg"
      "ffmpeg"
      "flyctl"
      "fmt"
      "goreleaser/tap/nfpm"
      "patchelf"
      "podman"
      "poppler"
      "rpm"
      "smithy-cli"
      "zenoh"
      "zig"
    ];

    casks = [
      { name = "lunar"; greedy = true; }
      { name = "raycast"; greedy = true; }
      { name = "1password"; greedy = true; }
      { name = "1password-cli"; greedy = true; }
      { name = "signal"; greedy = true; }
      { name = "docker-desktop"; greedy = true; }
      { name = "font-sf-mono-nerd-font"; greedy = true; }
      { name = "graphiql"; greedy = true; }
      { name = "wireshark-app"; greedy = true; }
      { name = "postman"; greedy = true; }
    ];
  };
}
