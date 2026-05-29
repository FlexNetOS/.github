#!/usr/bin/env bash
# g3c-stash-and-move.sh — relocate a converted clone to the backups quarantine.
#
# Part of the FlexNetOS additive reconciliation tooling (reversibility chain
# g3a→g3b→g3c). REFUSES (exit 30) unless a refs/local-backup/* ref exists in the
# clone (i.e. g3b ran). Otherwise it moves the directory to
#   .omc/backups/repos-<name>-<date>/
# and appends a line to .omc/backups/MOVE.log. This is the last, destructive-ish
# step (a move, fully reversible from the quarantine) and exists so submodule
# materialization can take over the original mount point.
#
# DO NOT run against the live repos/* clones — self-test with a throwaway temp
# git repo under /tmp.
#
# Exit codes:
#   0   moved successfully
#   30  refused: no local-backup ref present (g3b not run)
#   2   usage / bad path
#   3   destination already exists (refuse to clobber)
#
# Usage:
#   scripts/g3c-stash-and-move.sh <repos/path>
#   scripts/g3c-stash-and-move.sh -h | --help
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/g3c-stash-and-move.sh <repos/path>

Moves the clone to .omc/backups/repos-<name>-<date>/ and logs to
.omc/backups/MOVE.log, but only if a refs/local-backup/* ref exists (g3b ran).
Refuses with exit 30 otherwise.

Exit: 0 moved · 30 refused (no backup ref) · 3 dest exists · 2 usage.
EOF
}

[[ $# -eq 1 ]] || { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"

if [[ ! -d "$TARGET/.git" ]] && ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "REFUSED: '$TARGET' is not a git working tree" >&2
  exit 2
fi

# Require a local-backup ref (proof g3b ran).
backup_refs="$(git -C "$TARGET" for-each-ref --format='%(refname)' 'refs/local-backup/' 2>/dev/null || true)"
if [[ -z "$backup_refs" ]]; then
  echo "REFUSED: no refs/local-backup/* ref in $TARGET; run g3b-backup-branch.sh first" >&2
  exit 30
fi

# Determine repo root for placing .omc/backups (works from any cwd).
if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then :; else root="$PWD"; fi

name="$(basename "$TARGET")"
date_tag="$(date +%Y-%m-%d)"
dest_dir="$root/.omc/backups"
dest="$dest_dir/repos-${name}-${date_tag}"
log="$dest_dir/MOVE.log"

mkdir -p "$dest_dir"

if [[ -e "$dest" ]]; then
  echo "REFUSED: destination already exists: $dest" >&2
  exit 3
fi

mv "$TARGET" "$dest"
printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TARGET" "$dest" "backup_refs=$(echo "$backup_refs" | tr '\n' ',')" >>"$log"
echo "OK: moved $TARGET -> $dest (logged to $log)"
exit 0
