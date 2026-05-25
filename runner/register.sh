#!/usr/bin/env bash
# Register the installed runner with GitHub.
# Modes:
#   --org              Org-scoped (FlexNetOS must be a GitHub Organization)
#   --repo <name>      Single-repo scope: FlexNetOS/<name>
#   --ephemeral --repo <name>   One-shot ephemeral runner (auto-deregister)
#
# Uses `gh api` to mint the registration token if no --token is provided.
# Requires gh CLI authenticated as a user with appropriate scope.

set -euo pipefail

RUNNER_HOME="${RUNNER_HOME:-$HOME/_work/repos/actions-runner}"
MODE=""
REPO=""
TOKEN=""
NAME="${RUNNER_NAME:-$(hostname)-gh-rnr}"
LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,local}"
EPHEMERAL=0
REPLACE=0
INSTALL_SERVICE=1
RUNNER_USER="${RUNNER_USER:-$USER}"

usage() {
  cat <<'EOF'
Usage: runner/register.sh --org | --repo <name> [options]

Modes:
  --org              Register at FlexNetOS organization scope (D5 path A)
  --repo <name>      Register against FlexNetOS/<name>
  --ephemeral        Auto-deregister after one job (combine with --repo)

Options:
  --token TOKEN      Registration token (default: minted via gh api)
  --name NAME        Runner name (default: <hostname>-gh-rnr)
  --labels CSV       Comma-separated labels (default: self-hosted,linux,x64,local)
  --replace          Pass --replace to config.sh (overwrite existing)
  --no-service       Don't install systemd service after registration
  --user USER        User to run the service as (default: $USER)
  --home PATH        Runner install dir (default: $HOME/_work/repos/actions-runner)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)         MODE="org"; shift ;;
    --repo)        MODE="repo"; REPO="$2"; shift 2 ;;
    --ephemeral)   EPHEMERAL=1; shift ;;
    --token)       TOKEN="$2"; shift 2 ;;
    --name)        NAME="$2"; shift 2 ;;
    --labels)      LABELS="$2"; shift 2 ;;
    --replace)     REPLACE=1; shift ;;
    --no-service)  INSTALL_SERVICE=0; shift ;;
    --user)        RUNNER_USER="$2"; shift 2 ;;
    --home)        RUNNER_HOME="$2"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -z "$MODE" ]] && { echo "ERROR: one of --org or --repo is required" >&2; usage; exit 2; }
[[ "$EPHEMERAL" -eq 1 && "$MODE" != "repo" ]] && { echo "ERROR: --ephemeral requires --repo (GitHub user accounts can't do org-scoped ephemerals)" >&2; exit 2; }
[[ ! -x "$RUNNER_HOME/config.sh" ]] && { echo "ERROR: runner not installed at $RUNNER_HOME — run install.sh first" >&2; exit 1; }

# Mint registration token if not supplied
if [[ -z "$TOKEN" ]]; then
  command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI required to mint registration token (or pass --token)" >&2; exit 1; }
  if [[ "$MODE" == "org" ]]; then
    TOKEN=$(gh api -X POST /orgs/FlexNetOS/actions/runners/registration-token --jq .token)
    URL="https://github.com/FlexNetOS"
  else
    TOKEN=$(gh api -X POST "/repos/FlexNetOS/$REPO/actions/runners/registration-token" --jq .token)
    URL="https://github.com/FlexNetOS/$REPO"
  fi
fi

# Build config.sh args
args=(--url "$URL" --token "$TOKEN" --labels "$LABELS" --name "$NAME" --unattended)
[[ "$REPLACE" -eq 1 ]] && args+=(--replace)
[[ "$EPHEMERAL" -eq 1 ]] && args+=(--ephemeral)

cd "$RUNNER_HOME"

echo "INFO: registering runner ($MODE${EPHEMERAL:+ ephemeral}) → $URL"
./config.sh "${args[@]}"

# Ephemeral runners run once and exit; the spawner handles them.
if [[ "$EPHEMERAL" -eq 1 ]]; then
  echo "OK: ephemeral runner registered. Run with: ./run.sh"
  exit 0
fi

# Install systemd service unless told not to
if [[ "$INSTALL_SERVICE" -eq 1 ]]; then
  echo "INFO: installing as systemd service (user: $RUNNER_USER)"
  sudo ./svc.sh install "$RUNNER_USER"
  sudo ./svc.sh start
  sudo ./svc.sh status
fi

echo
echo "OK: runner registered and running"
