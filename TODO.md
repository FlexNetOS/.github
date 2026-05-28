# TODO — current changes needed

> Working TODO list for the FlexNetOS/.github umbrella repo. Separate from `USER.TODO.md` (one-time human setup steps).
> Applied changes move to `CHANGELOG.md`. End-of-session summaries land in `SESSIONS.md`.
> The full deep-research plan that produced this list lives at `data/brain-data/research/my-github-reconciliation.md`.

**Last updated:** 2026-05-28 (post-ralplan consensus + 4-clone pre-adoption research)
**Branch:** `feat/github-app-automation`
**Status:** plan `pending approval`; no execution authorized yet.

---

## Pre-adoption dossier review gate (Phase 0 — added 2026-05-28)

Companion plan: `~/.claude/plans/sprightly-shimmying-charm.md` (the 4-clone adoption thread).
Cross-references the broader 17-gap plan in `data/brain-data/research/my-github-reconciliation.md`.

These four dossiers exist on disk; their section 9 "Open decisions for user" checklists gate every irreversible action that follows.

- [ ] Review `data/brain-data/research/ai-top-utility.md` section 9 — security-hardening branch handling, PDF asset strategy, `.claude/` overlap policy. **Correction noted:** origin is FlexNetOS-owned (G3a will exit 0, not 13).
- [ ] Review `data/brain-data/research/n8n.md` section 9 — SUL license fit, sync cadence, local-FlexNetOS-changes question. Already forked.
- [ ] Review `data/brain-data/research/fabro.md` section 9 — **go/no-go on `gh repo fork fabro-sh/fabro --org FlexNetOS`** (IRREVERSIBLE), use case, partial-clone strategy.
- [ ] Review `data/brain-data/research/paperclip.md` section 9 — **go/no-go on `gh repo fork paperclipai/paperclip --org FlexNetOS`** (IRREVERSIBLE), `skills/` integration strategy, brand sensitivity.

## Adoption execution (gated on Phase 0)

- [ ] Per `data/brain-data/research/ai-top-utility.md` section 6 — convert `repos/ai-top-utility/` -> `repos/owned/ai-top-utility/` submodule + add MANIFEST entry under OWNED.
- [ ] Per `data/brain-data/research/n8n.md` section 6 — set up `develop` on `FlexNetOS/n8n`, convert to `repos/forked/n8n/` submodule + add MANIFEST entry under FORKED.
- [ ] Per `data/brain-data/research/fabro.md` section 6 (gated by section 9 + explicit user OK) — `gh repo fork`, set up develop, convert to `repos/forked/fabro/` submodule + MANIFEST entry.
- [ ] Per `data/brain-data/research/paperclip.md` section 6 (gated by section 9 + explicit user OK) — `gh repo fork`, set up develop, convert to `repos/forked/paperclip/` submodule + MANIFEST entry.

## Per-fork org-only setup (Phase B/C/D — applies once each fork exists)

For each forked adoptee (`n8n`, `fabro`, `paperclip`), on `develop`:

- [ ] `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`.
- [ ] `.github/FUNDING.yml`: copy from umbrella.
- [ ] `.github/FLEXNETOS-ENV.md`: pointer to umbrella `secrets/envs/dev.env.tmpl` + `direnv allow` instructions.
- [ ] `.github/workflows/ci.yml`: thin caller using umbrella reusable workflows (`uses: FlexNetOS/.github/.github/workflows/reusable-*.yml@main`).
- [ ] Branch protection on mirror branch (`main`/`master`): linear history, block direct pushes (`gh api -X PUT`).
- [ ] Branch protection on `develop`: PR + 1 review.

**Out of scope (would break upstream sync):** internal package renames, Docker image refs, README badges, upstream-authored docs.

## Umbrella state fixes (deferred from 4-clone session)

- [ ] **Rewrite `docs/directory-layout.md` to Model B.** The current doc describes a retired sibling-checkout pattern (`$HOME/_work/repos/_forks/_firstparty/_readonly/`) that conflicts with the MANIFEST-based submodule layout. Acknowledge the retired pattern in a one-line note.
- [ ] Append "Phase 0 follow-ons: 4 fresh clones to adopt" section to `USER.TODO.md` next to the existing 4 PENDING-FORK adoptees so it's one queue.
- [ ] Append 5-line "Adopting a new upstream" pointer to `docs/fork-workflow.md` (owned vs already-forked vs needs-fork).
- [ ] Verify `docs/submodule-vision.md` still consistent with Model B.

