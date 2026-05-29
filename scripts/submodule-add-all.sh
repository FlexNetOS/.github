#!/usr/bin/env bash
# Reads repos/MANIFEST.yaml and runs `git submodule add` for any entry not
# yet present in .gitmodules. Idempotent. Safe to re-run.
#
# 404 handling:
#   - Tagged entries (# depends-on: USER.TODO#5) that 404: WARN + skip, exit 0.
#     These are known-pending forks; the fork is a deliberate human step.
#   - Untagged entries that 404: ERROR + exit 1. Requires operator action.
#
# Requires: git, python3, gh (for URL probing and --create-missing).

set -euo pipefail

MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"
DRY_RUN=0
CREATE_MISSING=0

usage() {
  cat <<'EOF'
Usage: scripts/submodule-add-all.sh [--dry-run] [--create-missing]

  --dry-run         Print the `git submodule add` commands without running.
  --create-missing  For any entry whose `url` 404s on GitHub, attempt
                    `gh repo create` (FlexNetOS/* only) or warn.

Reads repos/MANIFEST.yaml (override with MANIFEST=path env var).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --create-missing) CREATE_MISSING=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found" >&2; exit 1; }

[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found at $MANIFEST" >&2; exit 1; }

# Resolve the repo root so paths work regardless of cwd.
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Precompute set of paths tagged with `# depends-on: USER.TODO#5`.
# These are known-pending forks; a 404 on them is expected and not an error.
TAGGED_PATHS=$(awk '
  /^- path:/ { name=$0; sub(/^- path:[ \t]*/, "", name); sub(/[ \t]*$/, "", name) }
  /depends-on: USER\.TODO#5/ && name != "" { print name }
' "$MANIFEST")

is_tagged() {
  echo "$TAGGED_PATHS" | grep -qxF "$1"
}

count=$(python3 scripts/manifest-query.py "$MANIFEST" --count)
added=0
skipped=0
errored=0

while IFS=$'\t' read -r path url branch partial; do

  if [[ -z "$path" || "$path" == "null" ]]; then continue; fi
  if [[ -z "$url"  || "$url"  == "null" ]]; then
    echo "WARN: manifest entry for $path has no url, skipping"
    continue
  fi

  # Already a registered submodule?
  if git config --file .gitmodules --get "submodule.${path}.url" >/dev/null 2>&1; then
    skipped=$((skipped + 1))
    continue
  fi

  # Probe the URL when gh is available.
  if command -v gh >/dev/null 2>&1; then
    repo_slug="${url#https://github.com/}"
    if ! gh repo view "$repo_slug" >/dev/null 2>&1; then
      if [[ "$CREATE_MISSING" -eq 1 ]] && [[ "$repo_slug" == FlexNetOS/* ]]; then
        echo "INFO: $url not found; attempting gh repo create…"
        gh repo create "$repo_slug" --public --description "FlexNetOS umbrella submodule" || {
          echo "ERROR: failed to create $url" >&2; errored=$((errored + 1)); continue;
        }
      elif is_tagged "$path"; then
        echo "WARN: $url not found (tagged depends-on: USER.TODO#5 — fork pending, skipping)"
        skipped=$((skipped + 1))
        continue
      else
        echo "ERROR: $url not found and not tagged depends-on: USER.TODO#5 — operator action required" >&2
        errored=$((errored + 1))
        continue
      fi
    fi
  fi

  cmd=(git submodule add --depth=1 -b "$branch" "$url" "$path")
  if [[ -n "$partial" ]]; then
    # `git submodule add` doesn't expose --filter, so do a manual clone then
    # `git submodule add --no-clone` flow if/when git supports it. For now,
    # warn and fall through to the normal add — caller can re-clone with the
    # filter manually if size becomes a problem.
    echo "INFO: partial_clone=$partial requested for $path; manual filter clone may be needed after add."
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY: ${cmd[*]}"
  else
    echo "RUN: ${cmd[*]}"
    if "${cmd[@]}"; then
      added=$((added + 1))
    else
      errored=$((errored + 1))
    fi
  fi
done < <(python3 scripts/manifest-query.py "$MANIFEST" --fields path,url,branch,partial_clone)

echo
echo "Summary: $added added · $skipped already-present/skipped · $errored errored · $count total"
exit $errored
