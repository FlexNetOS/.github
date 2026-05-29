#!/usr/bin/env bash
#
# Stop the agentic-os harness daemon.
# Sends SIGTERM to the PID in ~/.agentic-os/harness.pid; falls back to pkill.
#
# Usage:
#   bash stop.sh

set -euo pipefail

PIDFILE="${HOME}/.agentic-os/harness.pid"

if [ -f "${PIDFILE}" ]; then
  PID="$(cat "${PIDFILE}")"
  if kill -0 "${PID}" 2>/dev/null; then
    echo "stopping harness pid ${PID}"
    kill -TERM "${PID}"
    for _ in 1 2 3 4 5; do
      sleep 1
      kill -0 "${PID}" 2>/dev/null || { echo "stopped"; exit 0; }
    done
    echo "harness did not stop on SIGTERM; sending SIGKILL"
    kill -KILL "${PID}" || true
    exit 0
  fi
  rm -f "${PIDFILE}"
fi

# Fallback if PID file is missing
if pkill -f 'agentic-os/harness.js --serve' 2>/dev/null; then
  echo "harness processes terminated (pkill fallback)"
else
  echo "no harness running"
fi
