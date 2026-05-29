---
name: clone-setup
description: Full research-before-fork ritual. Runs make research.pack, reads the actual source code (not just README/QUICKSTART), fills the dossier at data/brain-data/research/<name>.md with code-verified findings, then runs verified setup in the work clone. Mandatory before any gh repo fork. Code beats docs.
---

# clone-setup

Executes the umbrella's three-phase "Step 0 → 1 → 2" sequence for adopting a new upstream repo:

**Pack → Deep Research (code beats docs) → Verified Setup**

Research is always saved to `data/brain-data/research/<name>.md` before any setup runs.
If README and code disagree, **code wins**. README/QUICKSTART are read last, after code analysis.

## Invocation

```text
/clone-setup <github-url-or-owner/repo> [BRANCH=<branch>]
```

Examples:
- `/clone-setup yamadashy/repomix`
- `/clone-setup https://github.com/n8n-io/n8n`
- `/clone-setup apache/kafka BRANCH=trunk`

---

## HARD RULES — read before every run

**These rules override the script's own output. The script is a tool; you are the judge.**

1. **`✅ Step 0 complete` means the pack is available. It does NOT mean the repo is set up or healthy.** The script prints this message on every successful run, including reruns on already-cloned repos. Treat it as "pack ready, proceed to Phase 2."

2. **"Dossier already exists (leaving untouched)" is NOT a health signal.** An existing dossier may be a stub with unfilled TODOs from a prior interrupted run. You must check its completeness (see §Idempotency below) before treating any phase as done.

3. **"Reusing existing clone" means the work dir was not re-created.** The prior install may be stale, broken, or on a different commit. Re-verify Phase 3 even if the directory exists.

4. **The script's "step 3: THEN run `gh repo fork`" is a conditional, not a next action.** This skill never runs `gh repo fork`. Forking is gated on the user resolving §10 Open Decisions. If the script's output says to fork, ignore it and report the §10 gate items instead.

5. **Never report "setup complete and healthy" without running the health check in Phase 3.**

---

## Idempotency — what to do on a re-run

At the start of every invocation, determine `<name>` from the input (lowercased repo slug, e.g. `repomix` for `yamadashy/repomix`), then check existing state:

```bash
cd /home/drdave/workspace/my-github

# Check work dir
ls -la ".attic/research-work/<name>/.git" 2>/dev/null && echo "WORK_DIR_EXISTS" || echo "WORK_DIR_MISSING"

# Check dossier and count remaining TODOs
grep -c "^TODO\b\|: TODO$\| TODO$" "data/brain-data/research/<name>.md" 2>/dev/null \
  || echo "DOSSIER_MISSING"
```

Decision table — follow the matching row exactly:

| Work dir | Dossier | TODOs remaining | Action |
|---|---|---|---|
| Missing | Missing | — | Full run: Phase 1 → Phase 2 → Phase 3 |
| Missing | Exists | any | Phase 1 (reclone), re-read dossier to find gaps, complete Phase 2, Phase 3 |
| Exists | Missing | — | Phase 1 (repack only, skip reclone), full Phase 2, Phase 3 |
| Exists | Exists | > 0 | Phase 1 (repack, skip reclone), fill remaining TODOs in Phase 2, Phase 3 |
| Exists | Exists | 0 | Dossier looks complete — still run Phase 3 health check to confirm current state |

**No row says "already done, skip to fork."** Every invocation ends at Phase 3.

To force a full re-clone from scratch (e.g. upstream has changed significantly):
```bash
FORCE_RECLONE=1 make research.pack URL=<owner/repo>
```

---

## Phase 1 — Pack (Step 0 of the ritual)

Run from the umbrella root:

```bash
cd /home/drdave/workspace/my-github
make research.pack URL=<input>
```

If `BRANCH` was provided: `make research.pack URL=<input> BRANCH=<branch>`

