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

## SESSION-2026-05-28-004 — ralplan browser-choice (v1→v5 six-layer architecture) + branch-guard hard rule (later wiped)

> **Renumbered from -003 to -004 post-hoc:** a concurrent agent (line 11, "Restore accidentally-removed session files") also claimed `SESSION-2026-05-28-003` while this wrap-up was in progress. Per wrap-up rule "Don't reuse a session ID", this entry was bumped to -004. All UA items below (`UA-2026-05-28-002` through `-004`) were originally surfaced by -003 in this session's writes; cross-references should be read as "surfaced by what is now -004" — see the UA item Surfaced-by fields.

- **ID:** `SESSION-2026-05-28-004`
- **Date:** 2026-05-28
- **Branch:** `feat/restore-session-convention-files`
- **HEAD at start of wrap-up:** `3dd0ef4` (the commit this session produced for the v5 plan + install script)
- **HEAD at end:** `6ab5599` (4 commits landed during wrap-up by the concurrent agent: `71fdaa6`, `2061a8f`, `ee1c15f`, `6ab5599` — none from this session)
- **Mode:** `/ralplan` (consensus, 5 iterations) → `/oh-my-claudecode:team` (loaded, NOT spawned — cost gate held) → manual recreation after concurrent branch rewrite destroyed first writes → `/wrap-up`
- **Outcome:** v5 six-layer Linux workstation plan committed at `3dd0ef4` (misfiled at `.omc/plans/`; canonical path is `data/brain-data/research/`). Install script committed. Global branch-guard hard-rule hook installed at `~/.claude/`. Three UA items surfaced including a critical key-rotation gate.
- **User-action gates surfaced:** `UA-2026-05-28-002`, `UA-2026-05-28-003`, `UA-2026-05-28-004`.
- **Cost:** session crossed $200; critical-cost hook fired multiple times. Proceeded under explicit per-step user approval (cheapest-path option chosen at each cost gate). User said "everything not committed is gone" mid-session; recreated files from transcript and committed.

### What the user asked
> "/ralplan"
> (initial invocation; no args. Follow-up clarification: "we need to choice one browser that serves all purpose. Playwrite does not work well with chrome | firefox does not have the same extention for claude | Brave is new trend | what do we choose")

Scope expanded mid-session to include: Slim (port unification), Pi-hole + dnscrypt-proxy + Cloudflare/Quad9 (network DNS), vproxy (outbound proxy), trippy (diagnostic). Then user requested a hard rule that all session work must start on a feature branch. Then `/wrap-up`.

### What the answer is

**Browser/architecture question:** "pick one browser" is the wrong frame. The right answer is a **six-layer workstation architecture** that decouples daily browsing from Claude access from Playwright automation:

| Layer | Tool | Purpose |
|---|---|---|
| -2 | Pi-hole + dnscrypt-proxy + Cloudflare/Quad9 | network DNS (encrypted, filtered, cached) |
| -1 | vproxy | outbound forward proxy (opt-in per service) |
|  0 | Slim | local DNS + HTTPS reverse proxy for `*.test` |
|  1 | Firefox | daily browser (Linux-first-class) |
|  2 | Bifrost (Docker) | OpenAI-compatible LLM gateway (Anthropic + OpenRouter) |
|  3 | Obscura | Playwright automation (with bundled Chromium fallback) |

Plus trippy as a network-diagnostic sidecar and RTK already system-wide. Plan committed at `3dd0ef4` (currently `.omc/plans/ralplan-browser-choice.md`, must move per convention — see `UA-2026-05-28-003`). Install script at `scripts/install-v5-architecture.sh` is ready but unrun; requires `~/bifrost/.env` + `~/pihole/pihole_password.txt` + `~/vproxy/.env` (all chmod 600, written this session).

**Branch-rule question:** installed `~/.claude/hooks/branch-guard.sh` as a global hard rule. SessionStart warns; PreToolUse blocks Write/Edit on source files when on `main`/`master`/`trunk`. Exempts `.claude/`, `.omc/`, `.github/`, `CLAUDE.md`, `AGENTS.md`, `docs/**/*.md`. Per-repo allowlist + override supported; session bypass via `BRANCH_GUARD_OFF=1`.

### What was actually done this session

1. **Ralplan v1**: Planner picked Edge + Playwright's bundled chromium. Architect challenged with Brave + Chrome for Testing synthesis. Critic ITERATE-voted on 10 specific revisions.
2. **Ralplan v2**: Planner applied all 10 Critic revisions, kept Edge pick. Architect retracted CfT claim, accepted Edge as motivated. Critic APPROVED.
3. **Ralplan v3**: User hard-constraint flip ("main OS is linux so edge is a problem") — recommendation swapped to Brave; plan rewritten in place.
4. **Ralplan v4**: User rejected Brave and Edge; pointed at 7 reference repos (`obscura`, `slim`, `FreeDomain`, `bifrost`, `vproxy`, `devolutions-gateway`, `freellmapi`). Researched each via `gh api`. Reframed as three-layer architecture (Firefox + bifrost + obscura). Plan completely rewritten.
5. **Ralplan v4.1**: User added Slim ("we have way too many ports"). Plan extended with Layer 0.
6. **Ralplan v5**: User asked about reverse-proxy / proxy / DNS coverage. Added Layer -2 (Pi-hole + dnscrypt-proxy, NextDNS dropped per user direction for Cloudflare/Quad9), Layer -1 (vproxy promoted from follow-up to recommended), and trippy + RTK acknowledgement.
7. **Secrets written to `$HOME`** (chmod 600): `~/bifrost/.env` (user pasted Anthropic + OpenRouter API keys directly into chat — keys now compromised), `~/pihole/pihole_password.txt` (random 24-char), `~/vproxy/.env` (random password). All have `.gitignore` next to them.
8. **`/team` skill loaded** but NOT spawned — cost gate held at user's request after honest cost-trajectory estimate.
9. **Branch catastrophe**: user said "commit everything"; discovered the plan file + install script were not on disk; reflog + `git fsck --lost-found` found 148 dangling blobs but none contained the v5 plan or script content. Files had been destroyed by a concurrent cherry-pick / branch-delete workflow running mid-session. User chose "recreate from transcript".
10. **Recreated** `.omc/plans/ralplan-browser-choice.md` (588 lines) and `scripts/install-v5-architecture.sh` (388 lines, bash -n clean, chmod +x). Committed as `3dd0ef4 plan: v5 workstation architecture + install script` on `main` (working tree was on `main` at that moment).
11. **Branch-guard hard rule** installed: `~/.claude/hooks/branch-guard.sh` (executable, 4.2K, 5/5 smoke tests passed) + two hook entries appended via `jq` to `~/.claude/settings.json` (matchers `startup|resume|clear|compact` and `Edit|Write|MultiEdit`) + new "Hard rule" section in `~/.claude/CLAUDE.md` near the top.
12. **Wrap-up**: user removed the phantom registration that had been blocking the wrap-up skill from loading; skill loaded; this entry written.

