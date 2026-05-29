# TODO — current changes needed

> Working TODO list for the FlexNetOS/.github umbrella repo. Separate from `USER.TODO.md` (human-only actions; agent appends only to `## Agent-flagged user actions`).
> Applied changes move to `CHANGELOG.md`. Per-session logs land in `SESSIONS.md`.
> The full deep-research plan that produced this list lives at `data/brain-data/research/my-github-reconciliation.md`.

**Last updated:** 2026-05-29 (SESSION-2026-05-29-001 — clone-setup skill fix + setup philosophy; PR #21)
**Branch:** `feat/session-2026-05-29-002`
**Last updated:** 2026-05-29 (SESSION-2026-05-29-002 — wrap-up skill updated: commit all + push + PR)
**Branch:** `feat/todo-session-2026-05-28-006`
**Status:** Vision sequence enforced in CLAUDE.md+AGENTS.md; fork-remediation dirty diffs captured; `make verify` clean; adoption/forks gated pending `gh auth login` (UA-005).
**Last updated:** 2026-05-29 (SESSION-2026-05-29-006 — `architecture/` artifact framework landed via OPSX multi-model flow; on `feat/architecture-framework`)
**Branch:** `feat/architecture-framework`
**Status:** `architecture/` framework MERGED to develop via PR #27 (`9b6ef51`). Cross-link fix (broken by archive, caught in /wrap-up verify) pending merge in PR #29 → `UA-2026-05-29-004`. DEFERRED: cross-repo rollout to submodules, registry generator, org-wide promotion.

---

## Next steps (immediate — post SESSION-005)

- [x] **Review + merge PR #20** (additive reconciliation tooling: doctors, reversibility chain, report-only CI, docs). ✓ Merged 2026-05-28.
- [x] After `manifest-drift.yml` runs green once on a PR, **promote its jobs REPORT_ONLY → STRICT** (remove `continue-on-error: true`) and create `.github/workflows/promote-strict.md` tracking which jobs are still report-only. ✓ Promoted `claude-dir-check` + `open-questions-lint` 2026-05-28; 3 jobs still REPORT_ONLY per `.github/workflows/promote-strict.md`.
- [x] Resolve **`UA-2026-05-28-001`** (hand-maintained `CHANGELOG.md` vs release-please). ✓ Resolved 2026-05-28: hand-maintained until `v1.0.0`; at tag-cut the operator renames `[Unreleased]` → `[0.x.0-bootstrap]` and activates release-please. Bootstrap history is preserved. Note added to CHANGELOG.md header.

## Pre-adoption dossier review gate (Phase 0 — GATED, human decision)

Companion plan: `~/.claude/plans/sprightly-shimmying-charm.md`. Cross-references the 17-gap plan in `data/brain-data/research/my-github-reconciliation.md`. Each dossier's section 9 gates every irreversible action below.

- [ ] Review `data/brain-data/research/ai-top-utility.md` section 9 — origin is FlexNetOS-owned (G3a exits 0, not 13).
- [ ] Review `data/brain-data/research/n8n.md` section 9 — already forked; sync cadence, local-changes question.
- [ ] Review `data/brain-data/research/fabro.md` section 9 — **go/no-go on `gh repo fork fabro-sh/fabro --org FlexNetOS`** (IRREVERSIBLE).
- [ ] Review `data/brain-data/research/paperclip.md` section 9 — **go/no-go on `gh repo fork paperclipai/paperclip --org FlexNetOS`** (IRREVERSIBLE).

## Adoption execution (GATED on Phase 0; reversibility tooling now exists in `scripts/g3*`)

- [ ] Per `ai-top-utility.md` §6 — convert `repos/ai-top-utility/` → `repos/owned/ai-top-utility/` submodule + MANIFEST entry (OWNED). Use `scripts/g3a-can-convert.sh` → `g3b` → `g3c` then submodule add.
- [ ] Per `n8n.md` §6 — set up `develop` on `FlexNetOS/n8n`, convert to `repos/forked/n8n/` submodule + MANIFEST entry (FORKED).
  - ✓ MANIFEST entry → `branch: develop` + pnpm/docker toolchain + notes (SESSION-2026-05-29-005).
  - ✓ Build verified healthy; all §10 dossier decisions resolved.
  - blocked by: UA-2026-05-29-003 (develop-branch push + submodule conversion; needs human `git push`).
- [ ] Per `fabro.md` §6 (gated by §9 + explicit user OK) — fork, set up develop, convert to `repos/forked/fabro/` + MANIFEST entry.
- [ ] Per `paperclip.md` §6 (gated by §9 + explicit user OK) — fork, set up develop, convert to `repos/forked/paperclip/` + MANIFEST entry.

## Per-fork org-only setup (Phase B/C/D — once each fork exists, on `develop`)

- [ ] `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`.
- [ ] `.github/FUNDING.yml`: copy from umbrella.
- [ ] `.github/FLEXNETOS-ENV.md`: pointer to umbrella `secrets/envs/dev.env.tmpl` + `direnv allow`.
- [ ] `.github/workflows/ci.yml`: thin caller using umbrella reusable workflows.
- [ ] Branch protection on mirror branch (`main`/`master`): linear history, block direct pushes.
- [ ] Branch protection on `develop`: PR + 1 review.

**Out of scope (would break upstream sync):** internal package renames, Docker image refs, README badges, upstream-authored docs.

## Umbrella state fixes (deferred from 4-clone session)

- [x] **Rewrite `docs/directory-layout.md` to Model B.** ✓ Done 2026-05-28.
- [x] Append 5-line "Adopting a new upstream" pointer to `docs/fork-workflow.md` (owned vs already-forked vs needs-fork). ✓ Done 2026-05-28.
- [x] Verify `docs/submodule-vision.md` still consistent with Model B. ✓ Consistent — no changes needed.

## `.claude/settings.json` trim (G8 — tooling DONE, trim itself GATED)

> The doctor exists: `make claude.doctor` reports **39 violations** in the live file (read-only, never modifies it). Performing the trim moves the user's working hooks to user-global `~/.claude/settings.json` — a user-environment change, so it stays a deliberate, reviewed step.

- [ ] Remove the 10 hardcoded `/home/drdave/.claude/hooks/...` + `/home/drdave/memory/...` hook paths from `.claude/settings.json`; relocate to `~/.claude/settings.json`.
- [ ] Remove the 5 hardcoded plugin marketplace paths.
- [ ] Remove `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

## MANIFEST ↔ `.gitmodules` reconciliation (P4 closure, Option B lockfile) — DEFERRED

> Deferred from the additive pass: this refactors the **working** `submodules.*` machinery, so it is not additive. Tracked as **G4/G5 in `.omc/plans/open-questions.md`**. Decide the open question before starting.

- [ ] Author `scripts/materialize-gitmodules.sh` (deterministic; `--check`/`--write`/stdout).
- [ ] Extend `repos/MANIFEST.yaml` with optional `shallow:` field (S4 content-equivalence).
- [ ] Move `tools/{cpython,actionlint,gitleaks,trivy,node,bun,uv}` + `network/slim` into MANIFEST with `groups: [build-tooling] shallow: true`.
- [ ] Rewrite `make submodules.add` to go MANIFEST → `materialize --write` → `submodule init && update` (no raw `git submodule add`); add guardrail `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty.
- [ ] Add `make submodules.materialize-resolve` (S5) and `make submodules.init GROUP=<name>` (G17).
- [ ] Flip the `submodules-materialize-noop` job in `manifest-drift.yml` from placeholder to a real check once the pattern lands.

## USER.TODO#5 sequencing (detector DONE; tags + 404-resilience remain)

- [x] Add `# depends-on: USER.TODO#5` comments to the 4 pending-fork MANIFEST entries (Archon, everything-claude-code, oh-my-claudecode, oh-my-pi). ✓ Done 2026-05-28 — `check-user-todo-step5.sh --list-tagged` surfaces all 4.
- [x] Refactor `scripts/submodule-add-all.sh` to be 404-resilient: tagged 404 → WARN exit 0; untagged 404 → ERROR exit 1. ✓ Done 2026-05-28.
- [ ] **CRITICAL:** No `gh repo fork ... --org FlexNetOS` until the original-side cleanup is verified per-fork. See memory `feedback-fork-after-original-setup`.
  - Dirty diffs captured at `data/brain-data/research/fork-remediation/` (SESSION-2026-05-28-006). Next step per `/clone-setup`: `make research.pack URL=<upstream>` for each repo — gated on UA-2026-05-28-005 (`gh auth login`). (SESSION-2026-05-28-007)
- [ ] Update `branch: main` → `branch: develop` in `repos/MANIFEST.yaml` for everything-claude-code, oh-my-claudecode, oh-my-pi (Vision: `develop` carries FlexNetOS changes; gated until after fork remediation).

## CI invariant promotion (workflow DONE; promotion remains)

- [x] Create `.github/workflows/promote-strict.md` (tracks which `manifest-drift.yml` jobs are still REPORT_ONLY). ✓ Done 2026-05-28.
- [ ] After one green PR cycle each, flip remaining jobs to STRICT (remove `continue-on-error`). Remaining: `claude-settings-doctor` (fix G8 first), `check-user-todo-step5` (intentionally soft), `submodules-materialize-noop` (deferred). See `.github/workflows/promote-strict.md`.

## Reservations (carry-forward)

1. ✅ **6+ scripts now built** (SESSION-005): `claude-settings-doctor.js`, `g3a/g3b/g3c-*.sh`, `reconcile-stray-clones.sh`, `check-user-todo-step5.sh`, `open-questions-lint.js`, extended `runner-doctor.sh`. (Materialize/lockfile script remains deferred — see open-questions.)
2. **2 of 4 stray clones halt at G3a UNSAFE-MISMATCH** — `fabro` (`fabro-sh/fabro`), `paperclip` (`paperclipai/paperclip`). `ai-top-utility` is FlexNetOS-owned (exits 0). Each halting clone needs manual operator triage; cannot be automated without violating P5.

## Out of scope (deferred per ralplan)

- USER.TODO#5 itself (upstream operator task; gated).
- `.github/copilot-instructions.md` path audit.
- Toolchain version bumps.
- GitHub App automation refactor (recent commits stable).
- `v1.0.0` tag cut (USER.TODO step 10).