This produces:
- `.attic/research-work/<name>/` — full upstream clone (gitignored work area)
- `data/brain-data/research/<name>/repomix-pack.xml` — full source pack
- `data/brain-data/research/<name>/repomix-pack.compressed.xml` — signatures + comments only
- `data/brain-data/research/<name>/repomix-summary.md` — file counts, languages, HEAD
- `data/brain-data/research/<name>.md` — stub dossier (only created if one doesn't already exist)

Capture `<name>` (lowercased repo name shown in script output) and the work-dir path.
If the command exits non-zero, stop and report the error — do not continue.

**After Phase 1 completes:** report what was found (new clone vs reused, dossier state, TODO count). Do not declare success or health yet.

---

## Phase 2 — Deep Research (code beats docs)

### Reading order — strictly follow this sequence

1. `data/brain-data/research/<name>/repomix-summary.md` — stats, HEAD, language breakdown
2. `data/brain-data/research/<name>/repomix-pack.compressed.xml` — compressed source (signatures + comments; ideal for LLM analysis)
3. Only if compressed pack is insufficient for a specific section, read from `.attic/research-work/<name>/` directly:
   - Root manifest: `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod`
   - Entry point from manifest `main`/`bin`/`exports` field
   - `LICENSE` or `LICENSE.md` or `COPYING` — full text
4. README/QUICKSTART/docs — read **last**, only for cross-checking, never as primary source

### Extract the following from code

#### A. Identity (manifest-first)

Read the root manifest and extract:
- Exact `name`, `version`, `description`
- `license` field value
- `engines` / `requires-python` / rust edition / go version
- `bin` entries — actual CLI commands
- `main` / `module` / `exports` — actual entry points
- `keywords`
- From summary: tracked file count, primary languages, HEAD SHA + date

#### B. Purpose (cross-verified)

1. Summarize what the README says the tool does (1-3 sentences, quote preferred)
2. Read the entry point — what does the code actually do on startup?
3. Verdict: does code match README? If not, describe the gap
4. List any README claims with no corresponding code path

#### C. Stack inventory (from code)

- **Build system**: what does `scripts.build` / Makefile / `build.rs` actually invoke?
- **Dev server**: what does `scripts.dev` / `scripts.start` actually start?
- **Runtime requirements**: Node from `engines`, Python from `requires-python`, Rust edition, Go from `go.mod`
- **Key dependencies**: scan `dependencies` + `devDependencies` / Cargo `[dependencies]` / pyproject deps — flag heavy, unusual, or security-relevant ones
- **Native deps**: `node-gyp`, `build.rs`, C extensions, FFI, WASM bindings?
- **Database**: ORM, migration tool, connection code?
- **Auth**: JWT, OAuth, session middleware?

#### D. Actual setup commands — CRITICAL, verify from code not README

For each command, look in the manifest `scripts` section (or Makefile / pyproject), NOT the README:

| Command | How to verify | What to record |
|---------|---------------|----------------|
| Install | Lock file present: `pnpm-lock.yaml`→pnpm, `bun.lockb`→bun, `package-lock.json`→npm, `uv.lock`→uv, `Cargo.lock`→cargo | Exact command |
| Dev server | `scripts.dev` or `scripts.start` | Command + what it starts |
| Build | `scripts.build` | Command + output artifact location |
| Test | `scripts.test` | Command + runner name |
| Lint | `scripts.lint` | Command |

**Env vars** — scan compressed pack for actual code usage:
- Node/TS: `process.env.FOO`
- Python: `os.environ["FOO"]` or `os.getenv("FOO")`
- Rust: `std::env::var("FOO")`
- Any `.env` loader: `dotenv`, `python-dotenv`, `dotenvy`

For each var found: mark REQUIRED (no default in code → app fails without it) or OPTIONAL (has fallback).

**Required services** — grep compressed pack for:
- DB: `postgres://`, `mysql://`, `mongodb://`, `sqlite:`, `redis://`, connection pool
- External APIs: `fetch(`, `axios.`, `requests.get` — note the target domains/services
- Message queues: Kafka, RabbitMQ, NATS, SQS
- Ports: `.listen(`, `PORT`, `3000`, `8080` — list what the app binds

#### E. License (read the actual LICENSE file text)

- Identify the SPDX identifier from the file
- MIT/Apache-2.0/BSD: "permissive — no friction"
- GPL/LGPL: "copyleft — forking obligates releasing changes"
- AGPL: "network copyleft — SaaS use obligates source release"
- SSPL/BSL/Commons Clause/custom: "non-OSI — legal review required before fork"
- Check subdirectories for different licenses
- Note any CLA requirement from `CONTRIBUTING.md`

#### F. Discrepancies — README vs code (MANDATORY section)

For every instruction in README/QUICKSTART, verify against code. Common patterns:

| README / QUICKSTART claims | Code reality | Severity |
|---|---|---|
| `npm install` | `pnpm-lock.yaml` present → use pnpm | block |
| `npm start` | `scripts.start` absent from package.json | block |
| Lists env var FOO | Not referenced anywhere in source | info |
| Feature X supported | No code path for X found | warn |
| Port 3000 | Code binds 8080 | warn |
| Node >=18 | `engines` says `>=20` | warn |

Severity: **block** = setup will fail without this fix; **warn** = surprising but non-fatal; **info** = cosmetic mismatch.

If no discrepancies found after thorough check: write "None found — README matches code."

#### G. Security and adoption flags

Scan compressed pack for:
- Hardcoded credentials: `password =`, `api_key =`, `secret =`, `token =` assigned to string literals (not env var reads)
- Telemetry: `analytics`, `telemetry`, `beacon`, `mixpanel`, `segment`, `posthog`, `amplitude`
- Unusual network calls on startup (phoning home, license key checks)
- Deprecated packages (e.g., `request` for Node, `imp` for Python)

---

## Phase 2 output — Fill the dossier

Read the stub at `data/brain-data/research/<name>.md`.
Replace **every TODO** with real findings. Never leave a section blank.
If something is genuinely unknowable from the pack: write "Not determinable from source — requires runtime test."

Style reference: `data/brain-data/research/repomix.md`

The dossier must have all of these sections filled:

```text
## 1. Identity            — table from manifest
## 2. Purpose             — cross-verified + code-match verdict
## 3. Stack inventory     — from code
## 4. License caveat      — from LICENSE file text
## 5. FlexNetOS-side intent
## 6. Pre-adoption audit  — checklist with actual findings
## 7. Adoption plan
## 8. Sync risk           — upstream release cadence, last commit date
## 9. Verification        — exact commands (filled after Phase 3)
## 10. Open decisions     — gate items for user before fork
## 11. Decision log       — empty until adoption
## 12. Discrepancies      — README vs code table (mandatory, even if "None found")
```

After writing the dossier, verify no TODOs remain:

```bash
grep -n "^TODO\b\|: TODO$\| TODO$" "data/brain-data/research/<name>.md" | wc -l
```

If the count is > 0, list the unfilled lines and complete them before proceeding to Phase 3.

Write the dossier to disk before starting Phase 3.

---

## Phase 3 — Verified Setup

Work in `.attic/research-work/<name>/`.

**Even if the directory already has `node_modules`/`target`/`.venv` from a prior run, re-run the install command.** Prior artifacts are not evidence of current health.

1. **Env file**: if `.env.example` exists and `.env` does not → `cp .env.example .env`. Note which vars are blank and need real values.

2. **Install**: use the command from Phase 2 code-verified findings — NOT what README says. If Phase 2 found `pnpm-lock.yaml`, run `pnpm install` even if README says `npm install`.

3. **Health check** — run these to confirm the install actually worked (adapt to actual package manager / runtime):

   ```bash
   cd .attic/research-work/<name>

   # Node/npm/pnpm/bun projects:
   node --version              # confirm runtime matches engines field
   ls node_modules | wc -l    # confirm install produced output
   
   # Rust projects:
   cargo check 2>&1 | tail -5  # compile check without full build
   
   # Python/uv projects:
   .venv/bin/python --version 2>/dev/null || python3 --version
   ```

4. **Smoke test**: if `scripts.test` exists and Phase 2 found no reason to skip, run it. Capture exit code.

5. **Record result** in dossier §9 Verification:
   - Exact commands run
   - Exit codes
   - First error line if non-zero
   - Pass/fail verdict

If install exits non-zero: document the error verbatim in §9. Stop Phase 3. Do NOT guess at fixes.

---

## Final summary

Print after all phases complete:

```text
## clone-setup summary: <name>

| Phase    | Status              | Details                                            |
|----------|---------------------|----------------------------------------------------|
| Pack     | ✓ / ✗              | <size>, HEAD <sha>, branch <branch>                |
| Research | ✓ / ✗              | <N> discrepancies; dossier written; 0 TODOs remain |
| Dossier  | ✓ / ✗              | data/brain-data/research/<name>.md                 |
| Setup    | ✓ / ✗ / ⚠ SKIPPED  | Command: <cmd>; exit <code>                        |

Open decisions blocking fork (§10):
  <list each unchecked [ ] item, or "— none, all resolved">

⛔ Fork is NOT the next step.
   Resolve the §10 items above. When they are all checked off, report back
   and the user will decide whether to run:
     gh repo fork <slug> --org FlexNetOS --clone=false
```

**Do not run `gh repo fork` as part of this skill.**
**Do not suggest it as the immediate next action.** The fork gate exists because naming collisions and upstream drift are expensive to undo. Even if §10 appears empty, present the summary and let the user confirm.
