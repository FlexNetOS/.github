#!/usr/bin/env bash
# Expand `pass:<entry>` placeholders in an env-template and emit `export …`
# lines on stdout. Used by reusable-secrets.yml and as a standalone
# helper outside direnv.
#
# Usage:
#   scripts/secrets-inject.sh secrets/envs/ci.env.tmpl
#   eval "$(scripts/secrets-inject.sh secrets/envs/dev.env.tmpl)"
#
# Lines emitted:
#   export VAR='value'           (single-quoted, ' escaped)
#
# For GitHub Actions: redirect into $GITHUB_ENV after stripping `export `.

set -euo pipefail

TMPL="${1:-}"
[[ -z "$TMPL" ]] && { echo "Usage: $0 <env-template>" >&2; exit 2; }
[[ -f "$TMPL" ]] || { echo "ERROR: $TMPL not found" >&2; exit 1; }

command -v pass >/dev/null 2>&1 || { echo "ERROR: pass not installed" >&2; exit 1; }

while IFS= read -r line; do
    case "$line" in
        ''|'#'*) continue ;;
        *=pass:*)
            k="${line%%=*}"
            entry="${line#*=pass:}"
            if val=$(pass show "$entry" 2>/dev/null); then
                # single-quote escape: ' → '\''
                esc=${val//\'/\'\\\'\'}
                echo "export $k='$esc'"
            else
                echo "ERROR: pass entry '$entry' not found (needed for \$$k)" >&2
                exit 1
            fi
            ;;
        *=*)
            k="${line%%=*}"
            v="${line#*=}"
            esc=${v//\'/\'\\\'\'}
            echo "export $k='$esc'"
            ;;
    esac
done < "$TMPL"
