# Runner group policy

> Applies once `FlexNetOS` is a GitHub Organization and the runner is
> registered at the org scope (Path A in `runner/README.md`).

## Group: `local`

A single org-level runner group named `local` containing the
self-hosted runner `local-gh-rnr-lnx`.

### Repo access

**Restricted, allowlist.** Not `All repositories`.

Default allowlist:

- `FlexNetOS/.github` — for testing reusable workflows
- `FlexNetOS/weftos` — the historical user
- `FlexNetOS/ruvector` — needs runtime for vector-DB benchmarks
- `FlexNetOS/ruOS` — needs runtime for .deb builds

Adding a repo to the allowlist requires:

1. A PR against this file documenting the addition and the reason.
2. Maintainer review.
3. The Settings change in the GitHub UI.

### Workflow access

**Restricted, allowlist.** Public workflows from any repo (e.g.
trusted reusable workflows from `actions/`) are NOT permitted to run
on this group. Only workflows defined inside an allowlisted repo can
schedule jobs here.

## Label discipline

The runner advertises:

```text
self-hosted, linux, x64, local
```

Workflows that want this runner MUST request all four labels:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64, local]
```

Specifying only `self-hosted` is rejected — be explicit. This protects
against accidentally routing a job to the wrong runner once we have
more than one.

## Concurrency

The runner serves jobs **serially** (one at a time). For parallel
workloads, prefer GitHub-hosted runners.

If a workflow needs the self-hosted runner *and* matrix parallelism,
split the matrix legs so only one leg runs here and the rest run on
GitHub-hosted.

## Audit

- Every job's start/end is logged by the systemd journal — view with:
  `journalctl -u 'actions.runner.*'`
- `runner/audit.log` (gitignored) gets a weekly summary appended by a
  scheduled workflow (`runner-audit.yml`).
- Any allowlist or group-membership change emits a GitHub audit-log
  event in the org settings.

## Disabling fast

If the runner needs to be taken offline immediately (e.g. suspected
compromise):

```bash
# On the runner host
sudo systemctl stop 'actions.runner.*'
# In GitHub UI: Org Settings → Actions → Runners → remove the runner
```

Removing the runner from GitHub *and* stopping it locally is the only
fully-effective shutdown. Either alone leaves a window.
