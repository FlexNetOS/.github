#!/usr/bin/env bash
# Bump each submodule to its tracked branch HEAD (fast-forward only).
# Filter by group: --group core   (matches MANIFEST.yaml groups)
# Filter by name:  --name ruvector
# Default: all submodules.
#
# Idempotent. Reports which submodules changed.

set -euo pipefail

MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"
GROUP=""
NAME=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/submodule-bump.sh [--group GROUP] [--name NAME] [--dry-run]

Filters (combine freely):
  --group GROUP   Bump only submodules tagged with this group.
  --name NAME     Bump only the submodule whose path basename matches NAME.

Behavior: per submodule, fetch tracked branch, fast-forward only.
On success, the parent repo's submodule pointer is updated but NOT committed —
review and commit the resulting `git status` yourself.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --group) GROUP="$2"; shift 2 ;;
    --name)  NAME="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

changed=0
unchanged=0
errored=0

while IFS=$'\t' read -r path branch groups; do

  [[ -z "$path" || "$path" == "null" ]] && continue
  [[ ! -d "$path/.git" && ! -f "$path/.git" ]] && {
    echo "SKIP: $path — not initialized, run \`make submodules.init\` first"
    continue
  }

  # Apply filters
  if [[ -n "$GROUP" ]]; then
    [[ " $groups " == *" $GROUP "* ]] || continue
  fi
  if [[ -n "$NAME" ]]; then
    [[ "$(basename "$path")" == "$NAME" ]] || continue
  fi

  before=$(git -C "$path" rev-parse HEAD)

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY: would bump $path on $branch (currently $before)"
    continue
  fi

  if ! git -C "$path" fetch --quiet origin "$branch"; then
    echo "ERROR fetch: $path"
    errored=$((errored + 1))
    continue
  fi

  if ! git -C "$path" merge --ff-only "origin/$branch" 2>/dev/null; then
    echo "ERROR ff-only: $path — manual intervention needed (diverged from $branch)"
    errored=$((errored + 1))
    continue
  fi

  after=$(git -C "$path" rev-parse HEAD)
  if [[ "$before" != "$after" ]]; then
    echo "BUMP: $path  $before → $after"
    changed=$((changed + 1))
  else
    unchanged=$((unchanged + 1))
  fi
done < <(python3 scripts/manifest-query.py "$MANIFEST" --fields path,branch,groups)

echo
echo "Summary: $changed bumped · $unchanged unchanged · $errored errored"
[[ "$changed" -gt 0 ]] && echo "Next: review \`git status\` and commit the submodule bumps."
exit $errored
