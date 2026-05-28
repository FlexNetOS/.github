#!/usr/bin/env bash
# reconcile-stray-clones.sh — report-only triage of stray clones at repos/ root.
#
# Part of the FlexNetOS additive reconciliation tooling. Loops the known stray
# clones (clones sitting at repos/<name> instead of the canonical
# repos/{owned,forked,external}/<name> submodule mount), runs the READ-ONLY
# g3a-can-convert.sh predicate against each, and PRINTS a per-clone
# recommendation. DRY-RUN BY DEFAULT — it never converts or moves anything.
# An actual conversion path requires --execute AND is intentionally out of scope
# for this additive pass (it would call the g3b/g3c chain).
#
# Usage:
#   scripts/reconcile-stray-clones.sh            # report only (default)
#   scripts/reconcile-stray-clones.sh --execute  # refuses: out of scope here
#   scripts/reconcile-stray-clones.sh -h | --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"

# Known stray clones (relative to repo root). Edit here if the set changes.
STRAYS=(
  repos/ai-top-utility
  repos/fabro
  repos/paperclip
  repos/n8n
)

EXECUTE=0

usage() {
  cat <<'EOF'
Usage: scripts/reconcile-stray-clones.sh [--execute]

Report-only by default: runs g3a-can-convert.sh (READ-ONLY) on each known stray
clone and prints a recommendation. --execute is intentionally blocked in this
additive tooling pass.

Exit: 0 always in report mode.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "$EXECUTE" -eq 1 ]]; then
  echo "REFUSED: --execute is out of scope for the additive reconciliation pass." >&2
  echo "         Conversion (g3b backup -> g3c move -> submodule materialize) is a" >&2
  echo "         separate, coordinator-owned, gated step." >&2
  exit 2
fi

# Look up a MANIFEST mount whose basename matches, to flag duplicate-location.
manifest_dup_path() {
  local base="$1"
  [[ -f "$MANIFEST" ]] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  [[ -f scripts/manifest-query.py ]] || return 0
  python3 scripts/manifest-query.py "$MANIFEST" --fields path 2>/dev/null \
    | awk -v b="$base" -F/ '$NF==b {print $0}' | head -1
}

echo "FlexNetOS stray-clone reconciliation (REPORT-ONLY / dry-run)"
echo
printf '%-26s %-16s %s\n' "Clone" "g3a verdict" "Recommendation"
printf '%-26s %-16s %s\n' "--------------------------" "----------------" "------------------------------------------------"

for clone in "${STRAYS[@]}"; do
  if [[ ! -d "$clone" ]]; then
    printf '%-26s %-16s %s\n' "$clone" "ABSENT" "not present — nothing to reconcile"
    continue
  fi

  set +e
  out="$("$SCRIPT_DIR/g3a-can-convert.sh" "$clone" 2>&1)"
  code=$?
  set -e

  case "$code" in
    0)  verdict="SAFE(0)" ;;
    10) verdict="DIRTY(10)" ;;
    11) verdict="STASH(11)" ;;
    12) verdict="UNPUSHED(12)" ;;
    13) verdict="MISMATCH(13)" ;;
    *)  verdict="ERR($code)" ;;
  esac

  base="$(basename "$clone")"
  dup="$(manifest_dup_path "$base")"

  if [[ -n "$dup" && "$dup" != "$clone" ]]; then
    rec="DUPLICATE of MANIFEST mount '$dup' — de-dup (mechanical), not a fork question"
  elif [[ "$code" -eq 0 ]]; then
    rec="convertible: g3b backup -> g3c move -> materialize as submodule"
  elif [[ "$code" -eq 13 ]]; then
    rec="origin not FlexNetOS/not in MANIFEST — fork-or-leave decision (see open-questions.md)"
  else
    rec="resolve local state first ($verdict), then re-run g3a"
  fi

  printf '%-26s %-16s %s\n' "$clone" "$verdict" "$rec"
  [[ -n "$out" ]] && echo "    g3a: $out"
done

echo
echo "Mode: report-only. No conversion performed. Coordinator owns --execute path."
exit 0
