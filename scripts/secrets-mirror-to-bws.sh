#!/usr/bin/env bash
# Mirror the local `pass` store into Bitwarden Secrets Manager.
# One-way: pass is source of truth; BWS is downstream mirror.
#
# Requires: bws CLI authenticated with a project-scoped access token.
# Set BWS_ACCESS_TOKEN before running (export, .env, or systemd EnvFile).
#
# Usage:
#   scripts/secrets-mirror-to-bws.sh --project-id <UUID>
#   scripts/secrets-mirror-to-bws.sh --project-id <UUID> --filter runner/   # only one subtree

set -euo pipefail

STORE="${PASSWORD_STORE_DIR:-./secrets/store}"
PROJECT_ID=""
FILTER=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/secrets-mirror-to-bws.sh --project-id <UUID> [--filter PREFIX] [--dry-run]

Mirrors every pass entry under the (optional) PREFIX into the Bitwarden
Secrets Manager project identified by --project-id.

Existing BWS secrets with the same name are UPDATED (not duplicated).
Secrets that exist in BWS but not in pass are LEFT ALONE (no deletes).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --filter)     FILTER="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -z "$PROJECT_ID" ]] && { echo "ERROR: --project-id required" >&2; usage; exit 2; }
[[ -z "${BWS_ACCESS_TOKEN:-}" ]] && { echo "ERROR: BWS_ACCESS_TOKEN env var required" >&2; exit 1; }
command -v bws >/dev/null 2>&1 || { echo "ERROR: bws CLI not installed" >&2; exit 1; }
command -v pass >/dev/null 2>&1 || { echo "ERROR: pass not installed" >&2; exit 1; }

# Build a name → id map of existing BWS secrets for this project, for upserts.
declare -A BWS_NAME_TO_ID=()
while IFS=$'\t' read -r id name; do
    BWS_NAME_TO_ID["$name"]="$id"
done < <(bws secret list "$PROJECT_ID" --output json | \
         python3 -c 'import json,sys
for s in json.load(sys.stdin):
    print(f"{s[\"id\"]}\t{s[\"key\"]}")')

upserts=0
skips=0

while IFS= read -r -d '' f; do
    rel="${f#$STORE/}"
    rel="${rel%.gpg}"
    [[ -n "$FILTER" && "$rel" != "$FILTER"* ]] && continue

    val=$(pass show "$rel")
    name="$rel"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        if [[ -n "${BWS_NAME_TO_ID[$name]:-}" ]]; then
            echo "DRY: would update $name (id ${BWS_NAME_TO_ID[$name]})"
        else
            echo "DRY: would create $name"
        fi
        continue
    fi

    if [[ -n "${BWS_NAME_TO_ID[$name]:-}" ]]; then
        bws secret edit "${BWS_NAME_TO_ID[$name]}" --value "$val" >/dev/null
        echo "UPDATE: $name"
    else
        bws secret create "$name" "$val" "$PROJECT_ID" >/dev/null
        echo "CREATE: $name"
    fi
    upserts=$((upserts + 1))
done < <(find "$STORE" -type f -name '*.gpg' -print0)

echo
echo "Summary: $upserts upserted · $skips skipped"
