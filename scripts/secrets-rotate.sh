#!/usr/bin/env bash
# List secrets older than $ROTATE_DAYS days (default 90). Exit non-zero if
# any are found, so the scheduled workflow opens an issue.

set -euo pipefail

STORE="${PASSWORD_STORE_DIR:-./secrets/store}"
ROTATE_DAYS="${ROTATE_DAYS:-90}"

[[ -d "$STORE" ]] || { echo "ERROR: pass store not found at $STORE" >&2; exit 1; }

stale=0
found=0

# Find all .gpg files (pass entries) older than N days.
while IFS= read -r -d '' f; do
    found=$((found + 1))
    # Relative entry path = strip leading STORE/ and trailing .gpg
    rel="${f#$STORE/}"
    rel="${rel%.gpg}"
    age_days=$(( ( $(date +%s) - $(stat -c %Y "$f") ) / 86400 ))
    if [[ "$age_days" -gt "$ROTATE_DAYS" ]]; then
        echo "STALE: $rel — last touched $age_days days ago"
        stale=$((stale + 1))
    fi
done < <(find "$STORE" -type f -name '*.gpg' -print0)

echo
echo "Summary: $stale stale of $found total · rotation threshold = $ROTATE_DAYS days"
[[ "$stale" -gt 0 ]] && exit 1
exit 0
