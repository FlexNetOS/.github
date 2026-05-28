#!/usr/bin/env bash
# gitmodules-drift-guard.sh
# PreToolUse(Edit|Write|MultiEdit) hook: when .gitmodules is edited, remind that
# repos/MANIFEST.yaml is the single source of truth (mirrors manifest-drift.yml CI).
# Advisory only — never blocks. Repo-relative invocation:
#   bash scripts/hooks/gitmodules-drift-guard.sh
set -euo pipefail

stdin="$(cat 2>/dev/null || true)"
file="${TOOL_INPUT_FILE_PATH:-}"
if [ -z "$file" ] && [ -n "$stdin" ]; then
  file="$(printf '%s' "$stdin" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
fi

case "$file" in
  */.gitmodules|.gitmodules)
    msg="repos/MANIFEST.yaml is the source of truth for submodules; keep it consistent with .gitmodules (see manifest-drift.yml). Prefer 'make submodules.add' over hand-editing."
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[gitmodules-drift-guard] %s"}}\n' "$msg"
    ;;
esac
exit 0
