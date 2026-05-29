# AGENTS.md — FlexNetOS `.github` umbrella

Cross-CLI instruction file for AI agents (Codex, Gemini, Copilot, etc.).
Claude Code users: see `CLAUDE.md` for the full reference. This file summarises
the constraints that apply to **all** agents.

---

## What this repo is

`my-github` on disk = the `FlexNetOS/.github` org-wide repository. It is an
operational umbrella — community-health files, ~24 git submodules, a `pass`+GPG
secrets vault, a self-hosted GitHub Actions runner host config, and shared
reusable CI templates. **Nothing to build or run at the top level.** Real
codebases live in submodules under `repos/`; read their own `CLAUDE.md` /
`AGENTS.md` / `README.md` before touching them.

---

## Non-negotiable constraints

### 1. Branch discipline

**Never edit source files directly on `main`, `master`, or `trunk`.**

```bash
# At the start of every session:
git checkout -b feat/<short-descriptive-name>
```

The `branch-guard.sh` hook blocks `Edit`/`Write` on protected branches for
source files. It cannot be worked around — fix the branch, then edit.

Exempt from this rule: `.claude/**`, `.omc/**`, `.github/**`, `CLAUDE.md`,
`AGENTS.md`, `README.md`, `docs/**/*.md`.

### 2. External-repo sequence — never skip, never reverse

1. **Clone first** — new feature branch, original upstream, do not fork yet
2. **Research** — `make research.pack URL=<owner/repo>`, write dossier at `data/brain-data/research/<name>.md`
3. **Set it up working** — run as intended; host deps are temporary, not the destination
4. **Fork** — `gh repo fork <upstream> --org FlexNetOS --clone=false`; `main`/`master` tracks upstream clean, `develop` carries FlexNetOS changes
5. **Submodule** — `make submodules.add` registers the fork; `repos/MANIFEST.yaml` is the source of truth

Forking before step 3 is complete has previously broken repos. This gate is mandatory.

### 3. Full clones only

No `--depth 1`, no `--filter=blob:none`. The Vision requires full clones — workspace reproducibility depends on complete history.

### 4. Submodules are required, not optional

Every external dependency belongs in the git graph. Logs, cache, build artifacts — if it would normally be gitignored, it gets its own submodule. Nothing on disk is untracked in the broader git graph.

### 5. Secrets never in git

Secrets are injected at runtime via `pass` + `direnv`. `.env.example` files (keys listed, values empty) are committed; actual `.env` files never are.

---

## Canonical paths

| Location | Purpose |
|---|---|
| `/home/drdave/workspace/my-github` | Canonical repo root (migrated from `_work/repos/my-github`) |
| `repos/MANIFEST.yaml` | Single source of truth for all submodules |
| `data/brain-data/research/` | Research dossiers and plans — **never** `.omc/plans/` |
| `secrets/store/` | `pass`-managed GPG vault |
| `runner/` | Self-hosted GitHub Actions runner config |

---

## Key commands

```bash
make verify              # Run ALL local verification (gate before any PR)
make verify.manifest     # Validate repos/MANIFEST.yaml
make submodules.add      # Add MANIFEST entries missing from .gitmodules
make research.pack URL=<owner/repo>   # Clone + repomix-pack upstream for research
make claude.doctor       # Audit .claude/settings.json for bad paths
```

---

## What agents get wrong

- Suggesting shallow/partial clones (`--depth 1`, `--filter`)
- Forking before the original is cloned and working
- Treating `_work/repos/` as the canonical path (canonical is `workspace/my-github`)
- Putting research or plans in `.omc/plans/` (must be `data/brain-data/research/`)
- Editing on `main` instead of a feature branch
- Treating host-level installs as permanent (they are temporary; refactor into submodules)
- Skipping the `make research.pack` step before writing a dossier

---

## Session tracking

Four root files — keep them current via `/wrap-up`:

| File | Owner | Purpose |
|---|---|---|
| `TODO.md` | agent | Working TODO |
| `USER.TODO.md` | human | Human-only actions; agent appends only to `## Agent-flagged user actions` |
| `CHANGELOG.md` | both | Applied changes (Keep-a-Changelog `[Unreleased]`) |
| `SESSIONS.md` | agent | Per-session log (`SESSION-YYYY-MM-DD-NNN` IDs) |

---

## Full reference

See `CLAUDE.md` for the complete command reference, per-project conventions,
toolchain details, and CI invariant rules.

See `data/brain-data/obsidian-mind/brain/GitHub Workspace Vision.md` for the
architectural rationale behind every constraint above.
