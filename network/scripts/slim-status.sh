#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAP="$ROOT/network/service-map.yaml"

info() { printf '[slim-status] %s\n' "$*"; }
warn() { printf '[slim-status] WARN: %s\n' "$*" >&2; }

info "repo: $ROOT"
info "service map: $MAP"

if command -v slim >/dev/null 2>&1; then
  info "Slim binary: $(command -v slim)"
  slim --version 2>/dev/null || true
else
  warn "Slim binary is not installed"
fi

if [ -d "$ROOT/network/slim" ]; then
  info "Slim source path: $ROOT/network/slim"
  git -C "$ROOT/network/slim" status --short --branch 2>/dev/null || warn "Slim source is not initialized as a git checkout"
else
  warn "Slim source path missing: $ROOT/network/slim"
fi

info "declared services:"
python3 - <<'PY' "$MAP"
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
if not p.exists():
    print('  missing service-map.yaml')
    raise SystemExit(0)
text = p.read_text()
current = None
for line in text.splitlines():
    m = re.match(r'^  ([a-zA-Z0-9_-]+):\s*$', line)
    if m:
        current = m.group(1)
        continue
    if current and 'domain:' in line:
        domain = line.split(':', 1)[1].strip()
    elif current and 'target:' in line:
        target = line.split(':', 1)[1].strip()
        print(f'  {current}: {domain} -> {target}')
        current = None
PY
