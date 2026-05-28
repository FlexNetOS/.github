#!/usr/bin/env bash
# g3a-can-convert.sh — READ-ONLY safety predicate for clone→submodule conversion.
#
# Part of the FlexNetOS additive reconciliation tooling (reversibility chain
# g3a→g3b→g3c). This script performs ZERO writes and no network beyond local
# `git remote get-url`. It decides whether a clone at <repos/path> is SAFE to
# convert/move, by checking the working tree, stash, unpushed commits, and that
# origin matches the MANIFEST-declared url for that path.
#
# Exit codes (EXACT):
#   0   SAFE             clean tree AND origin matches MANIFEST url
#                        (or, if path not in MANIFEST, origin under FlexNetOS)
#   10  dirty            `git status --porcelain` non-empty
#   11  stash present    `git stash list` non-empty
#   12  unpushed         `git cherry @{upstream}` non-empty
#   13  UNSAFE-MISMATCH  origin not under FlexNetOS / mismatches MANIFEST url
#   2   usage / bad path
#
# Usage:
#   scripts/g3a-can-convert.sh <repos/path>
#   scripts/g3a-can-convert.sh -h | --help
set -euo pipefail

MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"

usage() {
  cat <<'EOF'
Usage: scripts/g3a-can-convert.sh <repos/path>

READ-ONLY predicate. Prints one of:
  SAFE: <reason>
  UNSAFE: <reason>           (dirty / stash / unpushed; exit 10/11/12)
  UNSAFE-MISMATCH: <reason>  (origin not under FlexNetOS / != MANIFEST; exit 13)

Exit: 0 SAFE · 10 dirty · 11 stash · 12 unpushed · 13 mismatch · 2 usage.
EOF
}

[[ $# -eq 1 ]] || { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"

if [[ ! -d "$TARGET/.git" ]] && ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "UNSAFE: '$TARGET' is not a git working tree" >&2
  exit 2
fi

# --- origin vs MANIFEST ------------------------------------------------------
origin="$(git -C "$TARGET" remote get-url origin 2>/dev/null || true)"
if [[ -z "$origin" ]]; then
  echo "UNSAFE-MISMATCH: $TARGET has no 'origin' remote"
  exit 13
fi

norm() { # strip trailing .git and trailing slash for comparison
  local u="$1"; u="${u%.git}"; u="${u%/}"; printf '%s' "$u"
}

manifest_url=""
if [[ -f "$MANIFEST" ]] && command -v python3 >/dev/null 2>&1 \
   && [[ -f scripts/manifest-query.py ]]; then
  # Exact path match against MANIFEST `url:` field.
  while IFS=$'\t' read -r m_path m_url; do
    if [[ "$m_path" == "$TARGET" ]]; then manifest_url="$m_url"; break; fi
  done < <(python3 scripts/manifest-query.py "$MANIFEST" --fields path,url 2>/dev/null || true)
fi

if [[ -n "$manifest_url" ]]; then
  if [[ "$(norm "$origin")" != "$(norm "$manifest_url")" ]]; then
    echo "UNSAFE-MISMATCH: origin '$origin' != MANIFEST url '$manifest_url' for $TARGET"
    exit 13
  fi
else
  # Not declared in MANIFEST: only origins under github.com/FlexNetOS/ are SAFE.
  if [[ "$(norm "$origin")" != *github.com/FlexNetOS/* ]] \
     && [[ "$(norm "$origin")" != *github.com:FlexNetOS/* ]]; then
    echo "UNSAFE-MISMATCH: origin '$origin' not under github.com/FlexNetOS/ and $TARGET not in MANIFEST"
    exit 13
  fi
fi

# --- working tree ------------------------------------------------------------
if [[ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]]; then
  echo "UNSAFE: working tree dirty at $TARGET"
  exit 10
fi

# --- stash -------------------------------------------------------------------
if [[ -n "$(git -C "$TARGET" stash list 2>/dev/null)" ]]; then
  echo "UNSAFE: stash entries present at $TARGET"
  exit 11
fi

# --- unpushed commits --------------------------------------------------------
# Only meaningful if an upstream is configured; if none, treat as no-unpushed.
if git -C "$TARGET" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
  if [[ -n "$(git -C "$TARGET" cherry '@{upstream}' 2>/dev/null)" ]]; then
    echo "UNSAFE: unpushed commits at $TARGET (git cherry @{upstream} non-empty)"
    exit 12
  fi
fi

echo "SAFE: $TARGET clean, origin '$origin' matches ${manifest_url:+MANIFEST}${manifest_url:-FlexNetOS}"
exit 0
