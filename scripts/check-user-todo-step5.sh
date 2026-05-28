#!/usr/bin/env bash
# check-user-todo-step5.sh — list MANIFEST entries by USER.TODO#5 dependency tag.
#
# Part of the FlexNetOS additive reconciliation tooling. READ-ONLY. Parses
# repos/MANIFEST.yaml and reports which entries are (or are not) tagged with a
#   # depends-on: USER.TODO#5
# marker in their block. The umbrella's MANIFEST currently has ZERO such tags,
# which is fine: --list-tagged prints nothing and exits 0; --list-untagged falls
# back to listing fork-pending entries (FlexNetOS-fork rows with an upstream),
# or, if none are detectable, all FlexNetOS-fork entries.
#
# Usage:
#   scripts/check-user-todo-step5.sh --list-tagged
#   scripts/check-user-todo-step5.sh --list-untagged
#   scripts/check-user-todo-step5.sh -h | --help
set -euo pipefail

MANIFEST="${MANIFEST:-repos/MANIFEST.yaml}"
TAG="depends-on: USER.TODO#5"

usage() {
  cat <<'EOF'
Usage: scripts/check-user-todo-step5.sh (--list-tagged | --list-untagged)

  --list-tagged     Print names of MANIFEST entries whose block contains
                    `# depends-on: USER.TODO#5`, sorted. Exit 0 (may be empty).
  --list-untagged   Print fork-pending FlexNetOS entries lacking the tag,
                    sorted. Falls back to all FlexNetOS-fork entries.

Read-only. Reads repos/MANIFEST.yaml (override with MANIFEST=path).
EOF
}

[[ $# -eq 1 ]] || { usage; exit 2; }

MODE=""
case "$1" in
  --list-tagged) MODE=tagged ;;
  --list-untagged) MODE=untagged ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
esac

[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found at $MANIFEST" >&2; exit 1; }

# Walk the manifest line-by-line, grouping by top-level `- path:` blocks.
# A block is "tagged" if any line within it contains the TAG marker.
# Name = basename of `path:`. We track url/upstream to classify fork-pending.
emit() {
  awk -v tag="$TAG" -v mode="$MODE" '
    function flush() {
      if (name != "") {
        if (mode == "tagged") {
          if (tagged) print name
        } else {
          # untagged mode: fork-pending = FlexNetOS url with an upstream, untagged
          if (!tagged && url ~ /github\.com[:\/]FlexNetOS\// && upstream != "") {
            pending[name] = 1
          }
          if (!tagged && url ~ /github\.com[:\/]FlexNetOS\//) {
            allfork[name] = 1
          }
        }
      }
      name=""; url=""; upstream=""; tagged=0
    }
    /^- path:/ {
      flush()
      v=$0; sub(/^- path:[ \t]*/, "", v); sub(/[ \t]*#.*/, "", v)
      n=split(v, a, "/"); name=a[n]
    }
    /^[ \t]+url:/ {
      v=$0; sub(/^[ \t]+url:[ \t]*/, "", v); sub(/[ \t]*#.*/, "", v); url=v
    }
    /^[ \t]+upstream:/ {
      v=$0; sub(/^[ \t]+upstream:[ \t]*/, "", v); sub(/[ \t]*#.*/, "", v); upstream=v
    }
    index($0, tag) > 0 { tagged=1 }
    END {
      flush()
      if (mode == "untagged") {
        np=0; for (k in pending) np++
        if (np > 0) { for (k in pending) print k }
        else { for (k in allfork) print k }
      }
    }
  ' "$MANIFEST" | sort -u
}

emit
exit 0
