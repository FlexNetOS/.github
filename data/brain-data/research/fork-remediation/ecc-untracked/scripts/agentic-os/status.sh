#!/usr/bin/env bash
#
# Human-readable status snapshot for the agentic-os harness.
# Combines: daemon state, freellmapi reachability, channel health,
# queue stats, last-24h cost.
#
# Usage:
#   bash status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="${SCRIPT_DIR}/harness.js"
PIDFILE="${HOME}/.agentic-os/harness.pid"

echo "=== agentic-os status @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

# --- Daemon ---------------------------------------------------------------
if [ -f "${PIDFILE}" ] && kill -0 "$(cat "${PIDFILE}")" 2>/dev/null; then
  PID="$(cat "${PIDFILE}")"
  echo "Daemon:    running (pid ${PID})"
else
  echo "Daemon:    not running"
fi

# --- freellmapi reachability ---------------------------------------------
CFG="${HOME}/.agentic-os/config.json"
ENDPOINT="http://localhost:3001/v1"
if [ -f "${CFG}" ]; then
  EP="$(node -e "try { const c = require('${CFG}'); process.stdout.write(c.freellmapi?.endpoint || ''); } catch (_) {}" 2>/dev/null || true)"
  [ -n "${EP}" ] && ENDPOINT="${EP}"
fi
if curl -fsS --max-time 3 "${ENDPOINT}/models" -o /dev/null 2>&1; then
  echo "freellmapi: reachable (${ENDPOINT})"
else
  echo "freellmapi: unreachable (${ENDPOINT})"
fi

# --- Harness JSON status --------------------------------------------------
echo
echo "--- harness status ---"
node "${HARNESS}" --status 2>&1 || echo "(status query failed)"
