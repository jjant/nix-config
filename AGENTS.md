# AGENTS.md

Guidance for AI agents (and humans) working in this repo. See `README.md` for
what the repo is and how to apply configs.

## Before you push — run CI locally

CI (`.github/workflows/ci.yml`) gates every push and PR with a **lint** job and
a per-host **build** matrix. Run the same checks locally *before* pushing so you
never raise a PR with a red check.

### 1. Lint — always run both, both must exit 0

```bash
nix run nixpkgs#statix -- check .   # anti-patterns (e.g. repeated attrset keys)
nix run nixpkgs#deadnix -- -f .     # dead / unused Nix code
```

Note: `statix` flags **repeated top-level keys**. Don't split one attribute
across several assignments (e.g. `system.foo = ...;` next to a separate
`system = { ... };`) — fold them into a single attrset instead.

### 2. Build the host config(s) you touched

Use the exact command CI uses for each host (from the build matrix in
`ci.yml`):

| Host           | Command                                                        |
| -------------- | -------------------------------------------------------------- |
| mac-m1 (Darwin)| `nix eval .#darwinConfigurations.mac-m1.system`                |
| al2-x86_64     | `nix build .#homeConfigurations.al2-x86_64.activationPackage`  |
| al2023-x86_64  | `nix build .#homeConfigurations.al2023-x86_64.activationPackage` |
| al2-aarch64    | `nix eval .#homeConfigurations.al2-aarch64.activationPackage`   |

If you changed a shared module under `modules/home/`, evaluate **all** hosts —
it feeds every configuration.

## Commits & PRs

- Follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat`, `fix`, `refactor`, `chore`, …) to match existing history.
- Never force-push or amend a commit that's already been pushed. Fix forward
  with a new commit; let GitHub squash on merge if you want a single commit.
