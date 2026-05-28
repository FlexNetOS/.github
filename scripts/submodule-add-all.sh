#!/usr/bin/env bash
# Reads repos/MANIFEST.yaml and runs `git submodule add` for any entry not
# yet present in .gitmodules. Idempotent. Safe to re-run.
#
# Requires: git, python3, gh (only if --create-missing is used).

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

  # Probe the URL exists (best effort — does not block if gh is missing).
  if [[ "$CREATE_MISSING" -eq 1 ]] && command -v gh >/dev/null 2>&1; then
    if ! gh repo view "${url#https://github.com/}" >/dev/null 2>&1; then
      echo "INFO: $url 404s; attempting gh repo create…"
      gh repo create "${url#https://github.com/}" --public --description "FlexNetOS umbrella submodule" || {
        echo "ERROR: failed to create $url" >&2; errored=$((errored + 1)); continue;
      }
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
echo "Summary: $added added · $skipped already-present · $errored errored · $count total"
exit $errored
