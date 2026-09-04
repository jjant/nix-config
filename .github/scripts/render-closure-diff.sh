#!/usr/bin/env bash

set -euo pipefail

diff_dir="${1:?usage: render-closure-diff.sh DIFF_DIR OUTPUT_FILE}"
output_file="${2:?usage: render-closure-diff.sh DIFF_DIR OUTPUT_FILE}"

shopt -s nullglob
diff_files=("$diff_dir"/*.txt)

if (( ${#diff_files[@]} == 0 )); then
  echo "No closure diff files found in $diff_dir" >&2
  exit 1
fi

declare -A first_file_by_hash=()
declare -A hosts_by_hash=()
declare -a hashes=()

for diff_file in "${diff_files[@]}"; do
  host="$(basename "$diff_file" .txt)"
  hash="$(sha256sum "$diff_file" | awk '{ print $1 }')"

  if [[ -z "${first_file_by_hash[$hash]+set}" ]]; then
    first_file_by_hash["$hash"]="$diff_file"
    hosts_by_hash["$hash"]="$host"
    hashes+=("$hash")
  else
    hosts_by_hash["$hash"]+=$'\n'"$host"
  fi
done

render_comment() {
  local line_limit="$1"

  {
    echo '<!-- flake-closure-diff -->'
    echo '## Flake closure changes'
    echo
    echo 'Package-level changes in the host configurations built by this PR:'

    for hash in "${hashes[@]}"; do
      diff_file="${first_file_by_hash[$hash]}"
      host_summary=""

      while IFS= read -r host; do
        if [[ -n "$host_summary" ]]; then
          host_summary+=", "
        fi
        host_summary+="<code>$host</code>"
      done <<< "${hosts_by_hash[$hash]}"

      entry_count="$(awk 'NF { count++ } END { print count + 0 }' "$diff_file")"

      echo
      echo '<details open>'
      if (( entry_count == 0 )); then
        echo "<summary>$host_summary — no package-level changes</summary>"
        echo
        echo 'No package additions, removals, version changes, or significant size changes were detected.'
      else
        echo "<summary>$host_summary — $entry_count changed closure entries</summary>"
        echo
        echo '```text'
        sed -n "1,${line_limit}p" "$diff_file"
        echo '```'

        if (( entry_count > line_limit )); then
          echo
          echo "_Showing the first $line_limit entries; the complete diff is available in the workflow artifact._"
        fi
      fi
      echo
      echo '</details>'
    done

    echo
    echo "Generated with \`nix store diff-closures\` by comparing the base and PR host closures. This summarizes realized package changes, not every upstream commit."
  } > "$output_file"
}

render_comment "${MAX_DIFF_LINES:-150}"

# GitHub issue comments are limited to 65,536 characters. Leave some room for
# encoding overhead and retry with tighter summaries when an update is large.
if (( $(wc -c < "$output_file") > 60000 )); then
  render_comment 50
fi

if (( $(wc -c < "$output_file") > 60000 )); then
  render_comment 20
fi

if (( $(wc -c < "$output_file") > 60000 )); then
  echo "Rendered closure diff is still too large for a PR comment" >&2
  exit 1
fi
