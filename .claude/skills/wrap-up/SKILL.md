---
name: wrap-up
description: Wrap up the current working session in the FlexNetOS umbrella repo. Updates TODO.md with remaining agent work, appends user-action items to USER.TODO.md when the model needs the human to do something, appends applied changes to CHANGELOG.md, and writes a session entry with a proper session ID to SESSIONS.md. Use when the user says "/wrap-up", "wrap up", "wrap-up", "end session", "session done", "let's stop here", or before a long context compaction.
---

# wrap-up

End-of-session bookkeeping for `/home/drdave/workspace/my-github` (FlexNetOS/.github umbrella). Four repo-root files, one durable session record. Run on every meaningful work session so the next session (or the next operator) picks up cold without losing context.

> Convention source: `~/.claude/projects/-home-drdave-workspace-my-github/memory/feedback-research-location.md`. This skill is the executor for that convention — don't drift from it. The file the convention memory originally called `SESSION.md` has been renamed to `SESSIONS.md` on disk (plural). The on-disk filename wins.

## The four files (repo root)

| File | Purpose | What goes in it | Who writes |
|---|---|---|---|
| `TODO.md` | **Forward-looking** working list of changes the **agent** still needs to do. | Unchecked items the next session must do. Cleared items move out (deleted or rolled into CHANGELOG). | Agent (`/wrap-up` and other sessions) |
| `USER.TODO.md` | **Human-action checklist** — steps only the user can perform (auth, push, fork, billing, ops decisions). | Numbered `## N. <headline>` sections with `**Why:**`, plus an `## Agent-flagged user actions` section appended by this skill when the agent surfaces a new must-do-by-human item. | Primarily the user; this skill **appends only to the dedicated `Agent-flagged user actions` section**. |
| `CHANGELOG.md` | **Applied** changes. Keep-a-Changelog format under `[Unreleased]`. | Files created, decisions recorded, corrections made. Use `Added / Changed / Removed / Decisions recorded / Notes` subsections. Reference TODO items as `(TODO: <name>)` and research artifacts as `(research: <slug>)`. | Agent |
| `SESSIONS.md` | **Most-recent-first** narrative log of each session, each with a unique session ID. | One `## SESSION-YYYY-MM-DD-NNN` section at the top with the structured header + body sections defined below. | Agent |

Research artifacts (deep-research outputs, ralplan deliverables, gap analyses) do **NOT** live in `SESSIONS.md` — they go to `data/brain-data/research/<slug>.md` and `SESSIONS.md` links to them.

## When to run

- User explicitly invokes `/wrap-up` or says "wrap up" / "end session" / "let's stop here".
- Before a `/clear` or expected context compaction, if substantive work was done.
- Before handing off to another model/operator.
- After landing a major artifact (research doc approved, plan finalized, branch ready to push).
- When the session produced a **user-blocking gate** (need a push, need a token, need a paid setting toggled) — even if other work is incomplete, surface the gate via `USER.TODO.md` before the session ends.

**Don't run** if the session did nothing meaningful (orientation only, single-question lookup, no files touched, no decisions made). An empty session entry is noise.

## Session ID format (authoritative)

Every `SESSIONS.md` entry MUST start with a session ID. The format is:

```
SESSION-YYYY-MM-DD-NNN
```

Where:

- `YYYY-MM-DD` — ISO 8601 date, **the day the session is being wrapped up**, taken from `Bash: date +%F`. Do not guess.
- `NNN` — zero-padded 3-digit sequence number for that day. Starts at `001` and increments per session that day.

Compute `NNN` like this:

```bash
TODAY=$(date +%F)
COUNT=$(grep -cE "^## SESSION-${TODAY}-[0-9]{3}" SESSIONS.md 2>/dev/null || echo 0)
NEXT=$(printf '%03d' $((COUNT + 1)))
SESSION_ID="SESSION-${TODAY}-${NEXT}"
echo "$SESSION_ID"
```

Properties this format gives you:

