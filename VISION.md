# Vision — what this repo is

`FlexNetOS/.github` is a **mega-umbrella**. It plays six distinct roles
at the same time, deliberately bundled so a single repo + a single
self-hosted runner can serve every other FlexNetOS repository.

A new contributor or a returning maintainer should read this page first.
The rest of the repo makes more sense once you understand the six jobs.

## The six roles

### 1. GitHub org community-health fallback

GitHub treats a repository named `.github` under a user or organization
as the source of **default community health files** for every other repo
in that account. Anything in this repo's root or `.github/` directory —
`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`,
`FUNDING.yml`, the issue/PR templates — is automatically displayed on
any FlexNetOS repo that does not ship its own copy. Overrides are local:
commit the file in the downstream repo and the local version wins for
that repo only.

This is the role most users notice. The other five sit underneath.

### 2. Mount point for ~24 git submodules

[`repos/MANIFEST.yaml`](repos/MANIFEST.yaml) is the single source of
truth for every external codebase the FlexNetOS world depends on. The
manifest covers three categories — **owned** (first-party FlexNetOS
repos), **forked** (third-party upstreams we patch and track), and
**external** (read-only upstream clones we pull in for reference).

[`scripts/submodule-add-all.sh`](scripts/submodule-add-all.sh) reads the
manifest and runs `git submodule add` for any entry not yet present.
Bumps and upstream syncs are automated by
[`scripts/submodule-bump.sh`](scripts/submodule-bump.sh) and
[`scripts/submodule-sync-upstream.sh`](scripts/submodule-sync-upstream.sh).
The Monday-morning workflow [`submodule-bump.yml`](.github/workflows/submodule-bump.yml)
runs the bumper on a schedule and opens a PR if any submodule moved.

Read [`docs/directory-layout.md`](docs/directory-layout.md) and
[`docs/fork-workflow.md`](docs/fork-workflow.md) before adding or
modifying entries.

### 3. Karpathy LLM-wiki — cross-project memory layer

The [`wiki/`](wiki/) tree is a persistent, compiled knowledge base in
the Karpathy LLM-wiki style. It is the memory layer for everything that
happens under this umbrella: when a paper changes how we evaluate
agents, when a new vector-DB technique lands in `ruvector`, when a
recurring engineering decision is settled — the synthesis lives here
and stays.

Mission, scope, and out-of-scope are documented in
[`wiki/purpose.md`](wiki/purpose.md). Schema and conventions are in
[`wiki/schema.md`](wiki/schema.md). The wiki is meant to be query-able
and lint-able; [`wiki-lint.yml`](.github/workflows/wiki-lint.yml) runs
nightly to catch broken links and orphans.

### 4. `pass` + GPG secrets vault with paper recovery

[`secrets/`](secrets/) is a `pass`-managed store keyed by GPG. Two
keys: a personal key on the dev box and a separate runner key, never
reused. Recovery is paper-backed via age — see
[`secrets/recovery/README.md`](secrets/recovery/README.md) for the
generation and storage protocol.

Injection into running processes is handled by
[`scripts/secrets-inject.sh`](scripts/secrets-inject.sh) (via direnv),
rotation by [`scripts/secrets-rotate.sh`](scripts/secrets-rotate.sh)
and the scheduled [`secrets-rotate.yml`](.github/workflows/secrets-rotate.yml)
workflow, and a one-way mirror to Bitwarden Secrets Manager by
[`scripts/secrets-mirror-to-bws.sh`](scripts/secrets-mirror-to-bws.sh)
for cloud accessibility.

### 5. Self-hosted GitHub Actions runner host config

[`runner/`](runner/) is the on-host configuration for the FlexNetOS
self-hosted runner: install script, registration helper, ephemeral-spawn
wrapper, and systemd units. Policy lives next to the code in
[`runner/policies/`](runner/policies/) — the runner-group allowlist and
the PR-from-fork policy that gates untrusted code from ever reaching the
runner.

Safety guidance and the migration path to ephemeral runners is in
[`docs/self-hosted-runner.md`](docs/self-hosted-runner.md). Read it
before changing anything in this directory.

### 6. Shared reusable-CI templates

[`.github/workflows/reusable-*.yml`](.github/workflows/) are
language-agnostic, `workflow_call`-shaped CI templates used by every
downstream FlexNetOS repo. They ship with documented inputs,
least-privilege `permissions:` blocks, and consistent matrix shapes so
adding a new repo is a three-line caller, not a hundred-line copy-paste.

```yaml
jobs:
  lint:
    uses: FlexNetOS/.github/.github/workflows/reusable-lint.yml@v1
    with:
      language: bun
    secrets: inherit
```

Downstream repos should pin to the moving major tag (`@v1`) once it
exists. Today the workflows are scaffolds; see [`RELEASING.md`](RELEASING.md)
for the path to v1.

## Why one repo instead of six

Each role *could* live in its own repository. Bundling them here is a
deliberate solo-operator choice:

- **One self-hosted runner** can serve the secrets vault, the submodule
  bumper, the wiki linter, and downstream callers — without
  cross-repository credential plumbing.
- **One Monday-morning operational view**: `git pull && git status` in
  this directory tells you whether secrets need rotating, whether
  submodules drifted, whether the wiki lost a link.
- **One CHANGELOG** for the operational machinery, not five.

The cost is surface area: a contributor landing on this repo sees more
than a typical `.github` repo. That is the trade-off this `VISION.md`
exists to surface, not to hide.

## What this repo is *not*

- **Not a place for per-project code.** Source code for `ruvector`,
  `weftos`, or any other FlexNetOS project lives in those repos.
- **Not a documentation site.** The `docs/` tree documents *operational*
  conventions shared across repos. Per-project docs live in their own
  `docs/`.
- **Not a release artifact host.** Tagged releases of this repo only
  describe the umbrella's own changelog. Downstream repos cut their own
  releases through [`reusable-release.yml`](.github/workflows/reusable-release.yml).

## See also

- [`README.md`](README.md) — usage walkthrough and inheritance mechanics
- [`MAINTAINERS.md`](MAINTAINERS.md) — who to ask, how to escalate
- [`RELEASING.md`](RELEASING.md) — tagging policy and the v1 path
- [`docs/README.md`](docs/README.md) — index of best-practices docs
- [`USER.TODO.md`](USER.TODO.md) — one-time human actions that unlock
  the rest of the automation (not checked in to public history;
  maintainer's setup list)
