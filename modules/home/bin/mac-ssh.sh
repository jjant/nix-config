#!/usr/bin/env bash
# Reach the Mac's forced command through the dev desk's loopback tunnel.
# The pinned OpenSSH supports accept-new even on AL2. On AL2023 its parser
# rejects the system SSH config, so use only these options and the forwarded
# agent in SSH_AUTH_SOCK. All callers can reuse the same authenticated socket.
exec ssh -F /dev/null -p "${MAC_OPEN_PORT:-2022}" \
  -o StrictHostKeyChecking=accept-new -o ControlMaster=auto \
  -o "ControlPath=$HOME/.ssh/mac-open-%r@%h:%p" -o ControlPersist=10s \
  "${MAC_OPEN_USER:-jjantdev}@localhost" "$@"
