#!/usr/bin/env bash
#
# Uninstall the agentic-os harness.
# Default: stop daemon, remove systemd unit symlink. Preserves ~/.agentic-os/.
# --purge: also delete ~/.agentic-os/ (config, queue, cost log, freellmapi clone).
#
# Usage:
#   bash uninstall.sh
#   bash uninstall.sh --purge

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE=""
[ "${1:-}" = "--purge" ] && PURGE=1

# --- Stop daemon ---------------------------------------------------------
echo "==> Stopping daemon (if running)"
bash "${SCRIPT_DIR}/stop.sh" || true

# --- systemd --user unit -------------------------------------------------
SYSTEMD_LINK="${HOME}/.config/systemd/user/ecc-agentic-os.service"
if [ -L "${SYSTEMD_LINK}" ] || [ -f "${SYSTEMD_LINK}" ]; then
  echo "==> Removing systemd unit ${SYSTEMD_LINK}"
  systemctl --user disable --now ecc-agentic-os.service 2>/dev/null || true
  rm -f "${SYSTEMD_LINK}"
  systemctl --user daemon-reload 2>/dev/null || true
fi

# --- State / data --------------------------------------------------------
if [ -n "${PURGE}" ]; then
  echo "==> Purging ${HOME}/.agentic-os/"
  rm -rf "${HOME}/.agentic-os"
  echo "All agentic-os data removed."
else
  echo "==> ${HOME}/.agentic-os/ preserved (use --purge to remove)"
  echo "    - config.json, queue.json, cost-log.jsonl, freellmapi/ all intact."
fi

echo "Uninstall complete."
