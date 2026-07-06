# ada CLI tab-completion for fish.
#
# ada emits its own fish completion script via `ada completion fish`. Source it
# lazily — fish autoloads this file on the first `ada <TAB>` — so the
# completions always match the installed version.
#
# Guarded with `command -q ada` so this is a no-op on hosts where ada isn't
# installed: nothing is sourced and no error is produced.

if command -q ada
    ada completion fish | source
end
