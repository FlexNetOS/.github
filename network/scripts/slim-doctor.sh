#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAP="$ROOT/network/service-map.yaml"
SLIM_SRC="$ROOT/network/slim"

info() { printf '[slim-doctor] %s\n' "$*"; }
warn() { printf '[slim-doctor] WARN: %s\n' "$*" >&2; }
fail() { printf '[slim-doctor] FAIL: %s\n' "$*" >&2; exit 1; }

info "repo: $ROOT"

if [ ! -f "$MAP" ]; then
  fail "missing service map: $MAP"
fi
info "service map present: $MAP"

if [ ! -d "$SLIM_SRC/.git" ] && [ ! -f "$SLIM_SRC/.git" ]; then
  warn "Slim submodule is not initialized at $SLIM_SRC"
  warn "run: git submodule update --init --depth 1 network/slim"
else
  info "Slim source present: $SLIM_SRC"
  git -C "$SLIM_SRC" rev-parse --short HEAD >/dev/null 2>&1 \
    && info "Slim source revision: $(git -C "$SLIM_SRC" rev-parse --short HEAD)"
fi

if command -v slim >/dev/null 2>&1; then
  info "Slim binary: $(command -v slim)"
  slim --version 2>/dev/null || warn "Slim binary exists but 'slim --version' failed"
else
  warn "Slim binary is not installed yet; this is expected before runtime rollout"
fi

for cmd in curl git python3; do
  if command -v "$cmd" >/dev/null 2>&1; then
    info "found $cmd: $(command -v "$cmd")"
  else
    warn "missing command: $cmd"
  fi
done

info "checking first rollout health target: http://127.0.0.1:3090/api/connection-status"
if curl -fsS --max-time 2 http://127.0.0.1:3090/api/connection-status >/dev/null 2>&1; then
  info "workspace health endpoint responded"
else
  warn "workspace health endpoint did not respond; start Hermes Workspace before testing workspace.test"
fi

info "doctor complete"
