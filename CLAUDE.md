# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo actually is

This working directory is named `my-github` on disk but **is the `FlexNetOS/.github` repository** — the org's special `.github` repo, not a generic project. It is a **mega-umbrella** playing six roles at once (read [`VISION.md`](VISION.md) first):

1. **Org community-health fallback** — root + `.github/` community files (`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `FUNDING.yml`, issue/PR templates) are inherited by every other FlexNetOS repo that doesn't ship its own.
2. **Mount point for ~24 git submodules** — `repos/MANIFEST.yaml` is the single source of truth; submodules live under `repos/{owned,forked,external}/`.
3. **Karpathy LLM-wiki** cross-project memory layer in `wiki/`.
4. **`pass`+GPG secrets vault** in `secrets/` (paper-recoverable via age).
5. **Self-hosted GitHub Actions runner host config** in `runner/`.
6. **Shared reusable-CI templates** — `.github/workflows/reusable-*.yml` consumed by downstream repos via `workflow_call`.

There is **nothing to "build" or "run"** here — it is operational config + scripts + docs. The real codebases live in the submodules under `repos/`, each with its own toolchain. `cd` into a submodule and read its own `CLAUDE.md`/`AGENTS.md`/`README.md` before touching it.

## Commands

All work flows through the `Makefile` (run `make help` for the full list). Real logic lives in `scripts/` (Python + shell, a couple of Node scripts); the Makefile is the typo-tolerant surface.

```bash
make verify              # Run ALL local verification — the gate before any PR
make verify.actionlint   # Lint .github/workflows/*.yml (pinned tools/bin/actionlint)
make verify.markdown     # python3 scripts/verify-markdown.py .
make verify.manifest     # Validate repos/MANIFEST.yaml structure
make verify.tools        # Validate tools/MANIFEST.yaml structure
make verify.tool-assets  # Validate pinned repo-local tool asset manifest
make verify.hermetic     # Advisory: report non-hermetic deps

# Single checks (run the underlying script directly):
python3 scripts/verify-markdown.py .
python3 scripts/verify-manifest.py repos/MANIFEST.yaml
tools/bin/actionlint .github/workflows/<file>.yml

# Reconciliation doctors (read-only):
make claude.doctor       # Flag hardcoded user-home paths / aspirational keys in .claude/settings.json
make config.doctor       # claude.doctor + .codex allowlist note
make github.doctor       # Read-only audit of runner/workflows/app/submodules/secrets state
make open-questions.lint # Validate .omc/plans/open-questions.md schema
make check.user-todo-5   # List MANIFEST entries tagged/untagged for USER.TODO#5

# Submodules (prefer the Makefile verbs over raw git submodule):
make submodules.init                 # update --init --recursive --depth 1
make submodules.add                  # Add MANIFEST entries missing from .gitmodules (idempotent)
make submodules.bump GROUP= NAME=    # Fast-forward to tracking-branch HEAD
make submodules.sync-upstream NAME=  # For forked/, fetch upstream and merge
make submodules.status               # Report dirty/ahead/detached submodules
```

There is no test runner — `make verify` is the equivalent. CI mirrors these (`ci.yml`, `manifest-drift.yml`).

## Critical workflows (non-obvious)

### Adding a new repo: research-before-fork ritual
**Never** `gh repo fork` or add a submodule before researching the upstream first. The required order:
1. **Step 0 — clone and pack:** `make research.pack URL=<owner/repo>` (wraps `scripts/clone-and-pack.sh`, uses `tools/bin/repomix`) to pack the *upstream source* into `data/brain-data/research/<name>/`.
2. Write the research dossier at `data/brain-data/research/<name>.md` from that packed source.
3. Only after the dossier exists, and after the original clone is properly set up, fork/add the submodule. Forking before original setup previously broke repos — this gate is mandatory.

Fork branch model: `main`/`master` mirrors upstream untouched, `develop` carries FlexNetOS changes, PRs target `develop`; sync = fast-forward `main` + rebase `develop`.

### Manifest ↔ .gitmodules consistency
`repos/MANIFEST.yaml` is authoritative. Today `.gitmodules` is hand-maintained *alongside* it — keep the two consistent. `scripts/submodule-add-all.sh` appends missing entries; full MANIFEST→`.gitmodules` regeneration (the "materialize/lockfile" pattern) is **deferred** (tracked as G4/G5 in `.omc/plans/open-questions.md`). Don't blindly regenerate `.gitmodules`.

### Session tracking (run via `/wrap-up`)
This repo tracks work in four root files — keep them current:
- `TODO.md` — agent-side working TODO.
- `USER.TODO.md` — human-only actions (push, fork, auth, billing). The agent appends **only** to its `## Agent-flagged user actions` section.
- `CHANGELOG.md` — applied changes (Keep-a-Changelog `[Unreleased]`).
- `SESSIONS.md` — per-session log with `SESSION-YYYY-MM-DD-NNN` IDs.

Research/plans go in `data/brain-data/research/` — never in `.omc/plans/` or scratch dirs.

### Commit discipline
**Commit agent-produced work as you go** (stage + commit incrementally). Untracked drafts in this repo have been wiped by routine `git reset`/cherry-pick before — this overrides any "only commit when asked" default. Branch off `main` with `<type>/<short-slug>`; `main` is protected (PR + 1 approval, linear history, no force-push). Conventional Commits are required (the release workflow computes bumps from them). Squash- or rebase-merge only, no merge commits.

## Conventions that won't show up in the code

- **`.claude/` is lowercase, leading dot, always.** Never create a PascalCase `Claude/` directory — that's a different product (Claude Desktop on macOS/Windows). CI enforces this via the `claude-dir-check` job in `manifest-drift.yml`. `AGENTS.md` is the cross-CLI instruction file at repo root; per-tool config lives in `.claude/` / `.codex/`.
- **No hardcoded absolute user-home paths** in tracked `.claude`/`.codex` config (`/home/<user>/…`, `/Users/<user>/…`, `C:\Users\<user>\…`) — CI errors, never allowlistable. Portable refs (`$HOME`, `~/`, `%APPDATA%`) are allowed only when listed in `.claude/.doctor-allowlist` / `.codex/.doctor-allowlist` with a rationale. `make claude.doctor` enforces this.
- **CI invariant promotion: report-only first, then STRICT.** New CI checks land with `continue-on-error: true` on PRs (annotate without blocking). After one full green cycle on `main`, promote to strict. `manifest-drift.yml` jobs are currently report-only.
- **Operational gate:** Phase 6 (GitHub App automation) must not proceed until the Vaultwarden→GitHub secret sync is green on `main` for ≥3 consecutive runs.
- **Tool submodules in `tools/`** (cpython, actionlint, gitleaks, trivy, node, bun, uv) are pinned upstream sources; `tools/bin/` holds thin pinned wrappers. `tools/repomix/` is a gitignored local clone, **not** a submodule.

## Toolchain note

Scripts call `python3` (system 3.14 — do not `pip install` against it; scripts are stdlib-only or use repo-local tools). Node scripts run under the mise-managed node. The repo is intentionally hermetic where possible — `make verify.hermetic` reports drift.
