# Work Plan: my-github Umbrella Repo Reconciliation

**Status:** pending approval
**Iteration:** 3 (Planner v3, post-Critic revision; APPROVED by Critic)
**Mode:** ralplan consensus, deliberate
**Generated:** 2026-05-28
**Branch under analysis:** `feat/github-app-automation`
**Repo:** `/home/drdave/workspace/my-github` (FlexNetOS/.github mega-umbrella)
**User prompt that triggered this plan:** `/ralplan Run deep research on the repo vision, plan, and TODO.md| what is missing?| where are the gaps?| claude expects ".claude" and "Claude" director| that means 2 seperate submodules ".claude" & "Claude"`

> **Execution status:** Plan is `pending approval`. No code changes, submodule mutations, or script writes have occurred. The user has not granted execution approval. To execute: invoke `/oh-my-claudecode:team` (recommended) or `/oh-my-claudecode:ralph` after reading the ADR + Critic reservations below.

---

## Direct answer to the user's directory question

**Use `.claude/` (lowercase, leading dot) only. Do NOT create a separate `Claude/` (PascalCase) directory. There is no two-submodule scheme.**

Empirical evidence (verified by orchestrator):
- `find /home/drdave/workspace/my-github -maxdepth 6 -type d -name 'Claude' -not -path '*/.git/*'` returns **zero matches**.
- Claude Code on Linux reads configuration from `.claude/` only — both user-global (`~/.claude/`) and project-local (`<project>/.claude/`).
- No git submodule for `Claude/` is expected, exists, or would be useful. The user's claim is incorrect.

Likely source of confusion:
- **Claude Desktop on macOS/Windows** uses `~/Library/Application Support/Claude/` (capitalized) — that is a different product (the Claude chat app), on a different OS family.
- **"Claude/Codex" prose** (e.g., in `wiki/README.md`) is a disjunction ("Claude or Codex"), not a path separator.
- **Configuration directory vs. git submodule** are categorically different mechanisms; the user's framing conflates them.

This answer is locked into CI via G15-claude-dir (see section 6) and documented in CONTRIBUTING.md per section 5.

---

## Changes from iteration 2 (the 5 Critic-mandated revisions, all closed)

1. **G8 rewritten against the verified 437-line `.claude/settings.json`** — targets the 16 hardcoded `/home/drdave/...` paths (10 hook commands + 5 plugin marketplace paths + 1 user-home memory hook) and the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` flag. Split into G8a (hooks), G8b (plugin marketplaces), G8c (env flag). Policy: trim umbrella `.claude/settings.json` to umbrella-backed entries only; user-specific hooks move to user-global `~/.claude/settings.json`. Integration test I3: `make claude.doctor` against post-trim file returns exit 0.
2. **P4 seam closed in Option B** — `make submodules.add` never calls raw `git submodule add`. Workflow: (1) edit MANIFEST entry, (2) `make submodules.materialize --write`, (3) `git submodule init && git submodule update <path>`. Guardrail: `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty.
3. **Pre-mortem expanded to 6 scenarios** — S4 (content equivalence via `shallow:` schema extension), S5 (merge conflict recipe via `make submodules.materialize-resolve`), S6 (allowlist for intentional user-global refs like `.codex/AGENTS.md` pointing at `~/.codex/config.toml`).
4. **G2 + G3a predicates tightened** — `# depends-on: USER.TODO#5` machine-read; tagged 404 = WARN exit 0, untagged 404 = ERROR exit 1. G3a "uncommitted local work" = union of 4 git predicates with named exit codes 10/11/12/13.
5. **`Claude/` directory regression check added to CI** — new step in `manifest-drift.yml`, REPORT_ONLY first, STRICT after one green cycle. CONTRIBUTING.md gets verbatim section 5 block.

Structural items from iteration 2 are unchanged: Option B selection, G3 decomposition, USER.TODO#5 sequencing, Phase 4.5 naming, ADR shape, 5 principles, 3 decision drivers, out-of-scope list.

---

## 1. Context

