{ lib, pkgs, lunarVimDarkPlusNvim, ... }: {
  home = {
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LS_COLORS = "";
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
      plugins = with pkgs.vimPlugins; [
        telescope-nvim
        vim-fish
        vim-nix
        plenary-nvim
        (pkgs.vimUtils.buildVimPlugin {
          name = "darkplus.nvim";
          src = lunarVimDarkPlusNvim;
        })
      ];
    };
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua".source = ./lua;
}