- **Lexicographically sortable** — `sort` on the IDs yields chronological order.
- **Stable** — does not depend on wall-clock time-of-day or timezone.
- **Human-readable** — operator can refer to "session 002 today" verbally.
- **Greppable** — `grep '^## SESSION-2026-05-28-' SESSIONS.md` lists all entries for a day.
- **Cross-referenceable** — CHANGELOG and TODO can tag entries with `(SESSION-2026-05-28-001)`.

Pre-rename legacy entries (anything before this skill landed) use the older `## YYYY-MM-DD — <headline>` shape with no ID. Do not retroactively rewrite them; just start new entries in the new format above any legacy entries.

## SESSIONS.md entry format (authoritative)

A complete entry looks like this. Drop subsections that are genuinely empty; do not pad.

```markdown
---

## SESSION-YYYY-MM-DD-NNN — <short headline of what this session was>

- **ID:** `SESSION-YYYY-MM-DD-NNN`
- **Date:** YYYY-MM-DD
- **Started:** HH:MM <tz>  *(optional; include if known)*
- **Ended:** HH:MM <tz>    *(optional; include if known)*
- **Branch:** `<git rev-parse --abbrev-ref HEAD output>`
- **HEAD at end:** `<git rev-parse --short HEAD output>`
- **Mode:** `<skill/workflow used — e.g. /ralplan, /autopilot, /wrap-up, manual>`
- **Outcome:** <one-line landing state>
- **User-action gates surfaced:** `<list of USER.TODO.md item IDs added this session, or "none">`
- **Cost:** $X.XX *(optional; include only if unusual — Opus loops, multi-agent runs)*

### What the user asked
> "<the user's literal opening prompt, verbatim where feasible>"

<one or two sentences of follow-up context only if scope expanded mid-session>

### What the answer is
<headline finding(s). Bullets allowed. Link the durable artifact: `data/brain-data/research/<slug>.md` or the relevant `CHANGELOG.md` entry. This subsection answers "what does the next operator need to know in 30 seconds?"
>

### What was actually done this session
1. <ordered, factual list — what was read, what was decided, what was written>
2. ...

### Reservations / risks
- <anything the critic/reviewer/verifier flagged that the next session should read first>
- <explicit negative gates: "no `gh repo fork` calls were made", "no submodule mutations", "no git commits", "no host-side installs", etc.>

### User-action gates (if any)
- <reference each item the agent appended to `USER.TODO.md` § Agent-flagged user actions, by ID>
  - e.g. `UA-2026-05-28-001 — push origin feat/github-app-automation (blocks: G3a, G14)`

### What's next
<the menu of next moves — `/team`, `/ralph`, manual triage, pause, etc. Be honest if it's "pause; nothing actionable until the user does UA-…">

### Files created/modified this session

| Path | What |
|---|---|
| `<path>` | <one-line description> |
| ... | ... |
```

Hard rules for the entry:

- **Date with `Bash: date +%F`**, not from memory. Compute branch / HEAD with `Bash: git rev-parse --abbrev-ref HEAD` and `git rev-parse --short HEAD`.
- **Quote the user's literal opening prompt** under "What the user asked" (use `> "..."`). Paraphrases drift across sessions; the literal prompt is durable evidence of intent.
- **List files honestly** — every path created or modified, plus auto-memories written under `~/.claude/projects/-home-drdave-workspace-my-github/memory/`. Hook-synthesized memories count too; mark them `(created by hook, not by me)`.
- **State negative gates explicitly** in Reservations — they tell the next session what state the branch is *not* in.
- **Length matches the work** — short session, short entry. Don't pad.

## Procedure

Work top-to-bottom. Each step is independent — skip a step only if there is genuinely nothing to record for it, and say so out loud rather than silently skipping.

### 1. Take inventory

Reconstruct what happened this session. Look at the conversation history, the tool calls you made, and the git working tree. Answer these for yourself:

