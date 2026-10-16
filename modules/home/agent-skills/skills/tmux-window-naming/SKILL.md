---
name: tmux-window-naming
description: Keep the current tmux window named after the active task. Use when running inside tmux, once the task is understood and when the task changes materially.
---

# tmux Window Naming

Keep the tmux window name describing the current task, so windows are
distinguishable at a glance in the status bar.

## When

- Once, after you understand what the session is about.
- Again only if the task changes materially (different package, different problem).
- Never re-set a name that is already correct; don't poll or re-check it.
- Skip when either `$TMUX` or `$TMUX_PANE` is empty.

## How

Always target `$TMUX_PANE`. The attached client's active window is not necessarily
the one this conversation runs in, so untargeted tmux commands hit the wrong window.

```bash
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  tmux set-option -w -t "$TMUX_PANE" automatic-rename off \
    && tmux rename-window -t "$TMUX_PANE" "<name>"
fi
```

`automatic-rename off` is required: with it on, tmux overwrites the name at the
next shell prompt. Rename the window; pane titles are not displayed unless
`pane-border-status` is on.

## Naming

- Name the task, for example `artemis cdk refactor`. Avoid tool names such as `codex-astra`.
- Maximum 24 characters including spaces. Abbreviate words rather than truncating mid-word.
- Do not mention the rename in your response. It is incidental to the work.

## Never

- Rename, kill or reconfigure any other window, pane or session.
- Change server or global tmux options (`tmux set -g ...`).
