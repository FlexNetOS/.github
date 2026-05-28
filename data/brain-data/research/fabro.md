# Research: fabro

**Status:** Pre-adoption research. **Third-party upstream — needs fork.**
**Action gated by this dossier:** `gh repo fork fabro-sh/fabro --org FlexNetOS` + branch setup + submodule at `repos/forked/fabro/`.

**Cross-reference:** Matches [my-github-reconciliation.md](my-github-reconciliation.md) Reservation 2 — fabro origin is NOT under FlexNetOS, so G3a will exit 13 (UNSAFE-MISMATCH). Operator must triage via this dossier and grant explicit go-ahead before fork.

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/fabro-sh/fabro.git` |
| Our fork (to be created) | `https://github.com/FlexNetOS/fabro` |
| License | **MIT** (badge in README; `LICENSE.md` in repo) |
| Upstream default branch | `main` |
| Current local branch | `main` |
| Local state | clean; in sync with origin/main (origin = upstream raw clone) |
| Latest upstream commit | `3634048a3 fix(web): keep runs empty state from being pushed to page bottom` (2026-05-27) |
| Docs site | `https://docs.fabro.sh` |
| Upstream CI | `.github/workflows/rust.yml` exists |

## 2. Purpose (per README)

> *"The open source dark software factory for expert engineers. AI coding agents are powerful but unpredictable. You either babysit every step or review a 50-file diff you don't trust. Fabro gives you a middle path: define the process as a graph, let agents execute it, and intervene only where it matters."*

Graph-based orchestration for AI coding agents. Define process as
nodes/edges; agents execute; human-in-the-loop intervention at defined
checkpoints. Positioned between "fully autonomous" and "babysit every
step."

## 3. Stack inventory

Polyglot — **Node monorepo + Rust workspace + Docker**.

- Root `package.json`: `"private": true`, `workspaces: ["apps/*", "lib/packages/*"]`.
- Root `Cargo.toml`: workspace with `members = ["lib/crates/*", "test/twin/openai", "test/twin/github"]`, `default-members = ["lib/crates/fabro-cli"]`, `resolver = "2"`.
- Directories: `.ai/`, `.cargo/`, `.claude/`, `.config/`, `.fabro/`,
  `apps/`, `bin/`, `docker/`, `docs/`, `evals/`, `installer/`, `lib/`,
  `target/`, `test/`.
- Has `.env.example` + `.dockerignore`.

Substantial polyglot codebase. Rust `target/` will inflate clone size;
consider `partial_clone: "tree:0"` for non-Rust runners.

## 4. FlexNetOS-side intent

Overlaps the umbrella's existing AI-agent cluster (archon,
everything-claude-code, oh-my-claudecode, oh-my-pi — all PENDING-FORK).
Fabro is distinct via the **graph-based orchestration model with
checkpointed intervention**, complementing the agent-runtime focus of
the existing cluster. Likely use:
- Define cross-repo workflows as fabro graphs.
- Gate sensitive ops (releases, refactors) behind human checkpoints.
- Possible integration with `understand-anything` for codebase intel
  input to fabro graphs.

## 5. Pre-adoption audit

- License is MIT — no friction to fork.
- Local clone clean, in sync with `fabro-sh/fabro:main`.
- `gh repo fork` is correct mechanism (preserves attribution).
- Polyglot — adoption touches Node + Rust. Both already in umbrella
  `tools/MANIFEST.yaml`.
- Upstream is **young** — no major release tag visible. Schema/CLI
  surface may churn. Rebase pain on `develop` if FlexNetOS commits land in
  files upstream actively refactors.
- Upstream CI is `.github/workflows/rust.yml` only. Add caller `ci.yml`
  for FlexNetOS umbrella reusables (lint + security + mixed-language
  test), don't replace `rust.yml`.
- Has `.claude/`, `.ai/`, `.config/` — overlap with FlexNetOS
  conventions. Treat upstream's as authoritative; do not overwrite.
- Has `.fabro/` — fabro-app-specific data dir. Verify not gitignored
  or committing user state.

## 6. Adoption plan

Case: **third-party — needs fork**.

1. **Irreversible: requires user explicit go-ahead + this dossier section 9
   resolved.**
   ```bash
   gh repo fork fabro-sh/fabro --org FlexNetOS --clone=false
   ```
2. Rewire local clone's remotes:
   ```bash
   cd repos/fabro
   git remote rename origin upstream
   git remote add origin https://github.com/FlexNetOS/fabro.git
   git push origin main                       # seed the fork
   git checkout -b develop && git push -u origin develop
   ```
3. Replace plain clone with submodule:
   ```bash
   # From umbrella root
   rm -rf repos/fabro
   mkdir -p repos/forked
   git submodule add --depth=1 -b develop \
       https://github.com/FlexNetOS/fabro.git \
       repos/forked/fabro
   cd repos/forked/fabro
   git remote add upstream https://github.com/fabro-sh/fabro.git
   ```
4. MANIFEST entry:
   ```yaml
   - path: repos/forked/fabro
     url: https://github.com/FlexNetOS/fabro
     upstream: https://github.com/fabro-sh/fabro
     branch: develop
     toolchain: [node, cargo, docker]
     groups: [forked, agents, orchestration]
     notes: |
       Graph-based orchestration for AI coding agents (MIT). Polyglot
       Node monorepo + Rust workspace. Upstream default branch is `main`;
       fork's `main` mirrors upstream, `develop` carries FlexNetOS
       changes.
   ```
5. Phase B (org-only rename) on `develop`:
   - `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`
   - Branch protection on `main`: linear history, no direct pushes
   - Branch protection on `develop`: PR + 1 review
   - `.github/FUNDING.yml`: FlexNetOS funding
   - `.github/FLEXNETOS-ENV.md`: env-scaffold pointer
   - `.github/workflows/ci.yml`: caller for umbrella reusables (lint +
     security; test stays on upstream's `rust.yml`)

## 7. Sync risk

**Medium-High.** Young, fast-moving polyglot codebase:
- Cargo workspace `members:` will change → don't edit on `develop`.
- `package.json` workspaces will change → don't edit on `develop`.
- Any FlexNetOS-side changes to fabro internals (vs. additive new files in
  `.github/`) will produce rebase friction.
- **Recommended:** keep `develop` near-identical to `main`; FlexNetOS
  changes accumulate in **new files**, not modifications to upstream's.

## 8. Verification

```bash
cd /home/drdave/workspace/my-github
make verify.manifest
make submodules.sync-upstream NAME=fabro   # "no upstream changes"
git -C repos/forked/fabro diff upstream/main..develop -- \
    package.json Cargo.toml Dockerfile README.md   # must be empty
```

## 9. Open decisions for user

- [ ] **Go/no-go on `gh repo fork fabro-sh/fabro --org FlexNetOS`.** The
      irreversible action.
- [ ] Intended use case for fabro inside FlexNetOS — orchestration of
      what, specifically? Affects which integrations to prioritize.
- [ ] Partial clone? Rust workspace + Node monorepo + Docker → heavy
      submodule. `tree:0` recommended for CI runners.
- [ ] Adopt fabro alongside or before the 4 PENDING-FORK agents (archon,
      everything-claude-code, oh-my-claudecode, oh-my-pi)? Adjacent in
      role.

## 10. Decision log

(empty — fill on adoption)
