# TODO — current changes needed

> Working TODO list for the FlexNetOS/.github umbrella repo. Separate from `USER.TODO.md` (human-only actions; agent appends only to `## Agent-flagged user actions`).
> Applied changes move to `CHANGELOG.md`. Per-session logs land in `SESSIONS.md`.
> The full deep-research plan that produced this list lives at `data/brain-data/research/my-github-reconciliation.md`.

**Last updated:** 2026-05-29 (SESSION-2026-05-29-015 — PR pipeline driven to finish line: develop CI repaired, network scaffolding salvaged, #66/#51 closed as superseded, develop→main promoted)
**Branch:** `develop` (all PRs target develop)
**Status:** All open PRs resolved; `main`↔`develop` content-in-sync; remote pruned to `main`+`develop`; `ci-failure-tracker` live on `main`. Adoption/forks still gated pending `gh auth login` (UA-005).

---

## CI-failure autofix (follow-on to `ci-failure-tracker.yml`)

> `ci-failure-tracker.yml` is now **LIVE on `main`** (promoted via PR #67): it watches the umbrella's workflows and opens an issue tagged `ci-failure` + `needs-autofix` referencing the failed run + per-job logs whenever CI fails. The autofix loop below consumes those issues.

- [ ] **Autofix failed workflows from `needs-autofix` issues.** Build the loop that picks up an open `ci-failure` issue, fetches the referenced run/job logs, diagnoses the root cause, and opens a fix PR against the failing branch (or comments a diagnosis when the fix needs human judgement). Candidate trigger: `issues` (labeled `needs-autofix`) → dispatch a Claude autofix job; or a scheduled sweep over open `ci-failure` issues. On success the tracker's `resolve` job auto-closes the issue when the workflow next goes green.
  - Gate: do not enable write-mode autofix on `main` until the tracker has run green for ≥1 cycle and the issue-noise/dedupe behaviour is confirmed sane on a feature branch.
  - First create the `ci-failure` + `needs-autofix` repo labels (the tracker assumes they can be applied; `github.rest.issues.create` will create missing labels on first use, but pre-creating them with colors/descriptions is cleaner).

## `.claude/settings.json` hygiene (gated G8 trim — non-required CI red)

> Surfaced SESSION-2026-05-29-015. After the splice repair (#71) settings.json is valid JSON, but the `.claude/settings.json hygiene` doctor + `Trivy filesystem + IaC` (both **non-required**, non-blocking) stay red on pre-existing violations.

- [ ] Remove the 4 hardcoded `/home/` marketplace paths (`ecc`, `karpathy-skills`, `omc`, `understand-anything`) and the forbidden `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` key from tracked `.claude/settings.json`; relocate marketplace defs to user-global `~/.claude/settings.json`. **Gated:** user-environment change — could disable plugin marketplaces for this project. (overlaps the G8 trim item below)

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
  - ✓ Full dossier complete (Phases 1–3 verified; SESSION-2026-05-29-009).
  - ✓ Local setup: `repos/paperclip feat/local-setup` — pnpm install, build, dev server, AGENTS.md hierarchy.
  - Fork explicitly **deferred** by user (§10: "No go" as of 2026-05-29). Revisit when priority resolved vs. fabro.
  - blocked by: user go/no-go decision.

## Per-fork org-only setup (Phase B/C/D — once each fork exists, on `develop`)

- [ ] `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`.
- [ ] `.github/FUNDING.yml`: copy from umbrella.
- [ ] `.github/FLEXNETOS-ENV.md`: pointer to umbrella `secrets/envs/dev.env.tmpl` + `direnv allow`.
- [ ] `.github/workflows/ci.yml`: thin caller using umbrella reusable workflows.
- [ ] Branch protection on mirror branch (`main`/`master`): linear history, block direct pushes.
- [ ] Branch protection on `develop`: PR + 1 review.

**Out of scope (would break upstream sync):** internal package renames, Docker image refs, README badges, upstream-authored docs.

## MANIFEST ↔ `.gitmodules` reconciliation (P4 closure, Option B lockfile) — DEFERRED

> Deferred from the additive pass: this refactors the **working** `submodules.*` machinery, so it is not additive. Tracked as **G4/G5 in `.omc/plans/open-questions.md`**. Decide the open question before starting.

- [ ] Author `scripts/materialize-gitmodules.sh` (deterministic; `--check`/`--write`/stdout).
- [ ] Extend `repos/MANIFEST.yaml` with optional `shallow:` field (S4 content-equivalence).
- [ ] Move `tools/{cpython,actionlint,gitleaks,trivy,node,bun,uv}` + `network/slim` into MANIFEST with `groups: [build-tooling] shallow: true`.
- [ ] Rewrite `make submodules.add` to go MANIFEST → `materialize --write` → `submodule init && update` (no raw `git submodule add`); add guardrail `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty.
- [ ] Add `make submodules.materialize-resolve` (S5) and `make submodules.init GROUP=<name>` (G17).
- [ ] Flip the `submodules-materialize-noop` job in `manifest-drift.yml` from placeholder to a real check once the pattern lands.

## USER.TODO#5 sequencing (detector DONE; branch targets set)

- [ ] **CRITICAL:** No `gh repo fork ... --org FlexNetOS` until the original-side cleanup is verified per-fork. See memory `feedback-fork-after-original-setup`.
  - Dirty diffs captured at `data/brain-data/research/fork-remediation/` (SESSION-2026-05-28-006). Next step per `/clone-setup`: `make research.pack URL=<upstream>` for each repo — gated on UA-2026-05-28-005 (`gh auth login`). (SESSION-2026-05-28-007)

## n8n + n8n-mcp service persistence

- [ ] **n8n and n8n-mcp are running as unmanaged background processes** — both die on reboot. Create systemd user units (or pm2 config) so they auto-start. n8n: `node packages/cli/bin/n8n start` via dotenvx from `repos/n8n/`. n8n-mcp: `node dist/mcp/index.js` from `repos/n8n/mcp/n8n-mcp/` with env from `.env`.
- [ ] **n8n-mcp `.env` is not pass-managed** — `AUTH_TOKEN` and `N8N_API_KEY` are plaintext in `repos/n8n/mcp/n8n-mcp/.env` (gitignored). Consider wiring via `direnv` + `pass` after UA-2026-05-29-003 (n8n submodule conversion) lands.

## Reservations (carry-forward)

1. ✅ **6+ scripts now built** (SESSION-005): `claude-settings-doctor.js`, `g3a/g3b/g3c-*.sh`, `reconcile-stray-clones.sh`, `check-user-todo-step5.sh`, `open-questions-lint.js`, extended `runner-doctor.sh`. (Materialize/lockfile script remains deferred — see open-questions.)
2. **2 of 4 stray clones halt at G3a UNSAFE-MISMATCH** — `fabro` (`fabro-sh/fabro`), `paperclip` (`paperclipai/paperclip`). `ai-top-utility` is FlexNetOS-owned (exits 0). Each halting clone needs manual operator triage; cannot be automated without violating P5.
3. **6 local-only unmerged branches retained** (SESSION-2026-05-29-015) — real in-flight work with no PRs, kept during branch cleanup: `feat/ci-autofix-claude` (github-agentic-os runner), `feat/github-agentic-os-runner`, `feat/github-automation-doctor`, `docs/root-claude-md`, `fix/pr24-settings-json`, `fix/architecture-crosslinks`. Open PRs when ready; recoverable from the all-refs backup bundle either way.

## Out of scope (deferred per ralplan)

- USER.TODO#5 itself (upstream operator task; gated).
- `.github/copilot-instructions.md` path audit.
- Toolchain version bumps.
- GitHub App automation refactor (recent commits stable).
- `v1.0.0` tag cut (USER.TODO step 10).