## Doc + convention

- [ ] Append CONTRIBUTING.md "Directory conventions for AI tooling" block (G10) with the verbatim section 5 disambiguation: `.claude/` (lowercase) only; no `Claude/`.
- [ ] Append CONTRIBUTING.md "CI invariant promotion pattern" (G14) referencing the existing upgrade-auto-review workflow as canon (report-only -> STRICT after green cycle).
- [ ] Append CONTRIBUTING.md "Resolving a `.gitmodules` merge conflict" recipe (G15-merge-resolve).
- [ ] Append CONTRIBUTING.md allowlist policy (G9) for intentional `$HOME`/`~/` references.
- [ ] README "Repo navigation" section linking `USER.TODO.md`, `TODO.md`, `CHANGELOG.md`, `SESSIONS.md`, and the canonical research dir.

## Working tree hygiene

- [ ] Per-clone triage now lives in pre-adoption dossiers under `data/brain-data/research/` (one per clone). Each dossier section 9 has the operator checklist that gates `gh repo fork` / submodule conversion.
- [ ] Path-repair `repos/n8n/` -> `repos/forked/n8n/` via the G3a-d reversibility chain (G3a verified SAFE for n8n). Plan per `data/brain-data/research/n8n.md` section 6.
- [ ] Gitignore `docker/` (host Docker daemon state — buildkit/containers/image/network/swarm/etc).
- [ ] **DO NOT gitignore `data/`** — it is intentional content (Obsidian vault, brain-data, canonical research folder). Earlier draft misclassified it.

## `.claude/settings.json` trim (G8a/b/c, P2 closure)

- [ ] Remove 10 hardcoded `/home/drdave/.claude/hooks/...` and `/home/drdave/memory/...` hook command paths from `.claude/settings.json`. Move to user-global `~/.claude/settings.json`.
- [ ] Remove 5 hardcoded plugin marketplace paths (`/home/drdave/_work/...`, `/home/drdave/repos/...`).
- [ ] Remove `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (aspirational; umbrella doesn't gate any feature on it).
- [ ] Author `scripts/claude-settings-doctor.js` with `--diff` and `--check`.
- [ ] Define `.claude/settings.canonical.json` (canonical shape).
- [ ] Add `.claude/.doctor-allowlist` (policy: `$HOME`/`~/` allowed only with rationale; hardcoded user paths NEVER allowed).
- [ ] Add `make claude.doctor` Make target.

## MANIFEST <-> `.gitmodules` reconciliation (P4 closure, Option B lockfile)

- [ ] Author `scripts/materialize-gitmodules.sh` (deterministic emission; `--check` / `--write` / stdout flags).
- [ ] Extend `repos/MANIFEST.yaml` schema with optional `shallow:` field (S4 content-equivalence).
- [ ] Move existing `tools/{cpython, actionlint, gitleaks, trivy, node, bun, uv}` + `network/slim` entries into MANIFEST with `groups: [build-tooling]` and explicit `shallow: true`.
- [ ] Rewrite `make submodules.add` workflow: (1) edit MANIFEST -> (2) `make submodules.materialize --write` -> (3) `git submodule init && update <path>`. Never call raw `git submodule add`.
- [ ] Add guardrail check: `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty.
- [ ] Add `make submodules.materialize-resolve` Make target for `.gitmodules` merge conflicts (S5).
- [ ] Add `make submodules.init GROUP=<name>` for selective init via `groups:` filter (G17 — CI clone-cost mitigation).

## USER.TODO#5 sequencing (machine-readable tags)

