# `runner/` — Self-hosted GitHub Actions runner

Config-as-code for the self-hosted runner that lives outside this repo
at `/home/drdave/_work/repos/actions-runner/`. Scripts here install,
register, and supervise that runner; the actual runner binaries are
left where GitHub Actions puts them.

## Current state (as of plan)

- Runner version: 2.334.0
- Install path: `/home/drdave/_work/repos/actions-runner/`
- Agent name: `local-gh-rnr-lnx` (agent id 21)
- Registered to: **repo-scope `FlexNetOS/weftos`** (the only repo it serves today)
- Service: **not installed** (`svc.sh install` never run)
- Labels: defaults (`self-hosted, linux, x64`)

## Where we're going

Multi-repo shared runner. Two paths — the choice is gated on
[TODO 3 in USER.TODO.md](../USER.TODO.md):

### Path A (recommended) — Org-scoped runner

Register the runner at the `FlexNetOS` organization scope (after TODO 3 is complete). Then:

```bash
# Run from /home/drdave/_work/repos/actions-runner/
./config.sh remove --token <REMOVAL-TOKEN-FROM-WEFTOS>

./config.sh \
  --url https://github.com/FlexNetOS \
  --token <ORG-RUNNER-REGISTRATION-TOKEN> \
  --labels self-hosted,linux,x64,local \
  --name local-gh-rnr-lnx \
  --runnergroup default \
  --unattended

sudo ./svc.sh install drdave
sudo ./svc.sh start
sudo ./svc.sh status
```

Then in GitHub UI: Organization Settings → Actions → Runner groups →
Create "local" group → restrict to selected repos.

### Path B (fallback) — Ephemeral per-job spawner

Keep FlexNetOS as a user account. Run `ephemeral-spawn.sh` as a
systemd timer that polls the GitHub API every 30s, generates a one-shot
registration token whenever a queued job is detected on any FlexNetOS
repo listed in `repos/MANIFEST.yaml`, and registers the runner
`--ephemeral` so it auto-deregisters after the job.

```bash
sudo cp runner/systemd/runner-spawn@.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now runner-spawn@drdave.timer
```

## Files

| File | Purpose |
| --- | --- |
| `install.sh` | Idempotent installer — downloads the latest stable runner, untars into `_work/repos/actions-runner-<v>/`, symlinks to `actions-runner/`. |
| `register.sh` | Multi-mode registration — `--org`, `--repo <name>`, or `--ephemeral`. Reads runner registration tokens via `gh api`. |
| `ephemeral-spawn.sh` | Path-B daemon — poll GitHub for queued jobs and spawn an ephemeral runner per detected queue entry. |
| `systemd/actions.runner.flexnetos.service.tmpl` | systemd unit for Path-A (long-running runner). |
| `systemd/runner-spawn@.service` | systemd template + timer for Path-B (ephemeral spawner). |
| `policies/runner-group.md` | Org-level allowlist + label discipline rules. |
| `policies/pr-from-fork.md` | Security: how we keep untrusted code off the runner. |

## Safety rails (must-haves regardless of path)

1. **Runner runs as non-root `drdave`** — no `sudo` available in jobs.
2. **No Docker socket mount.** Jobs that need containers use rootless
   Podman or a sibling runner that's explicitly opted-in.
3. **`_work/` on tmpfs** — secrets written to env-files in `_work/`
   evaporate on reboot and on every fresh job.
4. **Label discipline.** Only workflows that explicitly request
   `runs-on: [self-hosted, linux, x64, local]` see this runner.
   GitHub-hosted is the default everywhere else.
5. **PRs from forks are gated** — see `policies/pr-from-fork.md`. The
   default is **no fork PRs touch the self-hosted runner**.

## Operation

```bash
make runner.doctor      # read-only readiness checks
make runner.install     # dry-run install plan; add CONFIRM=1 DRY_RUN=0 to apply
make runner.register    # dry-run registration; add CONFIRM=1 DRY_RUN=0 to apply
make runner.status      # systemd status for persistent and ephemeral units
make runner.remove      # dry-run removal; add CONFIRM=1 DRY_RUN=0 to apply
```

## Safety defaults

Runner lifecycle commands default to dry-run/read-only behavior. Host or
GitHub mutations require both `DRY_RUN=0` and `CONFIRM=1`, for example:

```bash
make runner.install DRY_RUN=0 CONFIRM=1
make runner.register MODE=repo NAME=weftos DRY_RUN=0 CONFIRM=1
make runner.remove MODE=repo NAME=weftos DRY_RUN=0 CONFIRM=1
```

Copy `runner/.env.example` to a private local file before activating a host.
Registration/removal tokens are short-lived and must never be committed.

## Troubleshooting

- **`./config.sh` says "already configured"** — run `./config.sh remove`
  first, or pass `--replace`.
- **systemd unit fails with "user not found"** — `svc.sh install <user>`
  embeds the username; verify with
  `cat /etc/systemd/system/actions.runner.*.service | grep User=`.
- **Runner picks jobs but they fail with "no Docker daemon"** — that's
  intentional (see safety rail #2). Add `services:` containers using
  GitHub-hosted runners, or opt in to rootless Podman per-job.
- **The runner shows "Connected" but no jobs flow** — verify the
  workflow's `runs-on:` includes all the labels you set (`self-hosted`
  AND `linux` AND `x64` AND `local`).
