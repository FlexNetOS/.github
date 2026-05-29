#!/usr/bin/env bash
#
# Start the agentic-os harness in the foreground.
# Reads config from ~/.agentic-os/config.json (or $ECC_AGENTIC_OS_CONFIG).
# Use Ctrl-C to stop, or `bash stop.sh` from another shell.
#
# For background/auto-restart, use the systemd --user unit instead:
#   systemctl --user start ecc-agentic-os.service
#
# Usage:
#   bash start.sh [--interval 5000]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="${SCRIPT_DIR}/harness.js"
INTERVAL="${1:-5000}"

if [ ! -f "${HOME}/.agentic-os/config.json" ] && [ -z "${ECC_AGENTIC_OS_CONFIG:-}" ]; then
  echo "warning: no ~/.agentic-os/config.json found; using repo default" >&2
fi

PIDFILE="${HOME}/.agentic-os/harness.pid"
if [ -f "${PIDFILE}" ] && kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; then
  echo "harness already running (pid $(cat "${PIDFILE}"))" >&2
  exit 1
fi

exec node "${HARNESS}" --serve --interval "${INTERVAL}"
