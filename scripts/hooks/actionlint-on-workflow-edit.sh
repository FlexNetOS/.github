#!/usr/bin/env bash
# actionlint-on-workflow-edit.sh
# PostToolUse(Edit|Write|MultiEdit) hook: lint a GitHub Actions workflow the
# moment Claude edits one, mirroring `make verify.actionlint` locally.
# Repo-relative invocation: bash scripts/hooks/actionlint-on-workflow-edit.sh
# Non-fatal: exit 2 surfaces lint output back to Claude as feedback; never blocks the user.
set -euo pipefail

stdin="$(cat 2>/dev/null || true)"
file="${TOOL_INPUT_FILE_PATH:-}"
if [ -z "$file" ] && [ -n "$stdin" ]; then
  file="$(printf '%s' "$stdin" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
fi

case "$file" in
  *.github/workflows/*.yml|*.github/workflows/*.yaml) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -x "$root/tools/bin/actionlint" ] || exit 0

if ! "$root/tools/bin/actionlint" "$file" 1>&2; then
  echo "[actionlint] workflow lint failed for $file — fix before committing (make verify.actionlint)." >&2
  exit 2
fi
exit 0