- What did the user originally ask for? (Capture the literal prompt for the SESSIONS entry.)
- What was decided or produced? (Answer → research artifact path → plan status.)
- What files were created or modified? (`git status` and `git diff --stat`; check `~/.claude/projects/-home-drdave-workspace-my-github/memory/` for new memories.)
- What's left undone for the agent? → goes to `TODO.md`.
- What's left undone for the human? → goes to `USER.TODO.md § Agent-flagged user actions`.
- What did you learn that's worth recording as a permanent project decision? → goes to `CHANGELOG.md § Decisions recorded`.

If `git status` shows untracked or modified files you don't recognize, investigate before treating them as "yours" — they may be the user's in-progress work.

Compute the session ID now (see the format section above) — you'll need it for cross-references.

### 2. Update `TODO.md` (agent work only)

Open `/home/drdave/workspace/my-github/TODO.md` and edit in place. The file is grouped by topic with `- [ ]` checkboxes — preserve that shape.

- **Mark completed items** by deleting them. Do not leave checked `- [x]` lines; closed items belong in `CHANGELOG.md`.
- **Add new items** discovered this session under the right topical heading. Create a new heading if none fits.
- **Update "Last updated"** line at the top with `Bash: date +%F`.
- **Update "Status"** line if the plan moved between states (`pending approval` → `approved` → `in progress` → `complete`).
- If an item is now blocked or deferred, leave it but add a sub-bullet `- blocked by: <SESSION-id or UA-id>` or `- deferred: <reason>` so the next session knows.

If nothing changed, just bump "Last updated" and note "no TODO changes" in your wrap-up report.

### 3. Append to `USER.TODO.md` only when the model needs the human

`USER.TODO.md` is primarily the user's hand-authored, numbered checklist (`## 1. Push the initial scaffold`, etc.). **Do not edit, renumber, or reorder the user's existing sections.**

When the session surfaces a step that ONLY the user can do (push to a remote you don't have credentials for, run `gh repo fork` on a fork that's gated behind dossier review, pay for a thing, decide a policy question, sign a token), append it to a dedicated section at the **end** of the file:

```markdown
---

## Agent-flagged user actions

> Items added by `/wrap-up`. The numbered `## N.` sections above are the user's
> hand-authored canonical list — agents must not edit those. New agent-
> surfaced items go here, append-only.

### UA-YYYY-MM-DD-NNN — <short headline>

- **Surfaced by:** `SESSION-YYYY-MM-DD-NNN`
- **Blocks:** <list of TODO.md items, gate IDs, or research recommendations that cannot proceed until this is done>
- **Why:** <one-paragraph explanation: what the agent tried, why it can't finish it, what the human-only constraint is>
- **What to do:** <concrete steps — exact commands when possible>
- **How to verify done:** <observable check the agent (or human) can run to confirm completion — e.g. `git ls-remote origin <branch>` returns a sha>
- **Status:** `open`
```

Rules:

- **`UA-` ID format:** `UA-YYYY-MM-DD-NNN`, same date-and-counter shape as session IDs, scoped to the `Agent-flagged user actions` section. Compute NNN with: `grep -cE "^### UA-${TODAY}-[0-9]{3}" USER.TODO.md` + 1.
- **Append-only.** Never delete or rewrite an existing `UA-` item. If a future session sees the item is done, **update its `Status:` line** to `done (<SESSION-id>)` and add a one-line confirmation; leave the rest in place for audit.
- **Never touch the numbered `## N.` sections above.** Those are the human's.
- **If the `## Agent-flagged user actions` heading doesn't exist yet**, create it at the very end of the file (after the last existing `## N.` section), using the template above.
- **If no user action is needed this session, do not touch `USER.TODO.md` at all.** The skill is conditional.
- **Cross-reference both directions:** the SESSIONS.md entry lists every `UA-` ID created; each `UA-` item names the `SESSION-` ID that surfaced it.

### 4. Append to `CHANGELOG.md`

Open `/home/drdave/workspace/my-github/CHANGELOG.md`. Entries land under `[Unreleased]` (pre-`v1.0.0` convention).

Add concise entries under the appropriate subsection:

