#!/usr/bin/env bash
# For each submodule in `repos/forked/` that has an `upstream` URL in
# MANIFEST.yaml, fetch upstream and merge into the tracked branch.
# Reports conflicts; does not force-resolve.

set -euo pipefail

MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"
DRY_RUN=0
ONLY=""

usage() {
  cat <<'EOF'
Usage: scripts/submodule-sync-upstream.sh [--name NAME] [--dry-run]

For each MANIFEST entry with both `url` (our fork) and `upstream`,
fetch upstream and merge into the tracked branch.

Steps per submodule:
  1. ensure `upstream` remote exists and points at MANIFEST `upstream` URL
  2. git fetch upstream <branch>
  3. git merge --no-ff upstream/<branch>  (no auto-conflict resolution)
  4. report status

On conflict: stops on that submodule and prints next steps. Other
submodules in the run are NOT affected.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) ONLY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

synced=0
conflicts=0
nochange=0

while IFS=$'\t' read -r path url upstream branch; do

  [[ -z "$path" || "$path" == "null" ]] && continue
  [[ -z "$upstream" ]] && continue
  [[ -n "$ONLY" && "$(basename "$path")" != "$ONLY" ]] && continue
  [[ ! -d "$path/.git" && ! -f "$path/.git" ]] && {
    echo "SKIP: $path — not initialized"; continue;
  }

  echo "=== $path  (upstream: $upstream  branch: $branch) ==="

  # Ensure upstream remote exists
  if ! git -C "$path" remote get-url upstream >/dev/null 2>&1; then
    [[ "$DRY_RUN" -eq 1 ]] && echo "DRY: git remote add upstream $upstream" || git -C "$path" remote add upstream "$upstream"
  else
    cur_upstream=$(git -C "$path" remote get-url upstream)
    if [[ "$cur_upstream" != "$upstream" ]]; then
      echo "WARN: upstream remote URL differs ($cur_upstream); updating to $upstream"
      [[ "$DRY_RUN" -eq 1 ]] && echo "DRY: git remote set-url upstream $upstream" || git -C "$path" remote set-url upstream "$upstream"
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY: git fetch upstream $branch && git merge --no-ff upstream/$branch"
    continue
  fi

  if ! git -C "$path" fetch --quiet upstream "$branch"; then
    echo "ERROR fetch upstream: $path"
    conflicts=$((conflicts + 1))
    continue
  fi

  before=$(git -C "$path" rev-parse HEAD)

  if git -C "$path" merge --no-ff -m "merge upstream/$branch" "upstream/$branch" 2>&1 | tail -5; then
    after=$(git -C "$path" rev-parse HEAD)
    if [[ "$before" == "$after" ]]; then
      echo "OK: no upstream changes"
      nochange=$((nochange + 1))
    else
      echo "OK: merged upstream changes"
      synced=$((synced + 1))
    fi
  else
    echo "CONFLICT in $path — resolve manually:"
    echo "    cd $path"
    echo "    git status"
    echo "    # resolve conflicts, then: git add . && git commit"
    conflicts=$((conflicts + 1))
  fi
done < <(python3 scripts/manifest-query.py "$MANIFEST" --fields path,url,upstream,branch)

echo
echo "Summary: $synced merged · $nochange already-current · $conflicts conflicts"
exit $conflicts
