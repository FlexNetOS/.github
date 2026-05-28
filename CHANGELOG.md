# CHANGELOG

> Applied changes to the FlexNetOS/.github umbrella repo. Entries are dated and reference the source TODO item or research artifact where applicable.
> Forward-looking work lives in `TODO.md`. Session wrap-ups live in `SESSIONS.md`. Deep research artifacts live in `data/brain-data/research/`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once `v1.0.0` is cut (see `USER.TODO.md` step 10).

---

## [Unreleased]

### Added
- `TODO.md` — working TODO list for active changes (separate from `USER.TODO.md` for human-only setup steps).
- `CHANGELOG.md` — this file; tracks applied changes per project convention.
- `SESSIONS.md` — session wrap-up log (plural; logs all session summaries with session IDs, reference code, and location).
- `data/brain-data/research/my-github-reconciliation.md` — full ralplan consensus deliverable (iteration 3, APPROVED) covering VISION/PLAN/USER.TODO gap analysis, the `.claude` vs `Claude` directory resolution, and the 17-gap reconciliation plan.
- `data/brain-data/research/ai-top-utility.md` — pre-adoption dossier (FlexNetOS-owned, no upstream). (research: 4-clone-adoption)
- `data/brain-data/research/n8n.md` — pre-adoption dossier (already forked to `FlexNetOS/n8n`; needs `develop` branch + path normalization). (research: 4-clone-adoption)
- `data/brain-data/research/fabro.md` — pre-adoption dossier (third-party upstream `fabro-sh/fabro`; `gh repo fork` gated by section 9). (research: 4-clone-adoption)
- `data/brain-data/research/paperclip.md` — pre-adoption dossier (third-party upstream `paperclipai/paperclip`; `gh repo fork` gated by section 9). (research: 4-clone-adoption)
- Cross-session memory at `~/.claude/projects/.../memory/`:
  - `my-github-umbrella-model.md` — Model B authoritative + umbrella vision (no host-side installs, single-clone reproducibility).
  - `fork-workflow-branch-model.md` — `main`/`master` <-> upstream, `develop` <-> FlexNetOS branch model per `docs/fork-workflow.md`.
- Companion plan at `~/.claude/plans/sprightly-shimmying-charm.md` — the 4-clone adoption thread (Model B, Phase 0 dossier gate, research-before-fork rule).

### Changed
- _(none yet — plan is `pending approval`, no execution authorized)_

### Removed
- _(none yet)_

### Decisions recorded (2026-05-28)
- **Model B authoritative**: submodules live INSIDE `my-github/repos/{owned,forked,external}/`, NOT as `$HOME/_work/repos/_forks/` siblings. The doc `docs/directory-layout.md` describes the retired model and must be rewritten (queued in `TODO.md`).
- **Rename scope = Org-only**: CODEOWNERS, branch protection, FUNDING.yml, FLEXNETOS-ENV.md only. Internal package names (`package.json:name`, `Cargo.toml:name`, Docker image refs) deliberately untouched to keep upstream sync conflict-free.
- **Submodule `.github` overrides + caller workflows** inherit umbrella reusables via `uses: FlexNetOS/.github/.github/workflows/reusable-*.yml@main`. Switch to `@v1` once tagged.
- **Research-before-fork is a hard rule**: per-clone dossier must exist on disk at `data/brain-data/research/<name>.md` before any `gh repo fork` runs. Codified in cross-session memory `feedback-fork-after-original-setup.md` after the ruflu/ruvector incident.

### Corrections to prior work (2026-05-28)
- `data/brain-data/research/my-github-reconciliation.md` Reservation 2 — `ai-top-utility` was listed as "likely UNSAFE-MISMATCH". Verified origin is `https://github.com/FlexNetOS/ai-top-utility.git` (FlexNetOS-owned, no upstream remote). Correction recorded in `data/brain-data/research/ai-top-utility.md` cross-reference block, in the reconciliation doc Reservation 2 note, and in `TODO.md` Reservations section.