- **Added** — new files, new sections in existing docs, new scripts, new memories.
- **Changed** — modifications to existing config/code/docs (one-line *what changed* and *why*).
- **Removed** — files deleted, sections cut, deprecations.
- **Decisions recorded (YYYY-MM-DD)** — permanent project decisions this session. Date the subsection heading.
- **Corrections to prior work (YYYY-MM-DD)** — when this session overturned something a previous session got wrong.
- **Notes** — caveats, things explicitly *not* done, gate states.

Cross-reference conventions:

- TODO item closed → tag `(TODO: <short-name>)`.
- Implements a research recommendation → tag `(research: <slug>)`.
- Originates in or implements a session → tag `(SESSION-YYYY-MM-DD-NNN)`.
- Unblocks a user action → tag `(unblocks: UA-YYYY-MM-DD-NNN)`.
- Date format → ISO 8601 (`YYYY-MM-DD`).

If nothing was *applied* (plan still `pending approval`, no code changed, no decisions finalized), say so explicitly in the **Notes** subsection — don't fabricate `Added`/`Changed` entries.

### 5. Write the session entry to `SESSIONS.md`

Open `/home/drdave/workspace/my-github/SESSIONS.md`. The file is **most-recent-first** — the new entry goes directly under the header intro, above all older entries.

Use the SESSIONS.md entry format defined above. Required up-front, before you start typing:

- `Bash: date +%F` → date.
- `Bash: git rev-parse --abbrev-ref HEAD` → branch name.
- `Bash: git rev-parse --short HEAD` → HEAD short SHA at session end.
- Computed session ID (see procedure above).
- List of `UA-` IDs added to USER.TODO.md this session (may be empty).

### 6. Verify with the wrap-up-verifier subagent (mandatory)

After the four-file writes are complete and before you report "done" to the
user, **delegate to the `wrap-up-verifier` project subagent** for an
honest, evidence-backed check. This is non-optional — it catches bluffing,
gaps, format-rule violations, broken cross-references, and silent USER.TODO
edits that would otherwise leak through.

How to invoke (from the main agent context, after step 5):

```
Agent(
  description: "Verify wrap-up SESSION-<id>",
  subagent_type: "wrap-up-verifier",
  prompt: "Verify the wrap-up just completed at session ID
           SESSION-YYYY-MM-DD-NNN. Project root is
           /home/drdave/workspace/my-github. Run the full S1–S14 +
           H1–H10 procedure defined in your agent prompt. Emit the
           verdict report exactly in the structure documented there."
)
```

