# TODO — current changes needed

> Agent-side working TODO list for the FlexNetOS/.github umbrella repo. Separate from `USER.TODO.md` (human-only setup steps; agent appends only to its `## Agent-flagged user actions` section).
> Applied changes move to `CHANGELOG.md`. Per-session logs land in `SESSIONS.md`.
> The full deep-research plan that produced this list lives at `data/brain-data/research/my-github-reconciliation.md`.

**Last updated:** 2026-05-28 (restored from transcript after accidental removal)
**Branch of record:** `feat/restore-session-convention-files`
**Plan status:** `pending approval`; no execution of the reconciliation slice authorized yet.

---

## Doc + convention

- [ ] Append CONTRIBUTING.md "Directory conventions for AI tooling" block (G10) with the verbatim §5 disambiguation: `.claude/` (lowercase) only; no `Claude/`.
- [ ] Append CONTRIBUTING.md "CI invariant promotion pattern" (G14) referencing the existing upgrade-auto-review workflow as canon (report-only → STRICT after green cycle).
- [ ] Append CONTRIBUTING.md "Resolving a `.gitmodules` merge conflict" recipe (G15-merge-resolve).
- [ ] Append CONTRIBUTING.md allowlist policy (G9) for intentional `$HOME`/`~/` references.
- [ ] README "Repo navigation" section linking `USER.TODO.md`, `TODO.md`, `CHANGELOG.md`, `SESSIONS.md`, and the canonical research dir.

## Working tree hygiene

- [ ] Decide per-directory state for `repos/{ai-top-utility, fabro, paperclip}/` — three are likely UNSAFE-MISMATCH (origins not under FlexNetOS); requires per-clone triage in open-questions log (G3b/c/d).
- [ ] Path-repair `repos/n8n/` → `repos/forked/n8n/` via the G3a-d reversibility chain (G3a verified SAFE for n8n).
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

## MANIFEST ↔ `.gitmodules` reconciliation (P4 closure, Option B lockfile)

- [ ] Author `scripts/materialize-gitmodules.sh` (deterministic emission; `--check` / `--write` / stdout flags).
- [ ] Extend `repos/MANIFEST.yaml` schema with optional `shallow:` field (S4 content-equivalence).
- [ ] Move existing `tools/{cpython, actionlint, gitleaks, trivy, node, bun, uv}` + `network/slim` entries into MANIFEST with `groups: [build-tooling]` and explicit `shallow: true`.
- [ ] Rewrite `make submodules.add` workflow: (1) edit MANIFEST → (2) `make submodules.materialize --write` → (3) `git submodule init && update <path>`. Never call raw `git submodule add`.
- [ ] Add guardrail check: `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty.
- [ ] Add `make submodules.materialize-resolve` Make target for `.gitmodules` merge conflicts (S5).
- [ ] Add `make submodules.init GROUP=<name>` for selective init via `groups:` filter (G17 — CI clone-cost mitigation).

## USER.TODO#5 sequencing (machine-readable tags)

- [ ] Add `# depends-on: USER.TODO#5` comments to each MANIFEST entry whose URL points at a not-yet-created FlexNetOS fork (Archon, everything-claude-code, oh-my-claudecode, oh-my-pi).
- [ ] Author `scripts/check-user-todo-step5.sh` with `--list-tagged` / `--list-untagged`.
- [ ] Refactor `scripts/submodule-add-all.sh` to be 404-resilient: tagged 404 → WARN exit 0; untagged 404 → ERROR exit 1.
- [ ] **CRITICAL:** No `gh repo fork ... --org FlexNetOS` operations until the original-side cleanup is complete and verified per-fork. See memory: feedback-fork-after-original-setup.

## Reversibility chain (G3a-d)

- [ ] Author `scripts/g3a-can-convert.sh` (predicate with exit codes 0 SAFE / 10 dirty / 11 stash / 12 unpushed / 13 UNSAFE-MISMATCH).
- [ ] Author `scripts/g3b-backup-branch.sh` (creates `local-backup/<name>-<date>` ref).
- [ ] Author `scripts/g3c-stash-and-move.sh` (moves to `.omc/backups/`).
- [ ] Author `scripts/reconcile-stray-clones.sh` (orchestrates G3a→b→c→d per target).

## `.codex/config.toml` doctor (G9)

- [ ] Author `make config.doctor` Make target (generalizes `make claude.doctor` to `.codex/`).
- [ ] Add `.codex/.doctor-allowlist` (TOML) with entry for `~/.codex/config.toml` per `.codex/AGENTS.md` policy.

## Open-questions log + linter

- [ ] Create `.omc/plans/open-questions.md` with structured schema: `**Question:**` / `**Candidates:**` / `**Blocker for resolution:**`.
- [ ] Author `scripts/open-questions-lint.js`.
- [ ] Seed entries for G3b/c/d per-directory triage (ai-top-utility, fabro, paperclip).
- [ ] Seed entry for G15 (RELEASING.md vs `.omc/RELEASE_RULE.md` canon).
- [ ] Seed entry for G16 (`wiki/` growth policy).

## CI invariants (REPORT_ONLY → STRICT)

- [ ] Add `.github/workflows/manifest-drift.yml` with jobs: materialize-noop, claude-doctor, config-doctor, check-user-todo-step5, claude-dir-regression, open-questions-lint. All start REPORT_ONLY.
- [ ] Document promotion gates in `.github/workflows/promote-strict.md`.
- [ ] After one green PR cycle each, flip jobs to STRICT.

## Phase 5/6 detection-only slice items (G12, G13)

These two were in v2's gap inventory at slice-scope-detection-only level but dropped from v3's phase tables without explicit deferral. Adding for completeness; resolution is genuinely Phase 5/6.

- [ ] **G12 — runner lifecycle detection** (slice scope: detection only; resolution Phase 5). Author `scripts/runner-doctor.sh` that lists currently running self-hosted runner processes (via `ps`) and compares against `runner/registered.json` if present. Reports orphans (running but not registered) and ghosts (registered but not running). Add `make runner.doctor` target. No remediation in slice — only detection + report.
- [ ] **G13 — Vaultwarden secret-sync gate sentence** (slice scope: one-line documentation; resolution Phase 6). Append to README.md roadmap section: "Phase 6 (GitHub App automation) MUST NOT proceed until Vaultwarden→GitHub secret sync (`feat: add Vaultwarden GitHub secret sync`) is green on `main` for at least 3 consecutive runs." No code change in slice.

## Reservations (the Critic-flagged items — review before granting execution)

1. **6+ new scripts must be written** — `materialize-gitmodules.sh` (most critical), `claude-settings-doctor.js`, `g3a-can-convert.sh`, `g3b-backup-branch.sh`, `g3c-stash-and-move.sh`, `reconcile-stray-clones.sh`, `open-questions-lint.js`. Realistic scope is moderate engineering, not config cleanup.
2. **3 of 4 stray clones halt at G3a UNSAFE-MISMATCH** — `fabro` (origin: `fabro-sh/fabro`), `paperclip` (origin: `paperclipai/paperclip`), likely `ai-top-utility`. Requires per-clone operator triage; cannot be automated without violating P5.

## Out of scope (deferred per ralplan)

- USER.TODO#5 itself (upstream operator task; gated per feedback memory).
- `.github/copilot-instructions.md` path audit.
- Toolchain version bumps.
- GitHub App automation refactor (recent commits stable).
- `v1.0.0` tag cut (USER.TODO step 10).
