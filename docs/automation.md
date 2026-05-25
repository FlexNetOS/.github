# Automation

The full automation graph for this umbrella. What runs, when, on which
runner, and who owns turning it off.

## Triggers — one table

| Workflow | When | Runner | Owner | Output |
| --- | --- | --- | --- | --- |
| [`ci.yml`](../.github/workflows/ci.yml) | push to `main`, every PR, manual | GitHub-hosted | repo maintainer | green or red |
| [`release.yml`](../.github/workflows/release.yml) | push to `main`, manual | GitHub-hosted | repo maintainer | release-please PR; on merge, tag + release |
| [`dependency-review.yml`](../.github/workflows/dependency-review.yml) | every PR | GitHub-hosted | repo maintainer | block-or-pass on CVE severity |
| [`submodule-bump.yml`](../.github/workflows/submodule-bump.yml) | Mondays 14:00 UTC, manual | GitHub-hosted | repo maintainer | PR with bumped submodule SHAs |
| [`wiki-lint.yml`](../.github/workflows/wiki-lint.yml) | nightly 11:00 UTC, manual | GitHub-hosted | repo maintainer | issue if structural problems |
| [`secrets-rotate.yml`](../.github/workflows/secrets-rotate.yml) | Mondays 14:30 UTC, manual | **self-hosted `local`** | repo maintainer | issue if stale secrets |

## Reusable workflows (called by the above and by downstream repos)

| Workflow | Inputs | Permissions | Purpose |
| --- | --- | --- | --- |
| [`reusable-lint.yml`](../.github/workflows/reusable-lint.yml) | `language`, `paths`, `working-directory`, `fail-on-warning` | read | language-agnostic lint dispatch |
| [`reusable-test.yml`](../.github/workflows/reusable-test.yml) | `language`, `coverage` | read | test dispatch with optional coverage upload |
| [`reusable-build.yml`](../.github/workflows/reusable-build.yml) | `language`, `target`, `matrix` | read | build dispatch with cache |
| [`reusable-security.yml`](../.github/workflows/reusable-security.yml) | `language` | read + `security-events: write` | CodeQL + Trivy + Gitleaks |
| [`reusable-release.yml`](../.github/workflows/reusable-release.yml) | `language`, `release-type` | `contents: write`, `pull-requests: write`, `issues: write` | release-please for semver bumps |
| [`reusable-secrets.yml`](../.github/workflows/reusable-secrets.yml) | `keys` or `template`, `umbrella-ref` | read | inject pass secrets into `$GITHUB_ENV` (self-hosted only) |
| [`reusable-submodule-bump.yml`](../.github/workflows/reusable-submodule-bump.yml) | `group`, `manifest`, `runner`, `pr-title` | `contents: write`, `pull-requests: write` | bump submodules, open PR |

## Local automation (Makefile verbs)

```text
make help                  list everything
make bootstrap             one-time setup on a fresh clone
make verify                actionlint + markdownlint + manifest validation
make submodules.{init,add,bump,sync-upstream,status}
make wiki.{ingest,query,lint}      prints LLM prompts to run
make secrets.{unlock,rotate,mirror-bws}
make runner.{install,register,status}
make ci.local WORKFLOW=ci.yml
make clean
```

## The schedule, visualized

```text
Monday 14:00 UTC  → submodule-bump.yml         (bump submodules PR)
Monday 14:30 UTC  → secrets-rotate.yml         (issue if stale secrets)
Daily  11:00 UTC  → wiki-lint.yml              (issue if structural drift)
Every PR          → ci.yml + dependency-review.yml
Push to main      → ci.yml + release.yml
```

## How to disable a step (for incidents or maintenance)

- **A whole workflow**: GitHub UI → Actions → click the workflow → `…` →
  *Disable workflow*. Re-enable the same way. Disabling a workflow does
  NOT delete it.
- **A scheduled trigger only**: comment out the `schedule:` block in the
  workflow's YAML and commit. Manual `workflow_dispatch:` keeps working.
- **The self-hosted runner**: `sudo systemctl stop 'actions.runner.*'`
  *and* remove from GitHub UI (Org Settings → Actions → Runners → Remove).
  Either alone leaves a window.
- **A reusable workflow's downstream callers**: tag-pin from the
  caller side (`uses: …@v1.2.3`) and don't bump the pin. The workflow
  here keeps evolving; callers pinned to the old tag are unaffected.

## Permissions philosophy

Every workflow declares minimum `permissions:` explicitly. Defaults
are `contents: read`. `contents: write` only appears on `release.yml`
and `submodule-bump.yml`. `security-events: write` only on
`reusable-security.yml`. If you need more, add it in the caller's job
block, not in the reusable workflow itself.

## Action pinning

Every `uses:` action ref is either a release tag (`@v4`) **or** a SHA
(`@abc123…`). `@main` / `@master` / `@branch-name` is never accepted —
PR review catches and rejects them. Dependabot bumps the pins weekly.

## When something goes wrong

1. Check the Actions tab for the failed run's logs.
2. If the failure is in a reusable workflow, click through to the
   reusable's source — the call site links into the def.
3. If `secrets-rotate.yml` fails, it's almost always because the
   self-hosted runner is offline. Check
   `sudo systemctl status 'actions.runner.*'`.
4. If `submodule-bump.yml` opens a PR that breaks CI, drop the bump
   commit for the offending submodule(s) and re-merge — the next
   weekly run picks them up again.