(`wrap-up-verifier` is defined at `.claude/agents/wrap-up-verifier.md` —
read-only, Sonnet, no Write/Edit. It re-derives ground truth from
`git status`, `git diff`, and the four files. It does not depend on the
main agent's narrative.)

The verifier returns one of three verdicts:

- **PASS** — wrap-up is complete and honest. Proceed to the user-facing
  report below.
- **PASS WITH WARNINGS** — wrap-up is acceptable; surface the warnings
  in your user-facing report so the user can decide whether they care.
- **FAIL** — wrap-up has one or more critical defects (each cited with
  file:line evidence). You **must** fix every critical issue, re-run the
  affected wrap-up step(s), and re-invoke the verifier. Do not report
  "done" to the user while a FAIL is outstanding.

Cheap-and-fast prechecks before you delegate (optional, but they let you
catch the obvious issues without spending an agent call):

- `Bash: ls -la TODO.md USER.TODO.md CHANGELOG.md SESSIONS.md` — files
  present, recent mtimes. `USER.TODO.md` only if step 3 actually
  modified it.
- `Bash: head -25 SESSIONS.md` — confirm the new entry is at the top with
  the computed `SESSION-` ID and today's date.
- `Bash: git status --short` — confirm only the intended files are dirty.
- `Bash: grep -c "^## SESSION-$(date +%F)-" SESSIONS.md` — sanity-check
  the counter incremented correctly.

If any precheck obviously fails, fix it before invoking the verifier; the
verifier will just FAIL on the same issue and you'll have spent an extra
agent call.

### 7. Report to the user

Only after the verifier returns **PASS** or **PASS WITH WARNINGS**, output
a short report to the user:

1. **Session ID** just created.
2. **Verifier verdict** (`PASS` / `PASS WITH WARNINGS`) — name it explicitly.
   If `PASS WITH WARNINGS`, list each warning in one line.
3. The files touched and one-line of what changed in each.
4. Any `UA-` item IDs surfaced — explicitly call these out so the user sees
   them.
5. The "What's next" line, repeated from `SESSIONS.md`.
6. Any flag worth raising — e.g. "branch has unrelated dirty files: X, Y,"
   or "auto-memory wrote feedback-foo.md, review if you don't want it kept."

Never report "done" while the verifier returned FAIL. If the verifier keeps
returning FAIL on the same issue and you can't reconcile it, surface the
verifier's report verbatim to the user and ask them to adjudicate — do not
silently soften the verdict.

## Done-when

You are done when **all** of these are true:

1. `TODO.md` reflects current agent-side state (no stale completed items, new gaps added, "Last updated" bumped).
2. `USER.TODO.md` is either **untouched** (no user action needed) or **appended-only** under `## Agent-flagged user actions` with one or more `UA-` items. The numbered `## N.` sections are byte-identical to before.
3. `CHANGELOG.md` has new entries under `[Unreleased]` *or* an explicit "no changes applied" note for the session.
4. `SESSIONS.md` has a new entry at the top with a valid `SESSION-YYYY-MM-DD-NNN` ID, today's date, current branch + HEAD, the user's literal ask quoted, files-modified table, and explicit negative-gate notes.
5. `git status --short` shows only the intended changes.
6. **No commit, no push** — wrap-up writes durable docs; git state changes are a separate decision.
7. **The `wrap-up-verifier` subagent returned `PASS` or `PASS WITH WARNINGS`** (not `FAIL`) for this session ID. Any FAIL outcome — even a single critical issue — means you are not done; fix and re-verify.

## Do-not list

- **Don't edit the user's numbered `## N.` sections in `USER.TODO.md`.** Read-only above the `## Agent-flagged user actions` heading; append-only below it.
- **Don't write research artifacts inline in SESSIONS.md** — they go to `data/brain-data/research/<slug>.md`. SESSIONS.md links to them, doesn't contain them.
- **Don't auto-commit or push.**
- **Don't `git clean` or `git reset`.** If `git status` looks wrong, surface it; don't fix it.
- **Don't paraphrase the user's ask** when the original prompt is available verbatim. Drift compounds across sessions.
- **Don't pad.** Empty subsections delete; "no X" notes are fine. A 40-line entry beats a 400-line entry of restated context.
- **Don't reuse a session ID.** If you mis-counted and grep shows a collision, increment until unique. IDs are immutable once written.
- **Don't retroactively rewrite legacy session entries** that pre-date this skill — leave the pre-rename `## YYYY-MM-DD — ...` headings alone, just add new entries above them in the new format.
- **Don't write to `SESSION.md` (singular).** The file was renamed to `SESSIONS.md` (plural) on 2026-05-28. If you find a stale `SESSION.md` recreated by some other tool, surface it; do not silently merge or overwrite.

## Aliases this skill answers to

The frontmatter `description` already covers the auto-load triggers. For human reference, these all mean "run this skill":

- `/wrap-up`
- "wrap up", "wrap-up", "wrap up the session"
- "end session", "session done", "let's stop here", "stop for the day"
- "summarize the session and update the trackers"
- "update SESSIONS.md and TODO.md"

## Related

- `~/.claude/projects/-home-drdave-workspace-my-github/memory/feedback-research-location.md` — the convention this skill enforces.
- `~/.claude/projects/-home-drdave-workspace-my-github/memory/my-github-umbrella-model.md` — Model B umbrella structure context.
- `data/brain-data/research/` — where deep-research artifacts go (referenced from SESSIONS.md, not embedded).
- `USER.TODO.md § Agent-flagged user actions` — the only place this skill writes inside that file.
- `.claude/agents/wrap-up-verifier.md` — the read-only verifier subagent invoked in step 6.
