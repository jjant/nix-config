# Brazil CLI tab-completion for fish.
#
# Brazil only ships bash/zsh completions. Both delegate to the
# `brazil-cmd-complete` helper: it receives the command-line tokens (plus a
# trailing "/" sentinel when the line ends in a space) and prints
# newline-separated candidates for the current argument position. This wraps
# that same helper for fish.
#
# Fish narrows the returned list against the token under the cursor, so the
# function just returns the full candidate set for the current argument and
# lets fish filter by prefix.

function __brazil_complete
    # No-op if the Brazil CLI isn't installed on this host.
    command -q brazil-cmd-complete; or return

    set -l tokens (commandline --current-process --tokenize --cut-at-cursor)
    if test (commandline --current-token --cut-at-cursor) = ""
        # Cursor sits after a space: ask for the next argument's candidates.
        brazil-cmd-complete $tokens /
    else
        # Completing a partially typed token.
        brazil-cmd-complete $tokens ""
    end
end

# -f: brazil subcommands/args are not files, so suppress file completion.
complete -c brazil -f -a '(__brazil_complete)'
