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
- After creating a PR, open it in the browser so the reviewer can look it over
  and merge it on GitHub: run `open <pr-url>` on the URL `gh pr create` prints
  (Linux desktops: `xdg-open`), or pass `-o` / `--web` to `gh pr create`.

## After a PR merges — clean up

Once a PR is merged, sync `main` and remove the stale branch:

```bash
git checkout main
git pull --ff-only
git fetch --prune   # drops remote-tracking refs GitHub auto-deleted on merge
```

This repo **squash-merges**, so a branch's commits never become ancestors of
`main` and `git branch -d` will refuse to delete it ("not fully merged"). That
refusal is expected — it does **not** mean the work is missing. Confirm the
merge first (signals below), then delete with `git branch -D`.

Trustworthy "it was merged" signals:

- The PR shows as merged (`gh pr view <number>`), or its head branch was
  auto-deleted on the remote.
- After `git fetch --prune`, the local branch shows a `[gone]` upstream in
  `git branch -vv`.

Sweep every local branch whose remote was deleted on merge:

```bash
git branch -vv | awk '/: gone]/ {print $1}' | xargs -r git branch -D
```

Only delete branches you've confirmed merged. Never delete one that still has
unpushed or unmerged work, and leave unrelated branches alone.
