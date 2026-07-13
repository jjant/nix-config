# Custom shell scripts, packaged with resholve so every external command is
# rewritten to an absolute Nix store path (and the build fails on an undeclared
# command, plus gates on bash syntax + shellcheck + shfmt).
#
# Exposed as a plain attrset (not a home-manager module) so it can be imported
# from more than one place with the *same* derivations: `default.nix` installs
# them into `home.packages`, and `fish.nix` interpolates `tmux-sessionizer`'s
# store path into its keybinding + SSH-login snippet.
{ pkgs }:
let
  # Wrap a sibling <name>.sh file as a resholve'd package. Extra args (inputs,
  # fake, execer, keep, ...) are passed straight through to resholve's
  # "solution".
  writeShellApp =
    { name, src ? (./. + "/${name}.sh"), ... }@args:
    let
      extraSolution = builtins.removeAttrs args [ "name" "src" ];
    in
    pkgs.resholve.mkDerivation {
      pname = name;
      version = "0.0.0";
      inherit src;

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        cp "$src" "$out/bin/${name}"
        chmod +x "$out/bin/${name}"
        runHook postInstall
      '';

      doInstallCheck = true;
      installCheckPhase = ''
        runHook preInstallCheck
        ${pkgs.stdenv.shellDryRun} "$out/bin/${name}"
        ${pkgs.shellcheck}/bin/shellcheck "$out/bin/${name}"
        ${pkgs.shfmt}/bin/shfmt --diff -s -ln bash -i 2 -ci "$out/bin/${name}"
        runHook postInstallCheck
      '';

      solutions.default = {
        interpreter = "${pkgs.bash}/bin/bash";
        scripts = [ "bin/${name}" ];
      } // extraSolution;
    };

  # Bound in the `let` (not just an attr) because siblings reference it:
  # brazil-workspace-from-package takes it as a resholve input, and fish.nix
  # interpolates its store path. Referencing this binding resolves those uses
  # to the exact same derivation rather than a bare PATH lookup.
  tmux-sessionizer = writeShellApp {
    name = "tmux-sessionizer";
    inputs = with pkgs; [ fd fzf tmux coreutils ];
    # These can exec arguments in general (fd -x, fzf --bind, tmux run), but
    # this script never uses them that way, so assert they don't here.
    execer = [
      "cannot:${pkgs.fd}/bin/fd"
      "cannot:${pkgs.fzf}/bin/fzf"
      "cannot:${pkgs.tmux}/bin/tmux"
    ];
  };
in
{
  inherit tmux-sessionizer;

  brazil-open-package = writeShellApp {
    name = "brazil-open-package";
    inputs = with pkgs; [ coreutils ];
    # macOS `open` and the Amazon toolbox `brazil-context` aren't Nix
    # packages; leave them as runtime PATH lookups.
    fake.external = [ "open" "brazil-context" ];
  };

  brazil-workspace-from-package = writeShellApp {
    name = "brazil-workspace-from-package";
    # tmux-sessionizer is resolved to its store path (a real dependency), so
    # only `brazil` (the Amazon toolbox) stays a runtime PATH lookup.
    inputs = [ pkgs.coreutils tmux-sessionizer ];
    fake.external = [ "brazil" ];
    # tmux-sessionizer can exec (it runs tmux/fd/fzf internally), but we only
    # hand it a directory, so assert this invocation does not exec its arg.
    execer = [ "cannot:${tmux-sessionizer}/bin/tmux-sessionizer" ];
  };

  dev-desk-tunnel = writeShellApp {
    name = "dev-desk-tunnel";
    inputs = with pkgs; [ coreutils ];
    # Use the system ssh (carries the user's ~/.ssh config, agent, wssh proxy).
    fake.external = [ "ssh" ];
  };

  pnew = writeShellApp {
    name = "pnew";
    inputs = with pkgs; [ git coreutils ];
    execer = [ "cannot:${pkgs.git}/bin/git" ];
  };

  cr-open = writeShellApp {
    name = "cr-open";
    inputs = with pkgs; [ git coreutils ];
    execer = [ "cannot:${pkgs.git}/bin/git" ];
    # macOS `open` (and the Cloud Desktop shim of the same name) isn't a Nix
    # package; leave it as a runtime PATH lookup.
    fake.external = [ "open" ];
  };

  # Linux-only in practice (the consumer gates its install): on macOS this
  # would shadow the real `open`.
  open = writeShellApp {
    name = "open";
    inputs = with pkgs; [ coreutils gnutar zstd pv ];
    # System ssh carries the user's ~/.ssh config + forwarded agent.
    fake.external = [ "ssh" ];
    # tar/pv can exec in general, but this script never uses them that way.
    execer = [
      "cannot:${pkgs.gnutar}/bin/tar"
      "cannot:${pkgs.pv}/bin/pv"
    ];
  };
}
