# art CLI tab-completion for fish.
#
# art emits its own fish completion script via `art completions fish`. Source
# it lazily — fish autoloads this file on the first `art <TAB>` — so the
# completions always match the installed version.
#
# Guarded so it's a no-op when art isn't installed; stderr is discarded so an
# art build that predates the `completions` subcommand produces nothing (rather
# than an "unrecognized subcommand" error) until it's available everywhere.

if command -q art
    art completions fish 2>/dev/null | source
end