**Verified state evidence:**
- `repos/MANIFEST.yaml` — 30+ entries; declares `partial_clone:` per entry but NOT `shallow:`; zero `# depends-on:` tags currently.
- `.gitmodules` — 8 build-tooling submodules registered, all with `shallow = true` (this field is not in MANIFEST schema; S4 closes the gap).
- `repos/` working tree — 4 full clones present that should be submodules per MANIFEST or that lack entries: `repos/{ai-top-utility, fabro, n8n, paperclip}/`. `repos/n8n/` `origin` resolves to `https://github.com/FlexNetOS/n8n` (matches MANIFEST upstream). Other three origins are not under FlexNetOS — UNSAFE-MISMATCH expected per G3a.
- `.claude/settings.json` — **437 lines**. Contains: `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; 10 hook command paths under `/home/drdave/.claude/hooks/` and `/home/drdave/memory/`; 5 plugin marketplace paths under `/home/drdave/_work/...` and `/home/drdave/repos/...`. No `claudeFlow.*` keys exist.
- `scripts/submodule-add-all.sh` — exists; line 72 calls `git submodule add` directly (the P4 seam this plan closes).
- `scripts/materialize-gitmodules.sh` — **does NOT exist** (Critic reservation #1; must be authored as part of execution).
- `USER.TODO.md` — step 5 ("create missing FlexNetOS forks for Archon, everything-claude-code, oh-my-claudecode, oh-my-pi") is unresolved upstream.

---

## 2. Principles

| # | Principle | What it gates |
|---|---|---|
| P1 | **Empirical evidence over aspiration.** Plans target files that exist on disk in their actual current shape. No phantom keys. | G1, G7, G8 |
| P2 | **No hardcoded user-home paths in tracked config.** Hardcoded `/home/<user>/`, `/Users/<user>/`, `C:\Users\<user>\` are CI errors. | G8 |
| P3 | **CI-as-spec: every invariant is enforced by an automated check that runs report-only first, then strict after one green cycle.** | G2, G6, G8, G9, G11, G14, G15 |
| P4 | **One source of truth per concern.** No path mutates `.gitmodules` outside `make submodules.materialize --write`. | G3, G5, G14 |
| P5 | **Reversibility before destruction.** Predicate check + backup branch before any operation that could lose work. | G3a, G3b, G3c |

---

## 3. Decision Drivers

| # | Driver |
|---|---|
| D1 | **User work in `repos/n8n/` must not be destroyed.** Verified: full clone with `origin = https://github.com/FlexNetOS/n8n`. |
| D2 | **USER.TODO#5 is unresolved upstream.** Tooling must distinguish gated-404 (warn) from typo/permanent-404 (error). |
| D3 | **The `Claude` vs `.claude` answer must produce a durable CI-enforced artifact.** |

---

## 4. Options Considered

- **Option A — One-shot reconciliation.** Rejected (D1, P3, P5 violations).
- **Option B — Lockfile pattern with reconciliation slice (Phase 4.5). [SELECTED]** MANIFEST canonical; `.gitmodules` generated; `make submodules.add` never calls raw `git submodule add`.
- **Option C — Drop MANIFEST; `.gitmodules` as source.** Rejected (loses tier/partial_clone/depends-on metadata).
- **Option D — Quarantine and rebuild.** Rejected (destroys 30+ curated entries).
- **Option E — Symlinks.** Rejected (P2 violation; machine-bound).

---

## 5. Inlined answer: `Claude/` vs `.claude/` (verbatim to land in CONTRIBUTING.md)

> **Use `.claude/` (lowercase, leading dot) only.** It is the Claude Code per-repo config directory. Conventional. Hidden by default. Consumed by the Claude Code CLI and plugins. Settings live at `.claude/settings.json`.
>
> **Never create a `Claude/` (PascalCase, no dot) directory.** It is not a Claude Code convention; tooling does not look there; it will be confusing to future readers and to automation. If you find one, move its contents to `.claude/` and delete the PascalCase directory. CI enforces this — see `manifest-drift.yml` step `claude-dir-check`.
>
> **`AGENTS.md` is shared across CLIs** (Claude Code, Codex, Gemini, OMC) and lives at repo root. Per-tool config lives in the tool's hidden directory (`.claude/`, `.codex/`, etc.).

