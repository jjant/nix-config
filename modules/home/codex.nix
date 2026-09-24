{ lib, pkgs, ... }:
let
  # Codex updates config.toml itself (trusted projects, plugins, etc.), so
  # merge this preference into the writable file and preserve its comments.
  configureCodex =
    pkgs.writers.writePython3 "configure-codex"
      {
        libraries = [ pkgs.python3Packages.tomlkit ];
      }
      ''
        from pathlib import Path
        import tempfile

        import tomlkit

        config_path = Path.home() / ".codex" / "config.toml"
        original = config_path.read_text() if config_path.exists() else ""
        settings = tomlkit.parse(original)
        tui = settings.setdefault("tui", tomlkit.table())
        tui.setdefault("effects", tomlkit.table())["shimmer"] = False
        updated = tomlkit.dumps(settings)

        if updated != original:
            config_path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(
                mode="w", dir=config_path.parent, delete=False
            ) as output:
                output.write(updated)
            Path(output.name).replace(config_path)
      '';
in
{
  # Disable shimmering text while keeping the other terminal animations.
  home.activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${configureCodex}
  '';
}
