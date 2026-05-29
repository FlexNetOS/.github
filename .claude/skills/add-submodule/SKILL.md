---
name: add-submodule
description: Gated research-before-fork ritual for adding a repo to the FlexNetOS umbrella. Use when adding, forking, or vendoring any external repository into repos/ or repos/MANIFEST.yaml. Enforces Step-0 clone-and-pack, a written research dossier, and original-clone setup BEFORE any fork.
disable-model-invocation: true
---

# add-submodule — research-before-fork ritual

Adding a repo to this umbrella is the most error-prone recurring workflow here.
Forking before research / before the original clone is set up has broken repos
before (the ruflu/ruvector incident). This skill encodes the mandatory gate so
the steps cannot be skipped or reordered.

**Never run `gh repo fork` until every gate below is green.**

## Inputs

- `URL` — upstream GitHub URL or `owner/repo`.
- `category` — one of `owned` | `forked` | `external` (decides mount path
  `repos/<category>/<name>/` and MANIFEST section).
- `branch` — tracking branch (default `main`; forks usually track upstream
  `main`/`master` with FlexNetOS work on `develop`).

## Checklist (run top to bottom; stop on any failure)

1. **Gate 0 — not already present.** Confirm the repo is not already in
   `repos/MANIFEST.yaml` and not already a submodule (`git submodule status`).
2. **Step 0 — clone and pack the UPSTREAM source.**
   ```bash
   make research.pack URL=<owner/repo> [BRANCH=<branch>]
   ```
   This wraps `scripts/clone-and-pack.sh` + `tools/bin/repomix` and writes the
   packed upstream into `data/brain-data/research/<name>/`. The dossier MUST be
   written against this packed source, not from memory or the web alone.
3. **Write the research dossier** at `data/brain-data/research/<name>.md`:
   what the repo is, license, toolchain, why FlexNetOS wants it, maintenance
   burden, security/supply-chain notes, and the chosen `category` + tracking
   branch with rationale. The dossier file existing is a hard prerequisite for
   the next step.
4. **Gate 1 — original clone set up properly** (only for `forked`/`owned`):
   confirm the upstream is cloned and building/working locally BEFORE forking.
   Forking into the org before original setup is the exact step that previously
   caused breakage — do not skip.
5. **Only now**, perform the fork (forked category) — this is a **human action**:
   append it to `USER.TODO.md` under `## Agent-flagged user actions` rather than
   running `gh repo fork ... --org FlexNetOS` yourself.
6. **Register in MANIFEST** — add the entry to the correct section of
   `repos/MANIFEST.yaml` (`path`, `url`, `upstream` for forks, `branch`,
   `toolchain`, `groups`, optional `notes`). Keep `.gitmodules` consistent.
7. **Materialize the submodule:**
   ```bash
   make submodules.add        # idempotent; adds MANIFEST entries missing from .gitmodules
   make verify.manifest       # validate MANIFEST structure
   ```
8. **Record** the change in `CHANGELOG.md` (`[Unreleased]`) and a `SESSIONS.md`
   entry; flag any remaining human steps in `USER.TODO.md`.

## Fork branch model (category = forked)

`main`/`master` mirrors upstream untouched; `develop` carries FlexNetOS changes;
PRs target `develop`. Sync = fast-forward `main` + rebase `develop`. See
`docs/fork-workflow.md`.

## Done criteria

- `data/brain-data/research/<name>/` (packed) **and** `<name>.md` (dossier) exist.
- MANIFEST + `.gitmodules` consistent; `make verify.manifest` passes.
- Any fork/auth/billing step is in `USER.TODO.md`, not executed by the agent.
