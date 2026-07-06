# Toolbox CLI tab-completion for fish.
#
# The Amazon `toolbox` CLI (cobra-based) emits its own fish completion script
# via `toolbox completion fish`. Source it lazily — fish autoloads this file on
# the first `toolbox <TAB>` — so the completions always match the installed
# toolbox version.
#
# Guarded with `command -q toolbox` so this is a no-op on hosts where toolbox
# isn't installed (e.g. a fresh machine, or before the Amazon toolbox setup):
# nothing is sourced and no error is produced.

if command -q toolbox
    toolbox completion fish | source
end
