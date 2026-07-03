{ pkgs, ... }:
let
  # Make `<CMD-{number}>` send `<CTRL-B>{number}`
  # We embed the raw STX (0x02) character so TOML serialization preserves it
  prefix = builtins.fromJSON ''"\u0002"'';
  tmuxBindings = [
    { key = "1"; mods = "Command"; chars = "${prefix}1"; }
    { key = "2"; mods = "Command"; chars = "${prefix}2"; }
    { key = "3"; mods = "Command"; chars = "${prefix}3"; }
    { key = "4"; mods = "Command"; chars = "${prefix}4"; }
    { key = "5"; mods = "Command"; chars = "${prefix}5"; }
    { key = "6"; mods = "Command"; chars = "${prefix}6"; }
    { key = "7"; mods = "Command"; chars = "${prefix}7"; }
    { key = "8"; mods = "Command"; chars = "${prefix}8"; }
    { key = "9"; mods = "Command"; chars = "${prefix}9"; }
  ];
in
{
  # macOS's system terminfo (and nix's ncurses) don't ship the `alacritty`
  # entry, so `TERM=alacritty` fails to resolve on a fresh machine. Install the
  # terminfo via the per-user profile, which is on TERMINFO_DIRS. (Previously
  # this was a hand-`tic`'d ~/.terminfo entry that never made it off the old Mac.)
  home.packages = [ pkgs.alacritty.terminfo ];

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "alacritty";
      };
      # Alacritty launches $SHELL (falling back to the login shell). GUI apps
      # inherit the login session's $SHELL, which is stale right after a `chsh`,
      # so alacritty could open the old zsh while Terminal.app already uses fish.
      # Pin fish as a login shell so it's deterministic.
      terminal.shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "-l" ];
      };
      window = {
        decorations = "none";
      };
      font = {
        normal = {
          family = "SFMono Nerd Font";
          style = "Light";
        };
        bold = {
          style = "Semibold";
        };
        size = 15;
      };
      keyboard = {
        bindings = tmuxBindings;
      };
    };
  };
}
