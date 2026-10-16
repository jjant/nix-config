{ lib, ... }:
let
  # Every directory under ./skills is one skill (a SKILL.md plus any
  # references), in the format Claude Code, Codex and Kiro all read.
  skills = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills)
  );

  # Link each skill on its own rather than owning the whole skills directory:
  # Codex keeps its bundled skills in ~/.codex/skills/.system and AIM installs
  # its skills into ~/.kiro/skills, so those directories must stay writable.
  agentSkillDirs = [
    ".claude/skills"
    ".codex/skills"
    ".kiro/skills"
  ];
in
{
  home.file = lib.listToAttrs (
    lib.concatMap (
      dir:
      map (skill: {
        name = "${dir}/${skill}";
        value.source = ./skills/${skill};
      }) skills
    ) agentSkillDirs
  );
}
