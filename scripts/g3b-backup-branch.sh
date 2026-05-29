#!/usr/bin/env bash
# g3b-backup-branch.sh — create a local backup ref before any clone conversion.
#
# Part of the FlexNetOS additive reconciliation tooling (reversibility chain
# g3a→g3b→g3c). REFUSES (exit 20) unless g3a-can-convert.sh returns 0 for the
# target. Otherwise it creates an immutable backup ref
#   refs/local-backup/<name>-<YYYY-MM-DD>
# inside that clone's own .git, pointing at current HEAD. No network, no remote
# pushes, no working-tree mutation beyond ref creation.
#
# DO NOT run against the live repos/* clones — self-test with a throwaway temp
# git repo under /tmp.
#
# Exit codes:
#   0   backup ref created (or already existed, idempotent)
#   20  refused: g3a did not return SAFE (0)
#   2   usage / bad path
#
# Usage:
#   scripts/g3b-backup-branch.sh <repos/path>
#   scripts/g3b-backup-branch.sh -h | --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/g3b-backup-branch.sh <repos/path>

Creates refs/local-backup/<name>-<date> inside the clone's .git, but only if
g3a-can-convert.sh returns 0 (SAFE). Refuses with exit 20 otherwise.

Exit: 0 created · 20 refused (not SAFE) · 2 usage.
EOF
}

[[ $# -eq 1 ]] || { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"

if [[ ! -d "$TARGET/.git" ]] && ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "REFUSED: '$TARGET' is not a git working tree" >&2
  exit 2
fi

# Gate on g3a (read-only).
if ! "$SCRIPT_DIR/g3a-can-convert.sh" "$TARGET"; then
  echo "REFUSED: g3a-can-convert.sh did not report SAFE for $TARGET; not creating backup ref" >&2
  exit 20
fi

name="$(basename "$TARGET")"
date_tag="$(date +%Y-%m-%d)"
ref="refs/local-backup/${name}-${date_tag}"
head_sha="$(git -C "$TARGET" rev-parse HEAD)"

if git -C "$TARGET" show-ref --verify --quiet "$ref"; then
  existing="$(git -C "$TARGET" rev-parse "$ref")"
  echo "OK: backup ref $ref already exists ($existing) — idempotent, no change"
  exit 0
fi

git -C "$TARGET" update-ref "$ref" "$head_sha"
echo "OK: created $ref -> $head_sha in $TARGET/.git"
exit 0
