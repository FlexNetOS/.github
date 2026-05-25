# PR-from-fork policy

The self-hosted runner has **persistent access** to the dev box, the
`pass` secrets store under `secrets/store/runner/`, and the local file
system. A malicious PR from a fork that lands on this runner could:

- exfiltrate every secret the runner can decrypt
- write arbitrary files to `$HOME`
- modify shell rc files to persist after the job
- install backdoors

We accept none of this. The rules below make it operationally
impossible for fork-PR code to reach the self-hosted runner.

## Rules

### 1. Default: fork PRs never run on `self-hosted` labels

Every `runs-on: [self-hosted, ...]` job in a reusable workflow under
`.github/workflows/` has an `if:` guard:

```yaml
jobs:
  build:
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: [self-hosted, linux, x64, local]
```

This evaluates to `false` for fork PRs (which have a different
`head.repo.full_name`) and to `true` for branch PRs from the same repo
and for direct pushes to the trunk.

### 2. Fork PRs use GitHub-hosted runners

The same workflow has a parallel job for fork PRs that runs on a
GitHub-hosted runner — same logic, isolated environment, no access to
`pass` secrets. Use a sibling job, not an `else` branch:

```yaml
jobs:
  build-internal:
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: [self-hosted, linux, x64, local]
    steps: …same body…

  build-fork:
    if: github.event.pull_request.head.repo.full_name != github.repository
    runs-on: ubuntu-latest
    steps: …same body, but with `secrets: {}` and no pass-injection…
```

### 3. Manual approval gate for fork-PR self-hosted runs (escape hatch)

If a fork PR *must* run on the self-hosted runner (e.g. testing an
ARM-specific or GPU-dependent fix), use a GitHub Environment named
`self-hosted` with a required-reviewers gate. A maintainer reviews the
fork's diff before approving the deployment.

```yaml
build-fork-trusted:
  if: github.event.pull_request.head.repo.full_name != github.repository
  needs: [reviewed]
  environment: self-hosted     # forces required-reviewer approval
  runs-on: [self-hosted, linux, x64, local]
```

The `reviewed` job is a no-op placeholder whose only purpose is to be
the deployment target. Manual approval gates run before `needs:`
resolves.

### 4. Secrets are still scoped

Even with manual approval, the fork-PR job only sees secrets it
explicitly requests via `reusable-secrets.yml`. Default deny.

### 5. Audit every fork-PR approval

When a maintainer approves a fork-PR self-hosted run, GitHub emits an
audit-log event. The weekly `runner-audit.yml` workflow summarizes
these and posts the count to an issue. Unexpected approvals get
investigated.

## What this does NOT protect against

- Internal branches authored by compromised maintainer accounts.
  Defense: branch protection, signed commits, mandatory PR review.
- Vulnerabilities in dependencies pulled at build time. Defense:
  `reusable-security.yml` (Trivy + Gitleaks + CodeQL) gates every PR.
- The runner itself being compromised. Defense: minimal install, no
  Docker socket, secret rotation, ephemeral-runner migration if blast
  radius is unacceptable.