---

## 6. Gap Inventory & Phases

17 gaps (G1-G17), organized into a reconciliation slice (Phase 4.5) + follow-up Phase 5/6/7.

### Phase 1 — Decompose convert-to-submodule (reversibility) [G3a-d]

- **G3a** Predicate (READ-ONLY): exit 0 SAFE / 10 dirty / 11 stash / 12 unpushed / 13 UNSAFE-MISMATCH.
- **G3b** Backup branch `local-backup/<name>-<date>`.
- **G3c** Stash-and-move to `.omc/backups/repos-<name>-<date>/`.
- **G3d** `make submodules.add ENTRY=<name>` — the 3-step P4-safe workflow.

### Phase 2 — MANIFEST -> `.gitmodules` materialization (P4 closure) [G4, G5, G14]

- **G4** `make submodules.materialize` (read-only default; `--write` regenerates).
- **G5** MANIFEST schema gains optional `shallow:` field (S4 mitigation). 8 build-tooling entries get `shallow: true` explicitly.
- **G14** CI invariant: materialize-noop check in `manifest-drift.yml` (REPORT_ONLY -> STRICT).

### Phase 3 — USER.TODO#5 sequencing (machine-readable tag) [G2, G11]

- **G11** `check-user-todo-step5.sh --list-tagged` / `--list-untagged`.
- **G2** `submodule-add-all.sh` 404-resilient: tagged -> WARN, untagged -> ERROR.

### Phase 4 — `.claude/settings.json` trim [G1, G6, G7, G8a-c]

**G8a — Remove 10 hardcoded `/home/drdave/...` hook command paths:**
1. `node "/home/drdave/.claude/hooks/gitnexus/gitnexus-hook.cjs"`
2. `node /home/drdave/.claude/hooks/ccg/subagent-context.js`
3. `bash /home/drdave/.claude/hooks/global/bash-log.sh`
4. `node /home/drdave/.claude/hooks/ccg/session-start.js`
5. `node /home/drdave/memory/src/hooks/session-start.mjs`
6. `bash /home/drdave/.claude/hooks/global/stop-notify.sh`
7. `node /home/drdave/memory/src/hooks/session-stop.mjs`
8. `node /home/drdave/.claude/hooks/ccg/workflow-state.js`
9. `node /home/drdave/.claude/hooks/ccg/skill-router.js`
10. `bash /home/drdave/.claude/hooks/global/auto-format.sh`

Policy: user-global hooks belong in `~/.claude/settings.json`, not in tracked umbrella file.
Acceptance: `grep -E '"/home/[^"]+|/Users/[^"]+|C:\\\\[Uu]sers' .claude/settings.json | wc -l` returns `0`.

**G8b — Remove 5 hardcoded plugin marketplace paths:**
1. `/home/drdave/_work/claude-stack/plugins`
2. `/home/drdave/_work/repos/everything-claude-code/.claude-plugin/marketplace.json`
3. `/home/drdave/_work/repos/andrej-karpathy-skills/.claude-plugin/marketplace.json`
4. `/home/drdave/repos/oh-my-claudecode/.claude-plugin/marketplace.json`
5. `/home/drdave/_work/repos/Understand-Anything/.claude-plugin/marketplace.json`

**G8c — Remove `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`** (aspirational; not gating any feature).
Acceptance: `jq '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' .claude/settings.json` returns `null`.

**G7 — `make claude.doctor`** enforces canonical shape via `.claude/settings.canonical.json` with allowlist for `$HOME`/`~/` refs (`.claude/.doctor-allowlist`).

### Phase 4.5 — Reconciliation slice [G3-stray]

