# `.github` — FlexNetOS umbrella

This repository is a **mega-umbrella** that plays six roles at once.
[`VISION.md`](VISION.md) is the canonical overview; the table below is the
two-line tour:

| # | Role | Lives in |
| --- | --- | --- |
| 1 | GitHub org community-health fallback | repo root + [`.github/`](.github/) |
| 2 | Mount point for ~24 git submodules | [`repos/MANIFEST.yaml`](repos/MANIFEST.yaml) + [`scripts/`](scripts/) |
| 3 | Karpathy LLM-wiki cross-project memory layer | [`wiki/`](wiki/) |
| 4 | `pass`+GPG secrets vault with paper recovery | [`secrets/`](secrets/) |
| 5 | Self-hosted GitHub Actions runner host config | [`runner/`](runner/) |
| 6 | Shared reusable-CI templates | [`.github/workflows/reusable-*.yml`](.github/workflows/) |

Each role is documented in [`VISION.md`](VISION.md). The rest of this README
focuses on role #1 (community-health inheritance) and role #6 (reusable
workflows) — the two roles other FlexNetOS repos interact with directly.

For maintainer responsibilities see [`MAINTAINERS.md`](MAINTAINERS.md); for
the release cadence and the `v1` moving-tag policy see [`RELEASING.md`](RELEASING.md);
for operational best-practices docs see [`docs/README.md`](docs/README.md).

## Community-health inheritance (role #1)

GitHub treats a User-owned (or Organization-owned) repository named `.github`
as a fallback: any community health file present here is automatically used
by every other repo under the same account that does **not** define its own.
See [GitHub's documentation on default community health files][gh-default-community-files].

## Community-health files and reusable workflows

The files GitHub picks up as defaults for every FlexNetOS repo (role #1),
plus the reusable workflows callers consume (role #6). For the other four
roles see [`VISION.md`](VISION.md).

```text
.
├── LICENSE                         MIT
├── CODE_OF_CONDUCT.md              Contributor Covenant 2.1
├── CONTRIBUTING.md                 Commit conventions, PR expectations, branch policy
├── SECURITY.md                     Private vulnerability reporting, supported versions, SLA
├── SUPPORT.md                      Where to ask for help (Issues vs Discussions vs email)
├── FUNDING.yml                     Sponsorship handles (template placeholders)
├── VISION.md                       The six-role overview
├── MAINTAINERS.md                  Ownership, contact, escalation
├── RELEASING.md                    Tagging policy, release-please loop, the `v1` moving tag
├── profile/
│   └── README.md                   Public landing page rendered at github.com/FlexNetOS
├── docs/
│   ├── README.md                   Index of operational docs
│   ├── automation.md               Scheduled workflows and how their outputs flow back
│   ├── fork-workflow.md            Fork-and-track pattern, upstream syncing, release-tag sync
│   ├── directory-layout.md         On-disk convention for forks vs upstream vs first-party
│   └── self-hosted-runner.md       Safety guidance + ephemeral-runner migration path
└── .github/
    ├── CODEOWNERS                  Reviewer routing
    ├── PULL_REQUEST_TEMPLATE.md
    ├── ISSUE_TEMPLATE/
    │   ├── config.yml              Disables blank issues, adds contact links
    │   ├── bug_report.yml          Modern YAML issue form
    │   ├── feature_request.yml
    │   └── documentation.yml
    ├── dependabot.yml              Weekly bumps for GitHub Actions used here
    └── workflows/
        ├── reusable-lint.yml       workflow_call · language-agnostic lint dispatcher
        ├── reusable-test.yml       workflow_call · test dispatcher
        ├── reusable-build.yml      workflow_call · build dispatcher
        ├── reusable-security.yml   workflow_call · CodeQL + Trivy + Gitleaks
        ├── reusable-release.yml    workflow_call · release-please / semantic-release
        ├── reusable-secrets.yml    workflow_call · pass-based secret injection
        └── reusable-submodule-bump.yml
```

## How the inheritance works (and how to override it)

For any file in this repo's root or `.github/` that GitHub recognises as a
"community health file" (`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`,
`SUPPORT.md`, `FUNDING.yml`, the issue & PR templates), GitHub will display
it on any other FlexNetOS repo that **does not** ship its own version of that
file.

To **override** for a specific repo, simply commit a local copy. The local
copy wins; the fallback in this repo is ignored for that repo only.

The `profile/README.md` is a separate mechanism: it renders as the public
landing page at <https://github.com/FlexNetOS> (above the repo grid).

## How to use the reusable workflows

These are intentionally **scaffolds** today — they ship the `workflow_call`
shape, documented inputs, least-privilege `permissions:` blocks, and a
placeholder body. Bodies will be filled in by follow-on work.

In any FlexNetOS repo, drop a thin caller into `.github/workflows/ci.yml`:

```yaml
name: ci
on: [push, pull_request]

jobs:
  lint:
    uses: FlexNetOS/.github/.github/workflows/reusable-lint.yml@main
    with:
      language: bun
    secrets: inherit

  test:
    needs: lint
    uses: FlexNetOS/.github/.github/workflows/reusable-test.yml@main
    with:
      language: bun
    secrets: inherit
```

Once the scaffolds get real bodies and we cut tagged releases, callers should
pin to a moving major tag (`@v1`) so non-breaking improvements propagate
automatically while breaking changes force a deliberate bump.

## Best-practices docs

The `docs/` directory contains write-ups that resolve recurring engineering
questions across FlexNetOS repos. Link to them from any repo's README:

- **[Fork-and-track workflow](docs/fork-workflow.md)** — the right way to
  carry local patches on a third-party repo while staying current with
  upstream releases.
- **[Directory layout for local checkouts](docs/directory-layout.md)** —
  where forks, read-only clones, and first-party projects live on disk.
- **[Self-hosted runner safety](docs/self-hosted-runner.md)** — current
  inventory, untrusted-PR risk, label discipline, and the ephemeral-runner
  migration path.

## Local development for this repo

```bash
git clone https://github.com/FlexNetOS/.github.git
cd .github

# Lint workflows (requires actionlint — see https://github.com/rhysd/actionlint)
actionlint .github/workflows/*.yml

# Lint markdown (no install needed)
bunx markdownlint-cli2 "**/*.md" "!.omc/**"
```

The `main` branch is protected: PR with one approval, linear history, no
force-push, no deletion. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
commit-message convention and branch policy.

## Maintainer

See [`MAINTAINERS.md`](MAINTAINERS.md) for ownership, contact, and
escalation. Private vulnerability reports go through [`SECURITY.md`](SECURITY.md).

[gh-default-community-files]: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
