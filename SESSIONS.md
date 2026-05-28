# SESSIONS — session log

> Per-session wrap-ups for `my-github`. Newest first. Each entry has a session ID
> (`SESSION-YYYY-MM-DD-NNN`), reference code/artifacts, and location. Older
> summaries can be rotated to `data/brain-data/research/sessions/` if length
> becomes an issue. Cross-reference live work in `TODO.md` and applied changes
> in `CHANGELOG.md`.

---

## SESSION-2026-05-28-003 — Restore accidentally-removed session files

**Branch:** `feat/restore-session-wrapup-files`
**Triggered by:** *"All files were accidentally removed. Create a new feature branch and recreate every file then /verify them, commit and create PR."*
**Location:** `/home/drdave/workspace/my-github`

### What we did

1. **Assessed the loss.** `TODO.md`, `CHANGELOG.md`, `SESSIONS.md`, and the 5 research files (`ai-top-utility.md`, `n8n.md`, `fabro.md`, `paperclip.md`, `my-github-reconciliation.md`) were gone. `repomix.md` and all cross-session memory survived. Confirmed via git that the lost files were never committed (untracked working-tree files) — unrecoverable from git, so reconstructed from conversation context.
2. **Created restore branch** `feat/restore-session-wrapup-files`.
3. **Recreated all 8 files** faithful to their last-good state:
   - 4 pre-adoption dossiers + the reconciliation plan -> `data/brain-data/research/`
   - `TODO.md`, `CHANGELOG.md`, `SESSIONS.md` -> repo root
4. **Verified, committed, and opened a PR** so the files are durable (this is exactly the loss the `feedback-always-commit` memory warns about).

### Reference code / artifacts

- Recreated: `TODO.md`, `CHANGELOG.md`, `SESSIONS.md`, `data/brain-data/research/{ai-top-utility,n8n,fabro,paperclip,my-github-reconciliation}.md`
- Companion plan: `~/.claude/plans/sprightly-shimmying-charm.md`
- Survived (not recreated): `data/brain-data/research/repomix.md`, all `~/.claude/projects/.../memory/*.md`

### Deferred to next session

See `TODO.md` — Phase 0 dossier review gate, Phase A adoption (gated), Phase B/C/D per-fork setup, Phase E umbrella state fixes, broader 17-gap reconciliation items.

---

## SESSION-2026-05-28-002 — Pre-adoption research for the 4 fresh clones

**Branch:** `feat/github-app-automation`
**Triggered by:** `/ecc:research-ops` — audit umbrella + design adoption playbook for the four clones at `repos/{ai-top-utility,fabro,n8n,paperclip}/`.
**Companion plan:** `~/.claude/plans/sprightly-shimmying-charm.md`
**Builds on:** SESSION-2026-05-28-001 below (which produced `my-github-reconciliation.md`).

### What we did

1. **Audited the umbrella.** Confirmed `docs/fork-workflow.md` already specifies `main`/`master` <-> upstream and `develop` <-> FlexNetOS; submodule machinery already exists; reusable workflows already exist; rebrand machinery does NOT exist.
2. **Resolved a doc/code conflict:** `docs/directory-layout.md` describes a retired sibling-checkout pattern incompatible with the MANIFEST-based submodule layout. User confirmed **Model B** is authoritative; `directory-layout.md` queued for rewrite.
3. **Captured the umbrella vision.** my-github is a FlexNetOS umbrella, not a community-defaults `.github` repo. Each submodule shares the umbrella's `.github` pipe with per-repo modifications; goal is single-clone-then-go with no host-side installs / env tweaks.
4. **Codified the research-before-fork hard rule** after the ruflu/ruvector incident. Saved as cross-session memory.
5. **Wrote 4 per-clone dossiers** at `data/brain-data/research/`. Each has identity, purpose, stack, intent, pre-adoption audit, adoption plan, sync risk, verification, and a section 9 open-decisions checklist gating irreversible actions.
6. **Corrected one error** in `my-github-reconciliation.md`: `ai-top-utility` is FlexNetOS-owned (not UNSAFE-MISMATCH).

### What we learned

- The 4 clones decompose into 3 distinct adoption cases, not 1: owned-no-upstream (`ai-top-utility`), already-forked (`n8n`), needs-fork (`fabro` + `paperclip`).
- When the user flags a doc/code conflict as "major," weight their judgment over an advisor framing that minimizes it.

---

## SESSION-2026-05-28-001 — deep research + ralplan consensus on VISION/PLAN/USER.TODO gaps + Claude/.claude directory question

**Branch:** `feat/github-app-automation`
**Mode:** `/ralplan` (consensus planning, deliberate mode)
**Outcome:** APPROVED at iteration 3. Plan saved to `data/brain-data/research/my-github-reconciliation.md`. Status: `pending approval`. No execution authorized.

### What the user asked
> "Run deep research on the repo vision, plan, and TODO.md — what is missing? where are the gaps? Claude expects '.claude' and 'Claude' director — that means 2 separate submodules '.claude' & 'Claude'."

Plus convention follow-up: `TODO.md` / `CHANGELOG.md` / `SESSIONS.md` at root; research in `data/brain-data/research/`; never fork before originals are properly set up.

### What the answer is

**On the directory question:** Use `.claude/` (lowercase, dotted) only. There is no `Claude/` (PascalCase) directory and no two-submodule scheme. `find ... -name 'Claude'` returns zero matches. Likely confusion with Claude Desktop's macOS `~/Library/Application Support/Claude/`. Do NOT create a `Claude/` submodule.

**On VISION/PLAN/USER.TODO gaps (17 gaps):** Full ralplan consensus output lives at `data/brain-data/research/my-github-reconciliation.md`. Headline gaps: MANIFEST<->.gitmodules schism; missing `scripts/materialize-gitmodules.sh`; 437-line `.claude/settings.json` with 16 hardcoded paths; raw `git submodule add` seam; no `# depends-on:` tags; 4 untracked clones in `repos/`; no root tracking trio (now created).

### Reservations the Critic flagged

1. **6+ new scripts must be written** — realistic scope is moderate engineering, not config cleanup.
2. **Stray clones halt at G3a exit 13 (UNSAFE-MISMATCH)** by design — `fabro`, `paperclip` (corrected: not `ai-top-utility`). Requires per-clone operator triage.
