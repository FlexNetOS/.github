#!/usr/bin/env bash
# Safe removal helper for a local GitHub Actions runner.
# Defaults to dry-run. It never stores or prints registration/removal tokens.
set -Eeuo pipefail

RUNNER_HOME="${RUNNER_HOME:-$HOME/_work/repos/actions-runner}"
RUNNER_ORG="${RUNNER_ORG:-FlexNetOS}"
RUNNER_REPO="${RUNNER_REPO:-}"
MODE="${RUNNER_SCOPE:-}"
TOKEN="${RUNNER_REMOVAL_TOKEN:-}"
DRY_RUN="${DRY_RUN:-1}"
CONFIRM="${CONFIRM:-0}"
REMOVE_SERVICE="${REMOVE_SERVICE:-1}"

usage() {
  cat <<'EOF'
Usage: runner/remove.sh (--org | --repo <name>) [options]

Options:
  --token TOKEN      Runner removal token. If omitted, minted via gh api.
  --home PATH        Runner install dir. Default: $HOME/_work/repos/actions-runner
  --dry-run          Print actions only. Default.
  --execute          Actually run removal commands. Requires CONFIRM=1.
  --no-service       Skip svc.sh stop/uninstall.

Examples:
  make runner.remove DRY_RUN=1 MODE=repo NAME=weftos
  CONFIRM=1 make runner.remove DRY_RUN=0 MODE=repo NAME=weftos
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) MODE="org"; shift ;;
    --repo) MODE="repo"; RUNNER_REPO="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --home) RUNNER_HOME="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --no-service) REMOVE_SERVICE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -z "$MODE" ]] && { echo "ERROR: one of --org or --repo is required" >&2; usage; exit 2; }
[[ "$MODE" == "repo" && -z "$RUNNER_REPO" ]] && { echo "ERROR: --repo requires a repo name" >&2; usage; exit 2; }

say_run() { printf '+ %q ' "$@"; printf '\n'; }
run_or_print() {
  if [[ "$DRY_RUN" == "1" ]]; then
    say_run "$@"
  else
    "$@"
  fi
}

if [[ ! -d "$RUNNER_HOME" ]]; then
  echo "WARN: runner home does not exist: $RUNNER_HOME"
  echo "Nothing to remove on this host."
  exit 0
fi

if [[ "$DRY_RUN" != "1" && "$CONFIRM" != "1" ]]; then
  echo "ERROR: refusing to mutate host without CONFIRM=1" >&2
  echo "Try: CONFIRM=1 DRY_RUN=0 runner/remove.sh ..." >&2
  exit 2
fi

cd "$RUNNER_HOME"

if [[ "$REMOVE_SERVICE" == "1" && -x ./svc.sh ]]; then
  echo "INFO: service cleanup"
  run_or_print sudo ./svc.sh stop
  run_or_print sudo ./svc.sh uninstall
fi

if [[ ! -x ./config.sh ]]; then
  echo "WARN: config.sh missing or not executable; service cleanup was the only possible action."
  exit 0
fi

if [[ -z "$TOKEN" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "INFO: dry-run: would mint short-lived GitHub runner removal token with gh api"
    TOKEN="<hidden-removal-token>"
  else
    command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI required to mint removal token (or pass --token)" >&2; exit 1; }
    if [[ "$MODE" == "org" ]]; then
      TOKEN="$(gh api -X POST "/orgs/$RUNNER_ORG/actions/runners/remove-token" --jq .token)"
    else
      TOKEN="$(gh api -X POST "/repos/$RUNNER_ORG/$RUNNER_REPO/actions/runners/remove-token" --jq .token)"
    fi
  fi
fi

echo "INFO: runner config removal"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "+ ./config.sh remove --token <hidden-removal-token>"
else
  ./config.sh remove --token "$TOKEN"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "OK: runner removal flow complete (dry-run)"
else
  echo "OK: runner removal flow complete"
fi
