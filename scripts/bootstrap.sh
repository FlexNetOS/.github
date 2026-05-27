#!/usr/bin/env bash
# Idempotent bootstrap for a fresh dev box (or a fresh clone).
# Verifies host toolchain, initializes submodules, unlocks secrets,
# optionally installs the self-hosted runner.
#
# Safe to re-run.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

WITH_RUNNER=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [--with-runner] [-y|--yes]

  --with-runner   Also install the self-hosted runner (runner/install.sh)
  -y, --yes       Assume "yes" to all prompts; do everything possible non-interactively
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-runner) WITH_RUNNER=1; shift ;;
    -y|--yes)      ASSUME_YES=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$*"; }

# -----------------------------------------------------------------------------
say "Toolchain check"
# -----------------------------------------------------------------------------
required=(git bash)
optional=(mise gh gpg pass direnv age tools/bin/actionlint tools/bin/gitleaks tools/bin/trivy jq)

missing_required=()
for t in "${required[@]}"; do
  if command -v "$t" >/dev/null 2>&1; then
    ok "$t — $(command -v "$t")"
  else
    missing_required+=("$t")
    warn "$t — MISSING (required)"
  fi
done

missing_optional=()
for t in "${optional[@]}"; do
  if [[ -x "$t" ]]; then
    ok "$t — repo-local wrapper"
  elif command -v "$t" >/dev/null 2>&1; then
    ok "$t — $(command -v "$t")"
  else
    missing_optional+=("$t")
    warn "$t — missing (recommended)"
  fi
done

if [[ ${#missing_required[@]} -gt 0 ]]; then
  echo "ERROR: install required tools first: ${missing_required[*]}"
  exit 1
fi

if [[ ${#missing_optional[@]} -gt 0 ]]; then
  warn "Recommended tools missing: ${missing_optional[*]}"
  warn "Install hints:"
  warn "  apt-get install -y git gpg pass direnv age jq"
  warn "  gh auth login                        # gh CLI"
  warn "  python3 scripts/toolchain.py ensure  # pinned repo-local tool binaries"
fi

# -----------------------------------------------------------------------------
say "Submodules"
# -----------------------------------------------------------------------------
if [[ -f .gitmodules ]]; then
  ok "found .gitmodules — initializing"
  git submodule update --init --recursive --depth 1 || warn "submodule init had errors (check network + access)"
else
  warn "no .gitmodules yet — run \`make submodules.add\` once MANIFEST is approved"
fi

# -----------------------------------------------------------------------------
say "Secrets"
# -----------------------------------------------------------------------------
if [[ -d secrets/store ]]; then
  ok "secrets/store/ present"
else
  warn "secrets/store/ missing"
fi

if [[ -s secrets/.gpg-id && "$(head -c 16 secrets/.gpg-id)" != "# Add the GPG ke" ]]; then
  ok "secrets/.gpg-id configured"
else
  warn "secrets/.gpg-id is the placeholder — see secrets/README.md to set up your GPG key"
fi

if command -v direnv >/dev/null 2>&1 && [[ -f .envrc ]]; then
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    direnv allow . && ok "direnv allowed"
  else
    read -rp "  Run \`direnv allow\`? [y/N] " a
    [[ "$a" =~ ^[Yy]$ ]] && direnv allow . && ok "direnv allowed"
  fi
fi

# -----------------------------------------------------------------------------
if [[ "$WITH_RUNNER" -eq 1 ]]; then
  say "Self-hosted runner"
  if [[ -x runner/install.sh ]]; then
    bash runner/install.sh
  else
    warn "runner/install.sh missing or not executable"
  fi
fi

# -----------------------------------------------------------------------------
say "Done"
# -----------------------------------------------------------------------------
cat <<EOF
Next steps:
  1. If submodule init reported errors, check your gh/git auth: \`gh auth status\`.
  2. If secrets/.gpg-id is still a placeholder, follow secrets/README.md
     to set up your GPG key and re-init the pass store.
  3. To use the self-hosted runner, run \`make runner.register MODE=org\`
     (after FlexNetOS becomes an Organization — see TODO 3 in USER.TODO.md).
  4. Run \`make verify\` to lint everything.
EOF
