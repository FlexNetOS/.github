#!/usr/bin/env bash
# Sync selected Bitwarden/Vaultwarden vault items into GitHub Actions secrets.
#
# This script NEVER prints secret values. It reads a tab-separated mapping file
# and writes each mapped value to GitHub using `gh secret set --body`.
#
# Requirements:
#   - bw CLI authenticated and unlocked (`BW_SESSION` exported), or pass
#     --unlock to prompt for unlock and capture a session for this process.
#   - gh CLI authenticated with repo/admin:org scope as needed.
#   - Optional: BW_SERVER=https://vault.example.com for Vaultwarden.
#
# Mapping columns, tab-separated:
#   scope  target  secret_name  bw_item  bw_field  visibility  repos
#
# scope:
#   repo   target = OWNER/REPO
#   env    target = OWNER/REPO:ENVIRONMENT
#   org    target = ORG
#
# bw_field:
#   password | username | notes | field:<custom-field-name>
#
# visibility/repos are only used for org secrets:
#   visibility = all | private | selected
#   repos      = comma-separated repo names when visibility=selected
#
# Usage:
#   scripts/secrets-sync-github-from-bitwarden.sh --map secrets/github-secrets.tsv --dry-run
#   BW_SERVER=https://vault.example.test BW_SESSION=... scripts/secrets-sync-github-from-bitwarden.sh --map secrets/github-secrets.tsv
#   scripts/secrets-sync-github-from-bitwarden.sh --map secrets/github-secrets.tsv --unlock

set -euo pipefail

MAP_FILE="secrets/github-secrets.tsv"
DRY_RUN=0
UNLOCK=0

usage() {
  cat <<'EOF'
Usage: scripts/secrets-sync-github-from-bitwarden.sh [--map FILE] [--dry-run] [--unlock]

Sync selected Bitwarden/Vaultwarden vault items into GitHub Actions secrets.
See secrets/github-secrets.tsv.example for the mapping format.

Environment:
  BW_SERVER     Optional Bitwarden/Vaultwarden server URL.
  BW_SESSION    Required unless --unlock is used and bw is already logged in.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --map) MAP_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --unlock) UNLOCK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -f "$MAP_FILE" ]] || { echo "ERROR: mapping file not found: $MAP_FILE" >&2; exit 1; }
command -v bw >/dev/null 2>&1 || { echo "ERROR: bw CLI not installed" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI not installed" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }

gh auth status >/dev/null

if [[ -n "${BW_SERVER:-}" && "$DRY_RUN" -ne 1 ]]; then
  bw config server "$BW_SERVER" >/dev/null
fi

if [[ "$UNLOCK" -eq 1 ]]; then
  BW_SESSION="$(bw unlock --raw)"
  export BW_SESSION
fi

if [[ "$DRY_RUN" -ne 1 ]]; then
  [[ -n "${BW_SESSION:-}" ]] || {
    echo "ERROR: BW_SESSION is required unless --unlock is used." >&2
    echo "Hint: export BW_SESSION=\"$(bw unlock --raw)\"" >&2
    exit 1
  }
fi

validate_secret_name() {
  local name="$1"
  [[ "$name" =~ ^[A-Z_][A-Z0-9_]*$ ]]
}

extract_value() {
  local item_ref="$1"
  local field_ref="$2"
  local item_json
  item_json="$(bw get item "$item_ref" --session "$BW_SESSION")"
  ITEM_JSON="$item_json" python3 - "$field_ref" <<'PY'
import json
import os
import sys

field = sys.argv[1]
item = json.loads(os.environ["ITEM_JSON"])

if field == "password":
    value = (item.get("login") or {}).get("password")
elif field == "username":
    value = (item.get("login") or {}).get("username")
elif field == "notes":
    value = item.get("notes")
elif field.startswith("field:"):
    wanted = field.split(":", 1)[1]
    value = None
    for custom in item.get("fields") or []:
        if custom.get("name") == wanted:
            value = custom.get("value")
            break
else:
    raise SystemExit(f"unsupported bw_field: {field}")

if value is None or value == "":
    raise SystemExit(f"missing or empty Bitwarden value for field: {field}")

sys.stdout.write(value)
PY
}

sync_one() {
  local scope="$1"
  local target="$2"
  local secret_name="$3"
  local bw_item="$4"
  local bw_field="$5"
  local visibility="$6"
  local repos="$7"

  validate_secret_name "$secret_name" || {
    echo "ERROR: invalid GitHub secret name '$secret_name' (use A-Z, 0-9, underscore; start with A-Z/_)." >&2
    return 1
  }

  if [[ "$DRY_RUN" -eq 1 ]]; then
    case "$scope" in
      repo) echo "DRY: repo $target <- $secret_name from bw item '$bw_item' field '$bw_field'" ;;
      env)  echo "DRY: env  $target <- $secret_name from bw item '$bw_item' field '$bw_field'" ;;
      org)  echo "DRY: org  $target <- $secret_name from bw item '$bw_item' field '$bw_field' visibility=${visibility:-private} repos=${repos:-}" ;;
      *)    echo "ERROR: unsupported scope '$scope'" >&2; return 1 ;;
    esac
    return 0
  fi

  local value
  value="$(extract_value "$bw_item" "$bw_field")"
  echo "::add-mask::$value"

  case "$scope" in
    repo)
      printf '%s' "$value" | gh secret set "$secret_name" --repo "$target" >/dev/null
      echo "SET: repo $target/$secret_name"
      ;;
    env)
      local repo env
      repo="${target%%:*}"
      env="${target#*:}"
      [[ "$repo" != "$target" && -n "$env" ]] || { echo "ERROR: env target must be OWNER/REPO:ENV" >&2; return 1; }
      printf '%s' "$value" | gh secret set "$secret_name" --repo "$repo" --env "$env" >/dev/null
      echo "SET: env $repo:$env/$secret_name"
      ;;
    org)
      visibility="${visibility:-private}"
      case "$visibility" in
        all|private)
          printf '%s' "$value" | gh secret set "$secret_name" --org "$target" --visibility "$visibility" >/dev/null
          ;;
        selected)
          [[ -n "$repos" ]] || { echo "ERROR: selected org secret requires repos column" >&2; return 1; }
          printf '%s' "$value" | gh secret set "$secret_name" --org "$target" --visibility selected --repos "$repos" >/dev/null
          ;;
        *) echo "ERROR: invalid org visibility '$visibility'" >&2; return 1 ;;
      esac
      echo "SET: org $target/$secret_name"
      ;;
    *)
      echo "ERROR: unsupported scope '$scope'" >&2
      return 1
      ;;
  esac
}

count=0
while IFS=$'\t' read -r scope target secret_name bw_item bw_field visibility repos extra; do
  # skip comments, blank lines, and a header row
  [[ -z "${scope:-}" || "$scope" == \#* || "$scope" == "scope" ]] && continue
  [[ -z "${extra:-}" ]] || { echo "ERROR: too many columns in mapping line for $secret_name" >&2; exit 1; }
  [[ -n "${target:-}" && -n "${secret_name:-}" && -n "${bw_item:-}" && -n "${bw_field:-}" ]] || {
    echo "ERROR: mapping row missing required columns: scope target secret_name bw_item bw_field" >&2
    exit 1
  }
  sync_one "$scope" "$target" "$secret_name" "$bw_item" "$bw_field" "${visibility:-}" "${repos:-}"
  count=$((count + 1))
done < "$MAP_FILE"

echo "Summary: $count GitHub secret mapping(s) processed."
