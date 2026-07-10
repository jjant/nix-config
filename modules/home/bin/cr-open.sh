#!/usr/bin/env bash
set -euo pipefail

# cr-open: open the most recent CRUX code review referenced by this
# repository's git history.
#
# When enabled (the CRUX default), `cr --amend` records the review URL in the
# commit message, e.g.
#   cr https://code.amazon.com/reviews/CR-12345678
# so we walk back from HEAD and open the first review URL we find.

usage() {
  echo "Usage: cr-open [N]" >&2
  echo >&2
  echo "Open the latest CRUX code review found in the git history of the" >&2
  echo "current repository. Scans the most recent N commit messages" >&2
  echo "(default 100) for a code.amazon.com review URL and opens it." >&2
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

limit="${1:-100}"

if ! [[ $limit =~ ^[0-9]+$ ]]; then
  echo "cr-open: N must be a positive integer (got '$limit')" >&2
  usage
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "cr-open: not inside a git repository" >&2
  exit 1
fi

# Capture the CR id (CR-<digits>) from the first review URL in the history,
# ignoring any trailing /revisions/... path.
cr_url_re='code\.amazon\.com/reviews/(CR-[0-9]+)'
cr_id=""

while IFS= read -r line; do
  if [[ $line =~ $cr_url_re ]]; then
    cr_id="${BASH_REMATCH[1]}"
    break
  fi
done < <(git log -n "$limit" --format=%B)

if [[ -z $cr_id ]]; then
  echo "cr-open: no code review URL found in the last $limit commit(s)" >&2
  exit 1
fi

url="https://code.amazon.com/reviews/$cr_id"
echo "Opening $url"
open "$url"
