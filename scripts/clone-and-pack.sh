#!/usr/bin/env bash
# Step 0 of the umbrella's clone-and-research-before-fork ritual.
#
# Given an upstream GitHub URL, clone the *original* upstream into a
# gitignored work area, run repomix against it, and drop the pack and a
# short summary under data/brain-data/research/<name>/. Also seeds a stub
# research dossier at data/brain-data/research/<name>.md if one does not
# already exist.
#
# Does NOT call `gh repo fork`. Forking remains gated on the dossier
# being filled in — see memory rules `feedback-research-before-fork`,
# `feedback-fork-after-original-setup`, and `feedback-step-0-clone-and-pack`,
# and docs/fork-workflow.md.
#
# Usage:
#   scripts/clone-and-pack.sh https://github.com/<owner>/<repo> [BRANCH]
#   scripts/clone-and-pack.sh <owner>/<repo>                   [BRANCH]
#
# Env:
#   REPOMIX_VERSION   Override the version pinned in tools/bin/repomix.
#   PACK_FORMAT       xml|markdown|plain (default: xml).
#   FORCE_RECLONE     1 to rm -rf the existing work dir and re-clone.

set -euo pipefail

usage() {
  sed -n '2,22p' "$0"
  exit "${1:-2}"
}

[[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0

INPUT="$1"
BRANCH="${2:-}"
PACK_FORMAT="${PACK_FORMAT:-xml}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Normalize input: accept `owner/repo`, full HTTPS URL, or `git@host:owner/repo`.
case "$INPUT" in
  https://github.com/*|http://github.com/*)
    URL="${INPUT%/}"
    URL="${URL%.git}"
    SLUG="${URL#https://github.com/}"
    SLUG="${SLUG#http://github.com/}"
    ;;
  git@github.com:*)
    SLUG="${INPUT#git@github.com:}"
    SLUG="${SLUG%.git}"
    URL="https://github.com/${SLUG}"
    ;;
  */*)
    SLUG="$INPUT"
    URL="https://github.com/${SLUG}"
    ;;
  *)
    echo "ERROR: cannot parse '$INPUT' — expected owner/repo or a GitHub URL." >&2
    exit 2
    ;;
esac

OWNER="${SLUG%%/*}"
NAME="${SLUG##*/}"
[[ -n "$OWNER" && -n "$NAME" && "$OWNER" != "$NAME" ]] || {
  echo "ERROR: bad slug '$SLUG' — expected owner/repo." >&2; exit 2;
}

# Lowercase target dir name for stable filesystem path; preserve original
# casing in the dossier metadata.
DIR_NAME="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')"

WORK_ROOT=".attic/research-work"
WORK_DIR="${WORK_ROOT}/${DIR_NAME}"
OUT_DIR="data/brain-data/research/${DIR_NAME}"
DOSSIER="data/brain-data/research/${DIR_NAME}.md"

mkdir -p "$WORK_ROOT" "$OUT_DIR"

# --- Clone the *original* upstream, never our fork ---------------------------
if [[ -d "$WORK_DIR/.git" && "${FORCE_RECLONE:-0}" != "1" ]]; then
  echo "→ Reusing existing clone at $WORK_DIR (FORCE_RECLONE=1 to redo)"
  git -C "$WORK_DIR" fetch --quiet --depth=1 origin "${BRANCH:-HEAD}" || true
else
  [[ -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
  echo "→ Cloning $URL → $WORK_DIR"
  if [[ -n "$BRANCH" ]]; then
    git clone --depth=1 --branch "$BRANCH" --single-branch "$URL" "$WORK_DIR"
  else
    git clone --depth=1 --single-branch "$URL" "$WORK_DIR"
  fi
fi

CLONE_HEAD="$(git -C "$WORK_DIR" rev-parse HEAD)"
CLONE_HEAD_SHORT="$(git -C "$WORK_DIR" rev-parse --short HEAD)"
CLONE_BRANCH="$(git -C "$WORK_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
CLONE_LATEST="$(git -C "$WORK_DIR" log -1 --pretty='format:%h %s (%ad)' --date=short)"

# --- Pack with repomix --------------------------------------------------------
PACK_FILE="${OUT_DIR}/repomix-pack.${PACK_FORMAT}"
PACK_COMPRESSED="${OUT_DIR}/repomix-pack.compressed.${PACK_FORMAT}"
SUMMARY_FILE="${OUT_DIR}/repomix-summary.md"

echo "→ Packing (full) → $PACK_FILE"
tools/bin/repomix \
  --style "$PACK_FORMAT" \
  --output "$PACK_FILE" \
  "$WORK_DIR"

echo "→ Packing (compressed, signatures only) → $PACK_COMPRESSED"
tools/bin/repomix \
  --style "$PACK_FORMAT" \
  --compress \
  --output "$PACK_COMPRESSED" \
  "$WORK_DIR"

# --- File / language / size stats --------------------------------------------
FILE_COUNT="$(git -C "$WORK_DIR" ls-files | wc -l | tr -d ' ')"
TOTAL_BYTES="$(du -sb "$WORK_DIR" 2>/dev/null | awk '{print $1}')"
PACK_BYTES="$(wc -c < "$PACK_FILE" | tr -d ' ')"
PACK_COMPRESSED_BYTES="$(wc -c < "$PACK_COMPRESSED" | tr -d ' ')"

LANG_BREAKDOWN="$(
  git -C "$WORK_DIR" ls-files \
    | awk -F. 'NF>1 {print tolower($NF)}' \
    | sort | uniq -c | sort -rn | head -10 \
    | awk '{printf "- `%s` × %s\n", $2, $1}'
)"
TOP_DIRS="$(
  git -C "$WORK_DIR" ls-files \
    | awk -F/ 'NF>1 {print $1}' \
    | sort | uniq -c | sort -rn | head -10 \
    | awk '{printf "- `%s/` × %s files\n", $2, $1}'
)"

