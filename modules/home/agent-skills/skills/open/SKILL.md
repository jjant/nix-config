---
name: open
description: Open files, directories and URLs for the user to look at. Use when the user asks to open, show, view or preview something (a URL, PR, report, HTML page, PDF, image), or when handing them a generated artifact to look at.
---

# Opening things for the user

Run `open` (or `xdg-open`, same thing) with the path or URL. It just works on
every host: on a Linux dev desk it is already wired to copy the target to the
Mac and open it there. Don't check `which`, read the script, or inspect the
SSH tunnel first.

```bash
open https://example.com/pr/123    # URLs: http(s):// only; add the scheme
open report.pdf output/            # files and directories, several at once
open -d build/report/index.html    # HTML with sibling CSS/JS/images
open -s artifact.zip               # only when the user asks to share: prints a Drive link
```

- A file opened from a dev desk is a copy: stdout prints its Mac-side path, and
  later edits are not reflected. Re-run `open` after regenerating.
- On failure, show the user the error and stop. Don't debug the tunnel; the
  message already says what to do (e.g. reconnect with `ssh <desk alias>`).
