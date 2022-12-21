{ lib, pkgs, lunarVimDarkPlusNvim, ... }: {
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
}
