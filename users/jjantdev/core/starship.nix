{ lib, ... }: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      line_break = { disabled = true; };
      aws.disabled = true;
      nix_shell = {
        symbol = "❄️";
        # Enable `nix shell` detection
        heuristic = true;
      };
    };
  };
}
