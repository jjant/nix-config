# Custom shell scripts, packaged with resholve so every external command is
# rewritten to an absolute Nix store path (and the build fails on an undeclared
# command, plus gates on bash syntax + shellcheck + shfmt).
#
# Exposed as a plain attrset (not a home-manager module) so it can be imported
# from more than one place with the *same* derivations: `default.nix` installs
# them into `home.packages`, and `fish.nix` interpolates `tmux-sessionizer`'s
# store path into its keybinding + SSH-login snippet.
{ pkgs, lib }:
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

  # Our reverse-tunnel `open` (installed on Linux only — see default.nix). Bound
  # in the `let` so cr-open and brazil-open-package can pin their `open` calls
  # to it on Linux.
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

  # `open` differs by platform: on Linux it's the package above, so pin it to
  # its store path; on macOS it's the system binary, so leave it a PATH lookup.
  openInputs = lib.optional pkgs.stdenv.isLinux open;
  openExecer = lib.optional pkgs.stdenv.isLinux "cannot:${open}/bin/open";
  openFake = lib.optional pkgs.stdenv.isDarwin "open";
in
{
  inherit tmux-sessionizer open;

  brazil-open-package = writeShellApp {
    name = "brazil-open-package";
    inputs = [ pkgs.coreutils ] ++ openInputs;
    # `brazil-context` is the Amazon toolbox (not a Nix package). `open` is the
    # system binary on macOS (faked) but our own package on Linux (pinned).
    fake.external = [ "brazil-context" ] ++ openFake;
    execer = openExecer;
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
    inputs = with pkgs; [ git coreutils ] ++ openInputs;
    execer = [ "cannot:${pkgs.git}/bin/git" ] ++ openExecer;
    # `open` is the system binary on macOS (faked) but our own package on Linux
    # (pinned via openInputs).
    fake.external = openFake;
  };
}