- [ ] Add `# depends-on: USER.TODO#5` comments to each MANIFEST entry whose URL points at a not-yet-created FlexNetOS fork (Archon, everything-claude-code, oh-my-claudecode, oh-my-pi).
- [ ] Author `scripts/check-user-todo-step5.sh` with `--list-tagged` / `--list-untagged`.
- [ ] Refactor `scripts/submodule-add-all.sh` to be 404-resilient: tagged 404 -> WARN exit 0; untagged 404 -> ERROR exit 1.
- [ ] **CRITICAL:** No `gh repo fork ... --org FlexNetOS` operations until the original-side cleanup is complete and verified per-fork. See memory: feedback-fork-after-original-setup.

## Reversibility chain (G3a-d)

- [ ] Author `scripts/g3a-can-convert.sh` (predicate with exit codes 0 SAFE / 10 dirty / 11 stash / 12 unpushed / 13 UNSAFE-MISMATCH).
- [ ] Author `scripts/g3b-backup-branch.sh` (creates `local-backup/<name>-<date>` ref).
- [ ] Author `scripts/g3c-stash-and-move.sh` (moves to `.omc/backups/`).
- [ ] Author `scripts/reconcile-stray-clones.sh` (orchestrates G3a->b->c->d per target).

## `.codex/config.toml` doctor (G9)

- [ ] Author `make config.doctor` Make target (generalizes `make claude.doctor` to `.codex/`).
- [ ] Add `.codex/.doctor-allowlist` (TOML) with entry for `~/.codex/config.toml` per `.codex/AGENTS.md` policy.

## Open-questions log + linter

- [ ] Create `.omc/plans/open-questions.md` with structured schema: `**Question:**` / `**Candidates:**` / `**Blocker for resolution:**`.
- [ ] Author `scripts/open-questions-lint.js`.
- [ ] Seed entries for G3b/c/d per-directory triage (fabro, paperclip — ai-top-utility is FlexNetOS-owned, not a triage case).
- [ ] Seed entry for G15 (RELEASING.md vs `.omc/RELEASE_RULE.md` canon).
- [ ] Seed entry for G16 (`wiki/` growth policy).

## CI invariants (REPORT_ONLY -> STRICT)

- [ ] Add `.github/workflows/manifest-drift.yml` with jobs: materialize-noop, claude-doctor, config-doctor, check-user-todo-step5, claude-dir-regression, open-questions-lint. All start REPORT_ONLY.
- [ ] Document promotion gates in `.github/workflows/promote-strict.md`.
- [ ] After one green PR cycle each, flip jobs to STRICT.

## Phase 5/6 detection-only slice items (G12, G13)

- [ ] **G12 — runner lifecycle detection** (slice scope: detection only; resolution Phase 5). Author `scripts/runner-doctor.sh` that lists currently running self-hosted runner processes (via `ps`) and compares against `runner/registered.json` if present. Reports orphans (running but not registered) and ghosts (registered but not running). Add `make runner.doctor` target. No remediation in slice.
- [ ] **G13 — Vaultwarden secret-sync gate sentence** (slice scope: one-line documentation; resolution Phase 6). Append to README.md roadmap section: "Phase 6 (GitHub App automation) MUST NOT proceed until Vaultwarden->GitHub secret sync is green on `main` for at least 3 consecutive runs." No code change in slice.

## Reservations (the Critic-flagged items — review before granting execution)

1. **6+ new scripts must be written** — `materialize-gitmodules.sh` (most critical), `claude-settings-doctor.js`, `g3a-can-convert.sh`, `g3b-backup-branch.sh`, `g3c-stash-and-move.sh`, `reconcile-stray-clones.sh`, `open-questions-lint.js`. Realistic scope is moderate engineering, not config cleanup.
2. **2 of 4 stray clones halt at G3a UNSAFE-MISMATCH** — `fabro` (origin: `fabro-sh/fabro`), `paperclip` (origin: `paperclipai/paperclip`). The reconciliation plan originally listed `ai-top-utility` as a third — **corrected**: its origin is `FlexNetOS/ai-top-utility` (FlexNetOS-owned), so it does NOT halt. Per dossier.

## Out of scope (deferred per ralplan)

- USER.TODO#5 itself (upstream operator task; gated per feedback memory).
- `.github/copilot-instructions.md` path audit.
- Toolchain version bumps.
- GitHub App automation refactor (recent commits stable).
- `v1.0.0` tag cut (USER.TODO step 10).