### Reservations / risks
- **API keys leaked in chat transcript.** `UA-2026-05-28-002` — rotate before any production use.
- **Plan misfiled.** `UA-2026-05-28-003` — `.omc/plans/` violates the `feedback-research-location` convention; must move to `data/brain-data/research/`.
- **`3dd0ef4` first landed on `main`.** `UA-2026-05-28-004` — would now be blocked by the branch-guard rule. Maintainer decides whether to reset `main` or accept as a one-time pre-rule exception.
- **No execution of the v5 install script.** Plan is `pending approval`; `scripts/install-v5-architecture.sh` is ready but unrun. Will prompt for sudo when run.
- **No commits to anything outside this session's two files** in this repo. The branch-guard hook install is at `~/.claude/`, not under the repo tree.
- **No push.** Nothing was pushed to a remote in this session.
- **No `gh repo fork`.** None performed.
- **TODO.md and CHANGELOG.md were modified concurrently** by another agent/hook during wrap-up. TODO.md was skipped to avoid clobber; CHANGELOG.md was appended-only under new dated SESSION-003 subsections to preserve the concurrent body of work.

### User-action gates (3 items, all from this session)
- `UA-2026-05-28-002` — Rotate Anthropic + OpenRouter API keys IMMEDIATELY (chat-transcript leak). Blocks safe operation of `~/bifrost/.env` and any LLM-gateway smoke test.
- `UA-2026-05-28-003` — Move `.omc/plans/ralplan-browser-choice.md` → `data/brain-data/research/v5-workstation-architecture.md`. Blocks convention compliance.
- `UA-2026-05-28-004` — Decide whether `3dd0ef4` should remain on `main` or only on this feature branch. Blocks clean branch history.

### What's next
1. **You (manual):** rotate keys (`UA-002`), move plan file (`UA-003`), decide on `main` history (`UA-004`).
2. After `UA-002` is done: review `scripts/install-v5-architecture.sh --dry-run`; when satisfied, run it (the install will prompt for sudo for apt + Docker and to swap `/etc/resolv.conf`; safe abort if Pi-hole doesn't respond before the swap).
3. **Next agent session:** the new branch-guard hook will fire `[BRANCH GUARD]` at SessionStart when HEAD is `main`. Open a feature branch before any Edit/Write.

### Files created/modified this session

| Path | What |
|---|---|
| `.omc/plans/ralplan-browser-choice.md` | v5 plan (588 lines). Committed `3dd0ef4`. **Must move per convention — `UA-2026-05-28-003`.** |
| `scripts/install-v5-architecture.sh` | 7-phase install script (388 lines, exec, bash -n clean). Committed `3dd0ef4`. |
| `~/bifrost/.env` | chmod 600, holds Anthropic + OpenRouter API keys (**ROTATE — `UA-2026-05-28-002`**) |
| `~/pihole/pihole_password.txt` | chmod 600, 24-char random admin password |
| `~/vproxy/.env` | chmod 600, `VPROXY_USER`/`VPROXY_PASS`/`VPROXY_BIND` |
| `~/bifrost/.gitignore`, `~/pihole/.gitignore`, `~/vproxy/.gitignore` | guard against accidental git inclusion if those dirs become repos later |
| `~/.claude/hooks/branch-guard.sh` | new global hook (4.2K, exec, 5/5 smoke tests passed) |
| `~/.claude/settings.json` | two new hook entries appended via jq (SessionStart + PreToolUse:Edit\|Write\|MultiEdit) |
| `~/.claude/settings.json.bak-pre-branch-guard-20260528-135800` | backup before settings edit |
| `~/.claude/CLAUDE.md` | new "## Hard rule: open a feature branch BEFORE any session work" section near the top |
| `USER.TODO.md` | appended `UA-2026-05-28-002` / `-003` / `-004` to `## Agent-flagged user actions`. Numbered sections untouched. |
| `CHANGELOG.md` | appended `### Added (SESSION-2026-05-28-003)`, `### Decisions recorded (...)`, `### Notes (...)` blocks under `[Unreleased]`. |
| `SESSIONS.md` | this entry. |
| `TODO.md` | **NOT modified** by this wrap-up (concurrent agent/hook activity detected; skipped to avoid clobber). |

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
