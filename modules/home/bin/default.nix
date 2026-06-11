{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "tmux-sessionizer" ''
      directories=(
        "$HOME"
        "$HOME"/work
        "$HOME"/personal
        "$HOME"/.config
        "$HOME"/workplace
      )
      selected=$(${pkgs.fd}/bin/fd -L --min-depth 1 --max-depth 1 --type d . "''${directories[@]}" | ${pkgs.fzf}/bin/fzf)

      if [[ -z $selected ]]; then
        exit 0
      fi

      session_name=$(basename "$selected" | tr "." "_")

      if ! tmux has-session -t "$session_name" 2> /dev/null; then
        tmux new-session -s "$session_name" -n "workspace" -c "$selected" -d

        parent=$(realpath "$(dirname "$selected")")

        if [[ $parent = "/Volumes/workplace" ]]; then
          for dir in "$selected/src"/*; do
             if [[ -d "$dir" ]]; then
               tmux new-window -c "$dir" -n "$(basename "$dir")" -t "$session_name"
             fi
          done
        fi
      fi

      if [[ -z "$TMUX" ]]; then
        tmux start-server
        tmux attach
      fi

      tmux switch-client -t "$session_name"
    '')

    (pkgs.writeShellScriptBin "brazil-open-package" ''
      if [ "$#" -eq 0 ]; then
        packageName=$(brazil-context package name 2> /dev/null)
        brazilContextSucceeded="$?"
        if [ "$brazilContextSucceeded" -ne 0 ]; then
          >&2 echo "Not in a brazil package."
        fi
      else
        packageName="$1"
      fi

      if [ -n "$packageName" ]; then
        open "https://code.amazon.com/packages/$packageName"
      else
        >&2 echo "Usage: brazil-open-package [BRAZIL_PKG_NAME]"
        exit 1
      fi
    '')

    (pkgs.writeShellScriptBin "dev-desk-tunnel" ''
      if [ -z "$1" ]; then
          echo "Missing port. Usage $0 HOST SOURCE_PORT [OUTPUT_PORT]"
          exit 1
      fi

      USERNAME="jjantdev"
      HOST=$1
      SOURCE_PORT=$2
      OUTPUT_PORT=''${3:-$SOURCE_PORT}

      echo "Tunneling DevDesktop from $SOURCE_PORT to $OUTPUT_PORT"
      ssh -T -L "$SOURCE_PORT":localhost:"$OUTPUT_PORT" "$USERNAME"@"$HOST"
    '')

    (pkgs.writeShellScriptBin "pnew" ''
      set -o pipefail
      set -e

      if [[ $# -eq 0 ]]; then
        echo "Project name required:"
        echo "    $0 my_cool_project"
        exit 1
      fi

      if [[ $# -ne 1 ]]; then
        echo "Too many arguments, only 1 is supported"
        exit $#
      fi

      project_name=$1
      project_directory="$HOME/personal/$project_name"
      mkdir -p "$project_directory"
      git init --quiet "$project_directory"
      echo "Project created at ~/personal/$project_name"
    '')
  ];
}
