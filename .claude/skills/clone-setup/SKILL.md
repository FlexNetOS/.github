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
- `data/brain-data/research/<name>.md` — stub dossier with TODO placeholders

Capture `<name>` (lowercased repo name shown in script output) and the work-dir path.
If the command exits non-zero, stop and report the error — do not continue.

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

Write the dossier to disk before starting Phase 3.

---

## Phase 3 — Verified Setup

Work in `.attic/research-work/<name>/`.

1. **Env file**: if `.env.example` exists and `.env` does not → `cp .env.example .env`. Note which vars are blank and need real values.

2. **Install**: use the command from Phase 2 code-verified findings — NOT what README says. If Phase 2 found `pnpm-lock.yaml`, run `pnpm install` even if README says `npm install`.

3. **Smoke test**: if `scripts.test` exists and Phase 2 found no reason to skip, run it. Capture exit code.

4. **Record result** in dossier §9 Verification:
   - Exact command run
   - Exit code
   - First error line if non-zero
   - Pass/fail verdict

If install exits non-zero: document the error verbatim in §9. Stop Phase 3. Do NOT guess at fixes.

---

## Final summary

Print after all phases complete:

```text
## clone-setup summary: <name>

| Phase    | Status         | Details                                          |
|----------|----------------|--------------------------------------------------|
| Pack     | ✓ / ✗         | <size>, HEAD <sha>, branch <branch>              |
| Research | ✓ / ✗         | <N> discrepancies; dossier written               |
| Dossier  | ✓ / ✗         | data/brain-data/research/<name>.md               |
| Setup    | ✓ / ✗ / ⚠ SKIPPED | Command: <cmd>; exit <code>                |

Next steps:
  Resolve §10 Open Decisions in the dossier before forking.
  When ready: gh repo fork <slug> --org FlexNetOS --clone=false
  See docs/fork-workflow.md for Steps 3–5.
```

Do not suggest or run `gh repo fork` as part of this skill.
Forking is gated on the user resolving §10 Open Decisions.
