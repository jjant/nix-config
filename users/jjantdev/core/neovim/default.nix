{ lib, pkgs, vimPlugins, ... }:
let
  extraVimPlugins = lib.mapAttrsToList (name: value:
    pkgs.vimUtils.buildVimPlugin {
      name = name;
      src = value;
    }) vimPlugins;
in {
  home = {
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    shellAliases = {
      vi = "nvim";
      vim = "nvim";
    };
  };

  programs = {
    git.extraConfig.core.editor = "nvim";

    neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins;
        [ telescope-nvim vim-fish vim-nix plenary-nvim ] ++ extraVimPlugins;
    };
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua".source = ./lua;
}
