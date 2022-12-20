{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
    autocd = true;
    dotDir = ".config/zsh";
  };
}
