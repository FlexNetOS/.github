# CHANGELOG

> Applied changes to the FlexNetOS/.github umbrella repo. Entries are dated and reference the source TODO item or research artifact where applicable.
> Forward-looking work lives in `TODO.md`. Session wrap-ups live in `SESSIONS.md`. Deep research artifacts live in `data/brain-data/research/`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repo aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once `v1.0.0` is cut (see `USER.TODO.md` step 10).

**Ownership handoff (UA-2026-05-28-001):** This file is hand-maintained until `v1.0.0` is tagged. At that point, the operator renames `## [Unreleased]` below to `## [0.x.0-bootstrap] - <date>`, then activates `release.yml` (release-please). Release-please will manage `## [Unreleased]` and all version sections from that point forward, auto-generating entries from Conventional Commits. The bootstrap history below is preserved as a versioned section. The `release.yml` workflow is currently `workflow_dispatch`-only pending USER.TODO org/App setup — do not activate it before those gates pass.

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
- **Additive reconciliation tooling** (SESSION-2026-05-28-005, PR #20):
  - `scripts/claude-settings-doctor.js` — report-only `.claude/settings.json` hygiene scanner (hardcoded user-home paths + aspirational keys; allowlist-aware; never modifies the live file). (research: my-github-reconciliation G1/G7)
  - `scripts/g3a-can-convert.sh`, `scripts/g3b-backup-branch.sh`, `scripts/g3c-stash-and-move.sh`, `scripts/reconcile-stray-clones.sh` — reversibility chain (predicate + backup + dry-run move + orchestrator). (research: G3a-d)
  - `scripts/check-user-todo-step5.sh` — MANIFEST USER.TODO#5 tag detector. (research: G11)
  - `scripts/open-questions-lint.js` — open-questions schema validator. (research: G15)
  - `.claude/settings.canonical.json`, `.claude/.doctor-allowlist`, `.codex/.doctor-allowlist` — doctor reference shape + allowlists. (research: G6/G9)
  - `.omc/plans/open-questions.md` — 6 seeded entries (G3 triage, G4/G5 deferred, G15, G16).
  - `.github/workflows/manifest-drift.yml` — REPORT_ONLY CI: `claude-dir-check`, settings doctor, user-todo-5, open-questions-lint, deferred materialize-noop. (research: G14/G15-claude-dir)
  - Makefile targets: `claude.doctor`, `config.doctor`, `check.user-todo-5`, `open-questions.lint`.

- `.claude/skills/clone-setup/SKILL.md` — three-phase research-before-fork automation: `make research.pack` → code-first analysis (manifest → compressed pack → source → README last, enforced) → verified setup in `.attic/research-work/<name>/`; mandatory §12 Discrepancies table; `gh repo fork` never called by the skill. (SESSION-2026-05-28-006)

### Changed
- `.claude/skills/wrap-up/SKILL.md` — step 7 now commits all session work (7a: uncommitted substantive files), commits bookkeeping (7b), pushes branch to origin (7c), and opens a PR via `gh pr create` (7d); done-when item 6 updated from "committed, not pushed" to "committed, pushed, PR open"; do-not list updated (removed "Don't push", added "Don't force-push"); step 8 report now includes PR URL. (SESSION-2026-05-29-002)
- `scripts/runner-doctor.sh` — extended with `ps`-based orphan/ghost runner-process detection. (SESSION-2026-05-28-005; research: G12)
- `CONTRIBUTING.md` — added AI-tooling directory convention (`.claude` not `Claude`), CI-invariant promotion pattern, doctor allowlist policy, `.gitmodules` merge-conflict note. (SESSION-2026-05-28-005; research: G10/G14/G9)
- `README.md` — added Repo-navigation table + Phase-6 Vaultwarden operational gate. (SESSION-2026-05-28-005; research: G13)
- `Makefile` — added the reconciliation-tooling target block. (SESSION-2026-05-28-005)

### Changed (2026-05-29)
- `.claude/skills/clone-setup/SKILL.md` — **fix:** added `HARD RULES` section and `Idempotency` decision table to prevent false-positive health detection on re-runs; script's `✅ Step 0 complete` is now documented as "pack available" not "healthy"; fork gate overrides script output. (SESSION-2026-05-29-001)
- `.claude/skills/clone-setup/SKILL.md` — **feat:** added `Setup philosophy` section: (1) local-host-only free tier over paid cloud (service substitution table + docker-compose-first heuristic), (2) tooling preference order (Rust/cargo → bunx → mise → direnv), (3) always full-feature dev setup (never `--production`/`--slim`). (SESSION-2026-05-29-001)

### Removed
- _(none yet)_

### Decisions recorded (2026-05-28)
- **Model B authoritative**: submodules live INSIDE `my-github/repos/{owned,forked,external}/`, NOT as `$HOME/_work/repos/_forks/` siblings. The doc `docs/directory-layout.md` describes the retired model and must be rewritten (queued in `TODO.md`).
- **Rename scope = Org-only**: CODEOWNERS, branch protection, FUNDING.yml, FLEXNETOS-ENV.md only. Internal package names (`package.json:name`, `Cargo.toml:name`, Docker image refs) deliberately untouched to keep upstream sync conflict-free.
- **Submodule `.github` overrides + caller workflows** inherit umbrella reusables via `uses: FlexNetOS/.github/.github/workflows/reusable-*.yml@main`. Switch to `@v1` once tagged.
- **Research-before-fork is a hard rule**: per-clone dossier must exist on disk at `data/brain-data/research/<name>.md` before any `gh repo fork` runs. Codified in cross-session memory `feedback-fork-after-original-setup.md` after the ruflu/ruvector incident.
- **G4/G5 lockfile pattern deferred** (SESSION-2026-05-28-005): the MANIFEST→`.gitmodules` materialize/lockfile refactor was deliberately excluded from the additive-tooling pass because it refactors the working `submodules.*` machinery (not additive). Tracked in `.omc/plans/open-questions.md`; the `submodules-materialize-noop` CI job is a placeholder until it lands.

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

### Added (SESSION-2026-05-28-007)
- `AGENTS.md` — new cross-CLI instruction file: repo identity, branch discipline, 5-step Vision sequence (clone→research→setup→fork→submodule), full-clone-only rule, secrets policy, what agents get wrong, session tracking. (research: GitHub Workspace Vision)
- `data/brain-data/research/fork-remediation/` — dirty state snapshots for 3 fork-violated repos (everything-claude-code, oh-my-claudecode, oh-my-pi): `.patch` files + `ecc-untracked/` agentic-os subsystem (30 files) + 10-step remediation `README.md`. (TODO: USER.TODO#5)

### Changed (SESSION-2026-05-28-007)
- `CLAUDE.md` — added full 5-step Vision sequence + "What Claude gets wrong" hard guards + "Branch discipline at session start" subsection.
- `USER.TODO.md` — replaced 7× `_work/repos/my-github` → `workspace/my-github` (old-path migration); appended UA-2026-05-28-005/006/007.
- `repos/MANIFEST.yaml` — fixed header contradiction about `.gitmodules` regeneration; updated weftos + archon notes; removed stale `_work/repos/actions-runner/` ref.
- `secrets/store/.gpg-id` — replaced placeholder with real GPG fingerprint `6EC33743AA0CB75126F63F8765A937C4164F966F`.
- `tools/bin/repomix` — use `bunx` over `npx` (workspace uses bun 1.3.13 via mise); npx fallback retained.
- `.gitignore` — added `.claude/plugins/cache/`, `.claude/plugins/marketplaces/`, `.claude/plugins/data/` (555 MB plugin cache; regenerated by `omc install`).
- `scripts/verify-markdown.py` — added `.attic` to EXCLUDE_PARTS; 4 new EXCLUDE_PREFIXES for third-party dirs; result: `OK: 58 markdown files checked`.
- `.claude/agents/wrap-up-verifier.md` — fixed 1 bare fence (` ``` ` → ` ```text `).
- `.claude/skills/clone-setup/SKILL.md` — fixed 3 bare fences.
- `.claude/skills/wrap-up/SKILL.md` — fixed 2 bare fences.

### Decisions recorded (2026-05-28, SESSION-2026-05-28-007)
- **Fork-first violation confirmed** for everything-claude-code, oh-my-claudecode, oh-my-pi: all three set up from forks before clone/research/setup (Vision sequence violated). Dirty diffs captured before remediation. Correct sequence: clone upstream fresh → `make research.pack` → verify setup → `gh repo fork` → develop branch → apply patches → submodule. See `data/brain-data/research/fork-remediation/README.md`.
- **`tools/repomix/` stays gitignored** (not a submodule); promotion to MANIFEST/.gitmodules deferred until/unless FlexNetOS forks repomix.
- **`make verify` clean baseline**: 3 tool assets, 58 markdown files, 28 manifest entries, 13 tool entries — all pass on `feat/todo-session-2026-05-28-006`.

### Notes (SESSION-2026-05-28-007)
- **No `gh repo fork` calls made.** All fork remediation gated on UA-2026-05-28-005 (`gh auth login`).
- **No push to origin. No submodule mutations.**
- **MANIFEST `branch:` entries** for everything-claude-code, oh-my-claudecode, oh-my-pi still say `branch: main` — should be `branch: develop` per Vision; tracked in `TODO.md`.
- Session work fully committed (4 commits) on `feat/todo-session-2026-05-28-006`.

---

## Conventions

- **Date format:** ISO 8601 (YYYY-MM-DD).
- **Sections per release:** Added / Changed / Deprecated / Removed / Fixed / Security (Keep a Changelog standard).
- **Cross-references:** When an entry implements a `TODO.md` item, include a brief `(TODO: <item-name>)` tag. When it implements a research recommendation, include `(research: <slug>)`.
- **Pre-`v1.0.0`:** all entries land under `[Unreleased]`. After `v1.0.0` is cut per USER.TODO step 10, cut a dated release header above `[Unreleased]`.
