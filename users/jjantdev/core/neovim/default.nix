{ lib, pkgs, vimPlugins, ... }:
let
  extraVimPlugins = lib.mapAttrsToList
    (name: value:
      pkgs.vimUtils.buildVimPluginFrom2Nix {
        inherit name;
        src = value;
      })
    vimPlugins;
in
{
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
        [
          quick-scope
          lualine-nvim
          nvim-web-devicons
          nvim-autopairs
          telescope-nvim
          telescope-fzf-native-nvim
          vim-fish
          vim-nix
          nvim-surround
          plenary-nvim
          nvim-treesitter-textobjects
          (nvim-treesitter.withPlugins (grammars: [
            grammars.rust
            grammars.nix
            grammars.lua
            grammars.smithy
            grammars.kotlin
            grammars.bash
            grammars.fish
            grammars.yaml
            grammars.toml
            grammars.json
            grammars.javascript
            grammars.typescript
          ]))
          playground
          harpoon
          marks-nvim
          gitsigns-nvim
          comment-nvim
        ] ++ extraVimPlugins;
    };
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;
  xdg.configFile."nvim/lua".source = ./lua;
}