Run G3a->G3b->G3c->G3d on each of `repos/{ai-top-utility, fabro, n8n, paperclip}/`. UNSAFE-MISMATCH halts + opens a question (Critic reservation #2 — three of four likely halt).

### Phase 5 — `.codex/config.toml` doctor + allowlist [G9]

`make config.doctor` extends G7 policy to `.codex/`. Allowlist `.codex/.doctor-allowlist`:
```toml
[[allow]]
pattern = "~/.codex/config.toml"
rationale = ".codex/AGENTS.md specifies user-specific MCPs live in ~/.codex/config.toml"
```

### Phase 6 — CI promotion + merge-conflict recipe + Claude/ regression

- **G15-claude-dir** — `find . -maxdepth 6 -type d -name 'Claude' -not -path '*/.git/*'` in `manifest-drift.yml` (REPORT_ONLY -> STRICT).
- **G15-merge-resolve** — `make submodules.materialize-resolve` (auto-resolves `.gitmodules` conflicts).
- **G15-open-questions** — `.omc/plans/open-questions.md` with required fields **Question/Candidates/Blocker for resolution**; lint via `node scripts/open-questions-lint.js`.

---

## 7. ADR

**Decision:** Adopt **Option B (Lockfile pattern with reconciliation slice Phase 4.5)**.

**Drivers:** D1 (n8n preservation), D2 (USER.TODO#5 sequencing), D3 (Claude/.claude CI enforcement).

**Alternatives considered:** A/C/D/E all rejected with cited rationale.

**Why chosen:** Preserves curated metadata; closes P4 seam; supports reversibility; extends naturally to `make config.doctor`.

**Consequences:**
- Operators learn one workflow: `make submodules.add ENTRY=<name>`.
- `.gitmodules` is a generated artifact under version control (lockfile pattern).
- MANIFEST schema gains optional `shallow:` field.
- User-specific hook references move out of tracked `.claude/settings.json` into `~/.claude/settings.json`.
- **Six+ new scripts must be authored** (see Critic reservation #1).

**Follow-ups:** copilot-instructions audit; MANIFEST `# depends-on:` sweep when USER.TODO#5 resolves; STRICT promotion of all CI invariants.

---

## 8. Guardrails

**Must have:**
- READ-ONLY predicate before every destructive op.
- REPORT_ONLY -> STRICT for every CI invariant.
- Named-command acceptance test with expected exit code for every Make target.

**Must NOT have:**
- No raw `git submodule add` (guardrail: `grep -rn 'git submodule add' scripts/ Makefile | grep -v materialize` returns empty).
- No hardcoded user-home paths in tracked config.
- No PascalCase `Claude/` at depth <= 6.
- No silent 404.
- No USER.TODO#5 work in this plan.

---

## 9. Pre-Mortem (6 scenarios with named mitigations)

| # | Scenario | Mitigation |
|---|---|---|
| S1 | Phase 4.5 destroys `repos/n8n/` local work | G3a-d reversibility chain |
| S2 | Origin mismatches MANIFEST upstream | G3a exit 13 + halt + open-question |
| S3 | REPORT_ONLY never promoted to STRICT | `promote-strict.md` checklist |
| S4 | Migration not content-equivalent | G5 `shallow:` schema + I9 diff test |
| S5 | Merge conflict on regenerated `.gitmodules` | `make submodules.materialize-resolve` |
| S6 | `make config.doctor` over-fires on `~/.codex/config.toml` | `.codex/.doctor-allowlist` (hardcoded paths still never allowed) |

---

## 10. Test Plan (15 unit + 9 integration + 6 E2E + observability)

### Unit U1-U15
G3a fixtures (5 exit codes); G3b refusal; G3c refusal; check-user-todo-step5 tagged/untagged; submodule-add-all tagged-404/untagged-404; open-questions-lint field-required.

### Integration I1-I9
`make submodules.materialize` (both directions); `make claude.doctor` (both directions, against POST-TRIM repo file); `make config.doctor` (both directions); `make submodules.add ENTRY=n8n`; `make submodules.materialize-resolve`; content-equivalence diff (S4 check).

### E2E E1-E6
Mutate `.gitmodules` without materialize; add via Make; introduce PascalCase `Claude/`; inject home path in `.claude/settings.json`; concurrent merge conflict; missing open-question field.

### Observability
`MATERIALIZE_DRIFT` count/week; `claude.doctor` failure count; `Claude/` regression count; open-question staleness; allowlist size.

---

## 11. Principle-Violation Audit

| Principle | Violation | Closed by | Verification |
|---|---|---|---|
| P1 | Phantom `claudeFlow.*` keys targeted by earlier v2 | G1+G6 read actual file | I3, I4 |
| P2 | 16 hardcoded paths + env flag | G8a/b/c + G9 doctor + allowlist | U-suite for G8; I3-I6 |
| P3 | No materialize-noop; no Claude/ regression; no claude.doctor | G14, G15-claude-dir, G7 | E1, E3, E4 |
| P4 | `submodule-add-all.sh:72` raw `git submodule add` | Rewrite workflow; `grep` guardrail returns empty | I7, I8, I9 |
| P5 | Phase 4.5 destructive without gates | G3a-d chain | U1-U9, I7 |

---

## 12. Out of Scope (named with rationale)

- Resolving USER.TODO#5 (upstream operator task).
- `.github/copilot-instructions.md` path audit (ADR follow-up).
- Migrating non-stray clones beyond the 4 verified (log to open-questions).
- Toolchain bumps.
- GitHub App refactor.
- No code in `repos/<submodules>/`.
- No edits to `USER.TODO.md` (G11 is read-only).
- No tag/release creation.

---

## 13. Verification Summary Checklist (22 items)

All Make targets, CI invariants, acceptance criteria, and CONTRIBUTING.md additions enumerated with named commands and exit codes. See full v3 planner output in conversation history.

---

## ADR items the user should pay closest attention to before granting execution approval

### Reservation 1 — Six+ new scripts must be authored

Verified absent from `scripts/`:
- `materialize-gitmodules.sh` (the most critical — Option B's pivot point)
- `claude-settings-doctor.js`
- `g3a-can-convert.sh`, `g3b-backup-branch.sh`, `g3c-stash-and-move.sh`
- `reconcile-stray-clones.sh`
- `open-questions-lint.js`

Plan says "reuses existing `materialize-gitmodules.sh`" but the script does not exist. Realistic scope is **moderate engineering project**, not "configuration cleanup". Budget accordingly when granting execution approval.

### Reservation 2 — G3a halt-on-UNSAFE-MISMATCH is operator-blocking by design

Three of four stray clones (`fabro`, `paperclip`, likely `ai-top-utility`) will halt at exit 13 because their origins are not under `FlexNetOS/*`:
- `fabro` origin: `https://github.com/fabro-sh/fabro.git`
- `paperclip` origin: `https://github.com/paperclipai/paperclip.git`

NOTE (correction, 2026-05-28): `ai-top-utility` origin IS `https://github.com/FlexNetOS/ai-top-utility.git` (FlexNetOS-owned, no upstream) — it will NOT halt at exit 13. See `data/brain-data/research/ai-top-utility.md`. Only `fabro` and `paperclip` are true UNSAFE-MISMATCH cases.

The operator must triage each open-question manually before reconciliation can complete. This cannot be automated without violating P5 (reversibility before destruction). Plan ahead for that triage session.

---

## Consensus loop record

| Iteration | Verdict | Notes |
|---|---|---|
| Planner v1 | (initial) | Option A (path-prefix partition); v1 Option B was a strawman. |
| Architect | REVISE BEFORE CRITIC | Two significant principle violations: P2 (.claude/settings.json hidden state), P4 (Option A partition). |
| Planner v2 | (revised) | Flipped to principled Option B (lockfile); decomposed G3; reclassified G8; added G17. |
| Critic v1 | ITERATE | Five required revisions including G8 phantom-key correction. |
| Planner v3 | (revised) | All 5 items closed with verified empirical evidence. |
| Critic v2 | **APPROVE** | Reservations are advisory (script-authoring scope; operator triage burden). |

---

**End of plan. Status: pending approval.** No execution has occurred. To execute via parallel team, invoke `/oh-my-claudecode:team`. To execute sequentially with verification, invoke `/oh-my-claudecode:ralph`. To request changes, reply with the section + concern.
