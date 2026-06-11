_: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      line_break = { disabled = true; };
      aws.disabled = true;
      hostname.disabled = true;
      username.disabled = true;
      env_var.STARSHIP_HOST_ALIAS = {
        format = "[🌐 $env_value]($style) ";
        style = "bold cyan";
      };
      nix_shell = {
        heuristic = true;
      };
    };
  };
}
