#!/usr/bin/env bash
# protect-secrets-store.sh
# PreToolUse(Edit|Write|MultiEdit) hook: hard-block direct edits to the pass/GPG
# vault under secrets/store/. Ciphertext must only change via `pass` or the
# scripts/secrets-*.sh helpers; a stray Edit/Write corrupts it silently.
# Repo-relative invocation: bash scripts/hooks/protect-secrets-store.sh
# exit 2 in PreToolUse blocks the tool call.
set -euo pipefail

stdin="$(cat 2>/dev/null || true)"
file="${TOOL_INPUT_FILE_PATH:-}"
if [ -z "$file" ] && [ -n "$stdin" ]; then
  file="$(printf '%s' "$stdin" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
fi

case "$file" in
  */secrets/store/*|secrets/store/*)
    echo "[protect-secrets-store] BLOCKED: $file is inside the pass/GPG vault (secrets/store/)." >&2
    echo "Change secrets via 'pass' or scripts/secrets-*.sh — never a direct file edit." >&2
    exit 2 ;;
esac
exit 0
