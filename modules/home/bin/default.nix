{ pkgs, ... }:
let
  # Build a bin script from a sibling <name>.sh file, so scripts live as real,
  # editor-friendly, shellcheck-able files instead of inline Nix strings.
  #
  # `subs` maps placeholders (e.g. "@fd@") to values (e.g. a pinned store path)
  # that are substituted into the script text at build time. Pass { } for
  # scripts that need no substitutions.
  scriptFrom = name: subs:
    pkgs.writeShellScriptBin name (
      builtins.replaceStrings
        (builtins.attrNames subs)
        (builtins.attrValues subs)
        (builtins.readFile (./. + "/${name}.sh"))
    );
in
{
  home.packages = [
    # fd/fzf pinned to exact store paths; the rest (tmux, coreutils) come from
    # the interactive environment, as before.
    (scriptFrom "tmux-sessionizer" {
      "@fd@" = "${pkgs.fd}/bin/fd";
      "@fzf@" = "${pkgs.fzf}/bin/fzf";
    })
    (scriptFrom "brazil-open-package" { })
    (scriptFrom "dev-desk-tunnel" { })
    (scriptFrom "pnew" { })
  ];
}