# --- Summary -----------------------------------------------------------------
TODAY="$(date -u +%Y-%m-%d)"
REPOMIX_VER="$(tools/bin/repomix --version 2>/dev/null | head -1 || echo unknown)"

cat > "$SUMMARY_FILE" <<EOF
# repomix summary: ${SLUG}

Generated: ${TODAY} · repomix ${REPOMIX_VER} · pack format \`${PACK_FORMAT}\`

## Source

- **Upstream:** <${URL}>
- **Clone (work, gitignored):** \`${WORK_DIR}\`
- **Branch:** \`${CLONE_BRANCH}\`
- **HEAD:** \`${CLONE_HEAD_SHORT}\` (\`${CLONE_HEAD}\`)
- **Latest commit:** ${CLONE_LATEST}

## Size

| Metric | Value |
| --- | --- |
| Tracked files | ${FILE_COUNT} |
| Working tree | ${TOTAL_BYTES} bytes (\`du -sb\`) |
| Pack (full) | ${PACK_BYTES} bytes — \`${PACK_FILE}\` |
| Pack (compressed) | ${PACK_COMPRESSED_BYTES} bytes — \`${PACK_COMPRESSED}\` |

## Top extensions

${LANG_BREAKDOWN:-_(none)_}

## Top directories

${TOP_DIRS:-_(none)_}

## Next step

Open the pack and fill out the dossier at \`${DOSSIER}\` before any
\`gh repo fork\` — see [docs/fork-workflow.md](../../../docs/fork-workflow.md)
Step 0 for the full ritual.
EOF
echo "→ Wrote $SUMMARY_FILE"

# --- Dossier stub (only if no dossier already exists) ------------------------
if [[ ! -f "$DOSSIER" ]]; then
  cat > "$DOSSIER" <<EOF
# Research: ${NAME}

**Status:** Pre-adoption research — pack generated, dossier NOT YET WRITTEN.
**Action gated by this dossier:** TODO.

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | \`${URL}\` |
| Our fork (to be created) | TBD — do NOT run \`gh repo fork\` until this dossier is filled in. |
| License | TODO |
| Default branch | \`${CLONE_BRANCH}\` |
| Latest upstream commit | ${CLONE_LATEST} |
| Local clone (work) | \`${WORK_DIR}\` (gitignored) |
| Codebase pack | \`${OUT_DIR}/repomix-pack.${PACK_FORMAT}\` |

## 2. Purpose (per README)

TODO — paraphrase or quote the upstream README.

## 3. Stack inventory

See \`${SUMMARY_FILE}\` for file counts and language breakdown. Expand with:
- Build system (npm/cargo/bazel/etc.)
- Runtime deps
- Significant subdirectories

## 4. License caveat

TODO — confirm license file, flag any non-MIT/Apache-2.0 terms.

## 5. FlexNetOS-side intent

TODO — why we want this and what role it plays in the umbrella.

## 6. Pre-adoption audit

- [ ] License clear
- [ ] Active upstream
- [ ] Build reproduces locally
- [ ] No nested submodules with restrictive licenses
- [ ] Sync cadence agreed

## 7. Adoption plan

TODO. Default is the "third-party — needs fork" case in docs/fork-workflow.md.

## 8. Sync risk

TODO.

## 9. Verification

\`\`\`bash
make verify.manifest
make submodules.sync-upstream NAME=${DIR_NAME}
\`\`\`

## 10. Open decisions for user

- [ ] Go/no-go on \`gh repo fork ${SLUG} --org FlexNetOS\`.

## 11. Decision log

(empty — fill on adoption)
EOF
  echo "→ Stub dossier at $DOSSIER (fill in before forking)"
else
  echo "→ Dossier already exists at $DOSSIER (leaving untouched)"
fi

cat <<EOF

✅ Step 0 complete for ${SLUG}.

  Pack       : ${PACK_FILE}
  Compressed : ${PACK_COMPRESSED}
  Summary    : ${SUMMARY_FILE}
  Dossier    : ${DOSSIER}

Next:
  1) Read the pack + summary, fill in the dossier.
  2) Resolve the §10 "Open decisions" gate.
  3) THEN run \`gh repo fork ${SLUG} --org FlexNetOS --clone=false\`.

Per the umbrella's research-before-fork rule, do not skip step 1.
EOF
