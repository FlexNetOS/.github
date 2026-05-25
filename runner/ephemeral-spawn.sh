#!/usr/bin/env bash
# Path-B ephemeral runner spawner.
# Polls every FlexNetOS repo listed in repos/MANIFEST.yaml for queued jobs;
# when found, registers an ephemeral runner against that repo and runs once.
# After the job finishes (or fails), the runner auto-deregisters.
#
# Run via systemd timer `runner-spawn@<user>.timer` (see systemd/).
# Single-shot: spawns at most ONE ephemeral runner per invocation.

set -euo pipefail

RUNNER_HOME="${RUNNER_HOME:-$HOME/_work/repos/actions-runner}"
REPO_ROOT="${REPO_ROOT:-$HOME/_work/repos/my-github}"
MANIFEST="${MANIFEST:-$REPO_ROOT/repos/MANIFEST.yaml}"
LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,local}"
LOCK_FILE="${LOCK_FILE:-/tmp/runner-spawn.lock}"

# Avoid concurrent spawns
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "INFO: another spawn in progress — exiting"
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI required" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "ERROR: yq required" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found at $MANIFEST" >&2; exit 1; }

# Extract FlexNetOS repo names from MANIFEST (any path under owned/ or forked/)
mapfile -t repos < <(yq '.[].url' "$MANIFEST" \
  | grep -oE 'https://github\.com/FlexNetOS/[^"]+' \
  | sed 's|.*/||' | sort -u)

[[ ${#repos[@]} -eq 0 ]] && { echo "INFO: no FlexNetOS repos in manifest"; exit 0; }

# Find the first repo with a queued job
target_repo=""
for repo in "${repos[@]}"; do
  queued=$(gh api "/repos/FlexNetOS/$repo/actions/runs?status=queued&per_page=1" \
           --jq '.total_count // 0' 2>/dev/null || echo 0)
  if [[ "$queued" -gt 0 ]]; then
    target_repo="$repo"
    echo "INFO: queued job(s) detected in FlexNetOS/$repo (count=$queued)"
    break
  fi
done

if [[ -z "$target_repo" ]]; then
  exit 0   # nothing to do — exit quietly
fi

# Spawn an ephemeral runner for the target repo
NAME="ephemeral-$(hostname)-$$-$(date +%s)"
TOKEN=$(gh api -X POST "/repos/FlexNetOS/$target_repo/actions/runners/registration-token" --jq .token)

cd "$RUNNER_HOME"

echo "INFO: registering ephemeral runner $NAME → FlexNetOS/$target_repo"
./config.sh \
  --url "https://github.com/FlexNetOS/$target_repo" \
  --token "$TOKEN" \
  --labels "$LABELS" \
  --name "$NAME" \
  --ephemeral \
  --unattended \
  --replace

# `./run.sh` blocks until the runner picks up a job and finishes (then exits
# because of --ephemeral). When this script returns, the runner is gone.
echo "INFO: running one job…"
./run.sh
echo "OK: ephemeral runner exited cleanly"