### Notes
- Convention established on 2026-05-28 per user instruction: research/plans go in `data/brain-data/research/`; root carries `TODO.md` (todo), `CHANGELOG.md` (applied), `SESSIONS.md` (session wrap-up). Prior `.omc/plans/my-github-reconciliation.md` was moved to the canonical research location.
- **No `gh repo fork` calls have been made.** All forks remain gated behind dossier section 9 review + explicit per-clone go-ahead.
- **No submodule conversions have been performed.** All 4 clones still sit flat at `repos/<name>/` (neither documented place).
- **No `repos/MANIFEST.yaml` entries have been added** for the 4 adoptees.
- **2026-05-28 (restore):** All root tracking files (`TODO.md`, `CHANGELOG.md`, `SESSIONS.md`) and the 4 pre-adoption dossiers + reconciliation plan were accidentally removed and recreated on branch `feat/restore-session-wrapup-files`. They had never been committed (untracked working-tree files), confirming the `feedback-always-commit` rule. This restore commits them so they cannot be lost to a routine `git reset` again.

### Added (SESSION-2026-05-28-003)
- `.omc/plans/ralplan-browser-choice.md` — ralplan v5 six-layer Linux workstation architecture (Pi-hole + dnscrypt-proxy + Cloudflare/Quad9 → vproxy → Slim → Firefox + Bifrost + Obscura, with trippy diagnostic sidecar). 5 iterations of consensus planning; status `pending approval`. **Misfiled per convention — see `UA-2026-05-28-003`.**
- `scripts/install-v5-architecture.sh` — 7-phase install script for the v5 architecture with `--dry-run` and `--phase N` flags, pre-flight prereq checks, abort-before-DNS-swap safety, recovery runbook embedded in epilogue. `bash -n` clean. Not yet executed.
- `USER.TODO.md` — 3 new UA items: `UA-2026-05-28-002` (rotate leaked Anthropic + OpenRouter keys), `UA-2026-05-28-003` (move v5 plan to canonical `data/brain-data/research/` path), `UA-2026-05-28-004` (decide whether `3dd0ef4` should remain on `main`).

### Decisions recorded (2026-05-28, SESSION-2026-05-28-003)
- **Six-layer workstation architecture (ralplan v5):** per-purpose tools at each layer (DNS / outbound proxy / local DNS+HTTPS / browser / LLM gateway / automation browser) rather than overloading one browser. Rejected: Edge (Linux second-class), Brave (user rejection), Chrome (auto-update friction), Chrome for Testing (more wiring than bundled chromium), bundled chromium as default (obscura is purpose-built). Decoupling pattern is brand-agnostic and recoverable per-layer.
- **Hard rule: feature branch before session work.** Installed globally at `~/.claude/hooks/branch-guard.sh` + matching `SessionStart` and `PreToolUse:Edit|Write|MultiEdit` entries in `~/.claude/settings.json` + new "Hard rule" section in `~/.claude/CLAUDE.md`. SessionStart warns when HEAD is `main`/`master`/`trunk`; PreToolUse blocks Edit/Write on source files (allows `.claude/`, `.omc/`, `.github/`, `CLAUDE.md`, `AGENTS.md`, `docs/**/*.md`). Per-repo allowlist + override supported; session bypass via `BRANCH_GUARD_OFF=1`. Outside-repo files unaffected.

### Notes (SESSION-2026-05-28-003)
- **Branch-guard install is *global*, not committed to this repo** — lives under `~/.claude/`. Backup at `~/.claude/settings.json.bak-pre-branch-guard-20260528-135800`.
- **Secrets at `$HOME` (outside repo, chmod 600, not committed):** `~/bifrost/.env`, `~/pihole/pihole_password.txt`, `~/vproxy/.env`. Anthropic + OpenRouter keys in `~/bifrost/.env` must be rotated immediately — see `UA-2026-05-28-002`.
- **Convention violation flagged:** v5 plan committed to `.omc/plans/ralplan-browser-choice.md` rather than the canonical `data/brain-data/research/v5-workstation-architecture.md`. Tracked in `UA-2026-05-28-003`.
- **`3dd0ef4` first landed on `main`, not on a feature branch.** Wrap-up notes that the new branch-guard rule (installed *during the same session*) would have prevented this. The commit is now also reachable from `feat/restore-session-convention-files` (this branch); see `UA-2026-05-28-004` for the decision about whether to keep it on `main`.

---

## Conventions

- **Date format:** ISO 8601 (YYYY-MM-DD).
- **Sections per release:** Added / Changed / Deprecated / Removed / Fixed / Security (Keep a Changelog standard).
- **Cross-references:** When an entry implements a `TODO.md` item, include a brief `(TODO: <item-name>)` tag. When it implements a research recommendation, include `(research: <slug>)`.
- **Pre-`v1.0.0`:** all entries land under `[Unreleased]`. After `v1.0.0` is cut per USER.TODO step 10, cut a dated release header above `[Unreleased]`.
