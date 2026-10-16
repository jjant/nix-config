---
name: cloud-desktop-builds
description: Prevent memory and tmpfs stalls when running local builds, coverage, test compilation, or compiled previews on a Linux Cloud Desktop shared by several agent or tmux sessions. Use before launching those workloads and when diagnosing a stuck build; skip ordinary reads, edits, and remote build submissions.
---

# Cloud Desktop Builds

Coordinate expensive local work across sessions. Continue using the workspace's
normal build entrypoint and required testing tools; these controls do not replace
the package's build or integration-test workflow.

## Before launching expensive work

Inspect memory, the temporary filesystem, and competing builds:

```bash
free -h
df -h /tmp "$HOME"
findmnt -T /tmp
cat /proc/pressure/memory
ps -u "$(id -u)" -o pid,ppid,stat,rss,comm --sort=-rss | head -25
```

On cgroup v2, read `/proc/self/cgroup`, find the `0::` entry under
`/sys/fs/cgroup`, and walk its ancestors. Inspect `memory.current`,
`memory.high`, `memory.max`, `memory.events`, and `memory.pressure` where
present. The tightest ancestor matters, including `tmux-panes.slice`.

Free host RAM does not mean a pane has headroom. A pane can stall indefinitely at
`memory.high` without reaching `memory.max` or triggering the host's earlyoom.
Rising `high` events and sustained pressure identify this; a process waiting in
`mem_cgroup_handle_over_high` is direct evidence. Compare event counters across
samples rather than treating an old nonzero count as a current incident.

If another heavy build is already running, or current memory pressure is
substantial, do useful editing or review while it finishes. Do not launch a
duplicate build or preview to work around a slow command.

## Coordinate builds and keep artifacts on disk

For shell-driven workloads, use one shared lock per user and host, including
across workspaces and tmux sessions. Create private directories once:

```bash
(umask 077; mkdir -p "$HOME/.cache/cloud-desktop-builds/tmp")
```

Use this pattern, substituting the actual required build command:

```bash
flock --exclusive --nonblock --conflict-exit-code 75 --close \
  "$HOME/.cache/cloud-desktop-builds/heavy.lock" \
  env CARGO_BUILD_JOBS=4 \
      CMAKE_BUILD_PARALLEL_LEVEL=4 \
      NEXTEST_TEST_THREADS=4 \
      RUST_TEST_THREADS=4 \
      TMPDIR="$HOME/.cache/cloud-desktop-builds/tmp" \
  brazil-build release
```

`75` means the lock was unavailable: defer the workload rather than retrying
tightly or dropping the lock. `--close` prevents spawned daemons from keeping
the lock after the build command exits. Coordinate with existing builds that
predate or do not use this lock; the lock cannot control those processes.

Four workers is a conservative default for the observed multi-GiB Rust link
steps. Reduce it if cgroup headroom is low. Raise it only after measuring peak
memory and checking competing work. An explicit `-j`, a build configuration,
or another test runner may override these environment variables; check the
actual entrypoint rather than assuming every tool honors them.

Do not put Cargo target directories, coverage outputs, generated assemblies,
or browser installations in a tmpfs. Prefer the workspace's existing build
directory and cache. If isolation is needed, use a directory on disk and check
available disk space first. Setting `TMPDIR` does not override an explicit
`--target-dir /tmp/...` or application-specific output path.

For tools that own test execution, use their supported concurrency controls
and serialize submissions; do not bypass a required runner to use this shell
example.

## Track and finish work

Keep each build's execution handle and log location. Check the existing run
before retrying after an interruption. Killing tmux or closing an agent does
not reliably stop child builds in systemd scopes.

When a command stops progressing, inspect its cgroup pressure and process tree.
Check for a retained build before starting another one. Stop only work owned by
the current task or explicitly authorized by the user, checking PID identity
and descendants before signalling. Do not kill all user processes, stop the
entire tmux slice, delete unrelated `/tmp` contents, or raise resource limits
as a routine build workaround.

These instructions are coordination, not enforced isolation. If pressure
repeats despite serialization and bounded concurrency, propose a dedicated
build cgroup with a hard memory limit and cancellation of that build's
process tree, leaving interactive sessions usable.
