#!/usr/bin/env bash
# Idempotent install of the GitHub Actions self-hosted runner.
# Downloads the latest stable release, unpacks into the canonical
# install path, runs ./bin/installdependencies.sh.
#
# Does NOT register the runner — that's `register.sh`'s job.
# Does NOT install as a service — `register.sh` does that after registration.

set -euo pipefail

RUNNER_HOME="${RUNNER_HOME:-$HOME/_work/repos/actions-runner}"
VERSION="${RUNNER_VERSION:-}"
ARCH="${RUNNER_ARCH:-x64}"
DRY_RUN="${DRY_RUN:-1}"
CONFIRM="${CONFIRM:-0}"

usage() {
  cat <<'EOF'
Usage: runner/install.sh [--version X.Y.Z] [--home /path] [--dry-run|--execute]

  --version X.Y.Z   Runner version (default: latest stable from GitHub API)
  --home PATH       Install path (default: $HOME/_work/repos/actions-runner)
  --dry-run         Print intended actions only (default)
  --execute         Download/extract/install dependencies; requires CONFIRM=1

Idempotent — safe to re-run. Bumps the version in place if --version differs
from what's installed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --home)    RUNNER_HOME="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# Resolve latest version if not specified
if [[ -z "$VERSION" ]]; then
  command -v curl >/dev/null 2>&1 || { echo "ERROR: curl required" >&2; exit 1; }
  VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
            | grep -oE '"tag_name":\s*"v[0-9.]+"' \
            | grep -oE '[0-9.]+' | head -1)
  [[ -z "$VERSION" ]] && { echo "ERROR: could not resolve latest version" >&2; exit 1; }
  echo "INFO: using latest stable version $VERSION"
fi

ARCHIVE="actions-runner-linux-${ARCH}-${VERSION}.tar.gz"
URL="https://github.com/actions/runner/releases/download/v${VERSION}/${ARCHIVE}"

if [[ "$DRY_RUN" != "1" && "$CONFIRM" != "1" ]]; then
  echo "ERROR: refusing to mutate host without CONFIRM=1" >&2
  echo "Try: CONFIRM=1 DRY_RUN=0 runner/install.sh --execute ..." >&2
  exit 2
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY-RUN: would install/upgrade GitHub Actions runner"
  echo "  version: $VERSION"
  echo "  arch: $ARCH"
  echo "  home: $RUNNER_HOME"
  echo "  url: $URL"
  echo "No files were changed. Re-run with CONFIRM=1 DRY_RUN=0 --execute to apply."
  exit 0
fi

# Skip if already installed at the requested version
if [[ -f "$RUNNER_HOME/config.sh" ]]; then
  if [[ -f "$RUNNER_HOME/bin/Runner.Listener" ]]; then
    installed_version=$("$RUNNER_HOME/bin/Runner.Listener" --version 2>/dev/null || true)
    if [[ "$installed_version" == "$VERSION" ]]; then
      echo "OK: runner $VERSION already installed at $RUNNER_HOME"
      exit 0
    fi
    echo "INFO: upgrading runner $installed_version → $VERSION"
  fi
fi

mkdir -p "$RUNNER_HOME"
cd "$RUNNER_HOME"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "INFO: downloading $URL"
  curl -fsSL -o "$ARCHIVE" "$URL"
fi

echo "INFO: extracting $ARCHIVE"
tar xzf "$ARCHIVE"

# Install OS dependencies the runner needs
if [[ -x ./bin/installdependencies.sh ]]; then
  echo "INFO: installing runner dependencies (may prompt for sudo)"
  sudo ./bin/installdependencies.sh || {
    echo "WARN: dependency install failed (continuing) — see ./bin/installdependencies.sh manually"
  }
fi

echo
echo "OK: runner $VERSION installed at $RUNNER_HOME"
echo "Next: register with runner/register.sh"
