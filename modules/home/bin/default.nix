{ pkgs, lib, ... }:
let
  # Wrap a sibling <name>.sh file as a resholve'd package: resholve parses the
  # script, rewrites every declared external command to its absolute Nix store
  # path, and fails the build if a command isn't declared (via `inputs`) or
  # explicitly excused (via `fake`/`execer`). The build also gates on a bash
  # syntax check and shellcheck.
  #
  # Extra args (inputs, fake, execer, keep, ...) are passed straight through to
  # resholve's "solution".
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

  # Bound (rather than inlined) so it can be both installed and passed as a
  # resholve input to brazil-workspace-from-package, which invokes it — that
  # resolves the call to this exact store path instead of a bare PATH lookup.
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
  home.packages = [
    tmux-sessionizer

    (writeShellApp {
      name = "brazil-open-package";
      inputs = with pkgs; [ coreutils ];
      # macOS `open` and the Amazon toolbox `brazil-context` aren't Nix
      # packages; leave them as runtime PATH lookups.
      fake.external = [ "open" "brazil-context" ];
    })

    (writeShellApp {
      name = "brazil-workspace-from-package";
      # tmux-sessionizer is resolved to its store path (a real dependency), so
      # only `brazil` (the Amazon toolbox) stays a runtime PATH lookup.
      inputs = [ pkgs.coreutils tmux-sessionizer ];
      fake.external = [ "brazil" ];
      # tmux-sessionizer can exec (it runs tmux/fd/fzf internally), but we only
      # hand it a directory, so assert this invocation does not exec its arg.
      execer = [ "cannot:${tmux-sessionizer}/bin/tmux-sessionizer" ];
    })

    (writeShellApp {
      name = "dev-desk-tunnel";
      inputs = with pkgs; [ coreutils ];
      # Use the system ssh (carries the user's ~/.ssh config, agent, wssh proxy).
      fake.external = [ "ssh" ];
    })

    (writeShellApp {
      name = "pnew";
      inputs = with pkgs; [ git coreutils ];
      execer = [ "cannot:${pkgs.git}/bin/git" ];
    })

    (writeShellApp {
      name = "cr-open";
      inputs = with pkgs; [ git coreutils ];
      execer = [ "cannot:${pkgs.git}/bin/git" ];
      # macOS `open` (and the Cloud Desktop shim of the same name) isn't a Nix
      # package; leave it as a runtime PATH lookup.
      fake.external = [ "open" ];
    })
  ]
  # Linux-only packages, built into the cloud desktop closures but not macOS.
  ++ lib.optionals pkgs.stdenv.isLinux [
    # On macOS `open` would shadow the real one; on the cloud desktop it hands
    # files/URLs to the Mac over a reverse SSH tunnel.
    (writeShellApp {
      name = "open";
      inputs = with pkgs; [ coreutils gnutar zstd pv ];
      # System ssh carries the user's ~/.ssh config + forwarded agent.
      fake.external = [ "ssh" ];
      # tar/pv can exec in general, but this script never uses them that way.
      execer = [
        "cannot:${pkgs.gnutar}/bin/tar"
        "cannot:${pkgs.pv}/bin/pv"
      ];
    })

    # Invoked only from fish's interactive-SSH-login guard, which is itself
    # Linux-only, so there's no reason to build it on macOS.
    (writeShellApp {
      name = "tmux-attach-or-sessionize";
      # tmux-sessionizer resolves to its store path (a real dependency); tmux
      # is the only other external command.
      inputs = [ pkgs.tmux tmux-sessionizer ];
      # Both can exec in general (tmux run, sessionizer runs tmux/fd/fzf), but
      # this script invokes them as plain commands, execing neither.
      execer = [
        "cannot:${pkgs.tmux}/bin/tmux"
        "cannot:${tmux-sessionizer}/bin/tmux-sessionizer"
      ];
    })
  ];
}
