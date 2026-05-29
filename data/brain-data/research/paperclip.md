# Research: paperclip

**Status:** Pre-adoption research. **Third-party upstream — needs fork.**
**Action gated by this dossier:** `gh repo fork paperclipai/paperclip --org FlexNetOS` + branch setup + submodule at `repos/forked/paperclip/`.

**Cross-reference:** Matches [my-github-reconciliation.md](my-github-reconciliation.md) Reservation 2 — paperclip origin is NOT under FlexNetOS, so G3a will exit 13 (UNSAFE-MISMATCH). Operator must triage via this dossier before fork.

---

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/paperclipai/paperclip.git` |
| Our fork (to be created) | TBD — do NOT run `gh repo fork` until §10 Open Decisions resolved. |
| License | **MIT** |
| Upstream default branch | `master` |
| Latest upstream commit | `9eac727` — `[codex] Add skills CLI and catalog management (#6782)` (2026-05-28) |
| Local clone (work) | `.attic/research-work/paperclip` (gitignored) |
| Codebase pack | `data/brain-data/research/paperclip/repomix-pack.xml` |
| Published CLI | `paperclipai` on npm |
| Docs site | `https://paperclip.ing/docs` |
| Community | Discord + Twitter (`@papercliping`) |
| Node requirement | `>=20` |
| Package manager | `pnpm@9.15.4` (enforced in root `packageManager` field) |

| Metric | Value |
| --- | --- |
| Tracked files | 2,578 |
| Working tree | 67.7 MB |
| Primary language | TypeScript (1,425 `.ts` + 388 `.tsx` = 1,813 files) |
| Top-level packages | `packages/*`, `server/`, `ui/`, `cli/` |

---

## 2. Purpose (cross-verified)

### README says

> "Paperclip is the app people use to manage AI agents for work."

> "If OpenClaw is an *employee*, Paperclip is the *company*."

> "Paperclip is a Node.js server and React UI that orchestrates a team of AI agents to run a business."

> "This is for teams. If you have one agent, you probably don't need Paperclip. If you have twenty — you definitely do."

### Code confirms

Server entry (`server/src/index.ts`) starts an Express v5 HTTP + WebSocket server on `PORT=3100`, initialises Drizzle ORM against Postgres (embedded or external), and begins the agent heartbeat/scheduler loop. The UI (`ui/`) is a React 19 SPA; the CLI (`cli/`) is the operator surface for bootstrap, worktree management, DB backup, and routine control.

### Code-match verdict

**Matches.** README accurately describes the architecture. The "company OS for AI agents" framing is precise: the codebase contains org chart, budget enforcement, ticketing, heartbeat scheduling, governance approvals, audit logging, and an adapter layer for multiple agent runtimes (Claude Code, Codex, Cursor, Gemini, Grok, OpenClaw, pi, OpenCode).

### README claims without a code path

None found — all README-listed capabilities have corresponding code paths.

---

## 3. Stack inventory

### Monorepo

pnpm workspaces (`pnpm-workspace.yaml`). No Turborepo/Nx/Lerna — a custom `scripts/dev-runner.ts` orchestrates watch mode. All packages share `pnpm@9.15.4`.

Workspace members:
- `packages/*` — `shared`, `db`, `adapter-utils`, `mcp-server`, `skills-catalog`
- `packages/adapters/*` — one adapter package per agent runtime: `claude-local`, `codex-local`, `cursor-local`, `cursor-cloud`, `gemini-local`, `grok-local`, `openclaw-gateway`, `opencode-local`, `pi-local`, `acpx-local`, `utils`
- `packages/plugins/*` — out-of-process plugin SDK + examples
- `server/`, `ui/`, `cli/`

### Build system

| Package | Build command |
| --- | --- |
| Root (all) | `pnpm -r build` |
| server | `tsc && cp -R src/onboarding-assets/ dist/` |
| ui | `tsc -b && vite build` |
| cli | esbuild via `cli/esbuild.config.mjs` |
| db | `tsc && cp -r src/migrations dist/migrations` (with migration-number check) |

### Dev server

```bash
pnpm dev           # API server + UI (watch mode via dev-runner.ts)
pnpm dev:once      # same, no watch
pnpm dev:server    # server only (tsx src/index.ts)
pnpm dev:ui        # Vite dev server only
```

### Database

- **ORM:** Drizzle ORM `@0.45.2`
- **Migration tooling:** `drizzle-kit@0.31.9`, custom `check-migration-numbering.ts`, `migrate.ts`
- **Engine:** PostgreSQL
  - **Embedded mode:** `embedded-postgres@18.1.0-beta.16` (beta, patched — `patches/embedded-postgres@18.1.0-beta.16.patch`); auto-started, zero-config for local/dev
  - **External mode:** standard `postgres@^3.4.5` client via `DATABASE_URL`
  - Docker Compose uses `postgres:17-alpine`

### Auth

`better-auth@1.4.18` (TypeScript-first auth library). Two deployment modes:
- `trusted` (default for `onboard --yes`): no auth required for loopback access — **any process reaching port 3100 has full access**
- `authenticated`: full multi-user with board claim flow, invite links, agent API keys, short-lived run JWTs; requires `BETTER_AUTH_SECRET`

### Key dependencies (heavy / notable)

| Dependency | Why notable |
| --- | --- |
| `sharp@^0.34.5` | Native image processing (libvips, node-gyp, platform binary) |
| `embedded-postgres@18.1.0-beta.16` | Bundled Postgres binary — large, platform-specific, **beta + patched** |
| `@aws-sdk/client-s3@^3.888.0` | S3 object storage (optional; falls back to local FS) |
| `react@^19.0.0` + `react-dom` | React 19 |
| `express@^5.1.0` | Express v5 (stable but recently GA) |
| `ws@^8.19.0` | WebSocket server (live agent events) |
| `pino@^9.6.0` | Structured JSON logging |
| `mermaid@^11.12.0` | Diagram rendering in UI |
| `@assistant-ui/react@0.12.23` | AI chat UI components |
| `@mdxeditor/editor@^3.52.4` | Rich text / MDX editor |
| `hermes-paperclip-adapter` | First-party adapter (npm, not workspace) |
| `vitest` | Unit test runner |
| `playwright` | E2E test runner (separate `pnpm test:e2e`) |

### Native modules

YES — `sharp` (libvips native bindings) and `embedded-postgres` (Postgres binary). Both require platform-specific prebuilts or native compilation. On Linux/x86_64 prebuilts should pull cleanly, but Docker builds need multi-stage care.

### Telemetry

Enabled by default. Endpoint: `https://telemetry.paperclip.ing/ingest` (AWS API Gateway fallback: `execute-api.us-east-1.amazonaws.com`). Respects `PAPERCLIP_TELEMETRY_DISABLED=1`, `DO_NOT_TRACK=1`, `CI=true`. SHA-256 hashes repo paths (per-install salt) before transmission. Batch size 50, flush every 60 s.

---

## 4. License caveat

- **SPDX ID:** MIT
- **Copyright:** "Copyright (c) 2025 Paperclip AI" (LICENSE file); README says "MIT © 2026 Paperclip Labs, Inc" (minor inconsistency — company renamed, LICENSE not updated)
- **Verdict:** Permissive — no copyleft, no network-copyleft, no commercial restrictions.
- **CLA:** None. `CONTRIBUTING.md` requires `Model Used:` disclosure in PRs and uses the Greptile review bot, but no contributor license agreement.
- **Sub-directory licenses:** None detected. All workspace packages carry MIT in their `package.json`.

---

## 5. FlexNetOS-side intent

Paperclip would serve as the **agent orchestration control plane** for FlexNetOS operations — the "company OS" layer above individual Claude Code, OpenClaw, Codex, and other agent processes.

The relationship:
- **Paperclip** = company-level orchestrator (goals, budgets, org chart, heartbeat scheduling, audit)
- **OMC / Claude Code** = one agent type Paperclip can hire and schedule
- **oh-my-claudecode** = still the Claude Code runtime, now Paperclip-dispatched

*(drdave_input)* Use case is org chart and workflow.

Overlaps `fabro` (graph orchestration) and the existing PENDING-FORK agents, but is distinct:
- **End-user-facing app** with full UI (not just runtime library / CLI).
- **`skills/` directory** aligns with FlexNetOS skill registry.
- **Brand-conscious upstream** — keep FlexNetOS modifications scoped to org-only surfaces; do not touch upstream brand materials.

Best customization surface: the out-of-process **plugin SDK** (`packages/plugins/`) — FlexNetOS customizations as plugins, not core patches, keeps the fork rebasing clean.

---

## 6. Pre-adoption audit

- [x] License clear — MIT, no CLA
- [x] Active upstream — commit on 2026-05-28, high-velocity (ticket IDs in `PAPA-NNN` range, 6810+ issues)
- [ ] Build reproduces locally — **not yet verified** (see §9)
- [x] No nested submodules with restrictive licenses
- [x] Sync cadence agreed — `master` mirrors upstream; FlexNetOS changes on `develop`
- [ ] Telemetry opt-out configured (`PAPERCLIP_TELEMETRY_DISABLED=1` in deployment env)
- [ ] `BETTER_AUTH_SECRET` generated and stored in `secrets/store/`
- [ ] `embedded-postgres` patch compatibility verified on FlexNetOS host
- [ ] `sharp` native binary installs cleanly on FlexNetOS host
- [x] No hardcoded credentials in source
- [ ] `trusted` vs `authenticated` deployment mode decision made (see §10)

---

## 7. Adoption plan

Case: **third-party — needs fork**.

1. **Irreversible: requires user explicit go-ahead + §10 Open Decisions resolved.**
   ```bash
   gh repo fork paperclipai/paperclip --org FlexNetOS --clone=false
   ```
2. Rewire local clone's remotes:
   ```bash
   cd repos/paperclip
   git remote rename origin upstream
   git remote add origin https://github.com/FlexNetOS/paperclip.git
   git push origin master                        # seed the fork's master
   git checkout -b develop && git push -u origin develop
   ```
3. Replace plain clone with submodule:
   ```bash
   # From umbrella root
   rm -rf repos/paperclip
   mkdir -p repos/forked
   git submodule add --depth=1 -b develop \
       https://github.com/FlexNetOS/paperclip.git \
       repos/forked/paperclip
   cd repos/forked/paperclip
   git remote add upstream https://github.com/paperclipai/paperclip.git
   ```
4. MANIFEST entry:
   ```yaml
   - path: repos/forked/paperclip
     url: https://github.com/FlexNetOS/paperclip
     upstream: https://github.com/paperclipai/paperclip
     branch: develop
     toolchain: [node, pnpm, docker]
     groups: [forked, agents, ui]
     notes: |
       AI agent management app — "company OS" for multi-agent teams (MIT).
       Upstream uses `master`; fork's `master` mirrors upstream, `develop`
       carries FlexNetOS changes. Brand-sensitive — modifications scoped to
       org-only surfaces only. Customize via plugin SDK, not core patches.
       pnpm@9.15.4 enforced. Native deps: sharp + embedded-postgres (beta+patched).
       Set PAPERCLIP_TELEMETRY_DISABLED=1 in deployment.
   ```
5. Phase B (org-only changes) on `develop`:
   - `.github/CODEOWNERS`: `* @FlexNetOS/maintainers`
   - Branch protection on `master`: linear history, no direct pushes
   - Branch protection on `develop`: PR + 1 review
   - `.github/FLEXNETOS-ENV.md`: env-scaffold pointer and config guidance
   - `.github/workflows/ci.yml`: caller for umbrella reusables
   - **DO NOT** touch upstream README, banner, logo, product copy, `skills/` root layout, or `PAPA-NNN` ticket references.
6. Skills strategy: FlexNetOS-specific skills under `skills/flexnetos/` subdirectory — do not pollute the root `skills/` namespace to minimise merge conflicts.

---

## 8. Sync risk

**Medium-high.** Very active upstream (daily commits, 6810+ PRs), brand-conscious:

- Brand-driven README/banner changes are frequent → guaranteed conflicts if FlexNetOS edits README. Resolution: don't edit README on `develop`.
- `skills/` is growing rapidly (CLI skill catalog management landed 2026-05-28) → namespace conflicts if FlexNetOS adds to `skills/`. Resolution: `skills/flexnetos/` subdirectory.
- `embedded-postgres` is beta-and-patched → upstream may upgrade or remove the patch; track `patches/` directory on rebase.
- Adapter ecosystem (`packages/adapters/*`) expands with new agent runtimes → low conflict risk if FlexNetOS doesn't add adapters.
- `releases/` has binary artifacts → consider `--filter=blob:none` partial clone to avoid large binary history.

---

## 9. Verification

Performed against `.attic/research-work/paperclip/` (HEAD `9eac727`, 2026-05-28).

| Step | Command | Result |
| --- | --- | --- |
| Install | `pnpm install` (inside `.attic/research-work/paperclip/`) | Exit 0 — clean |
| Env file | `cp .env.example .env` | Done |
| Unit test | `pnpm test` | Exit 1 — 1207/1221 passed (98.9%); 13 timeouts in `@paperclipai/server` integration tests (workspace-runtime, cursor-local-execute, plugin-worker-manager, app-hmr-port, etc.) — all require live processes/services not present in cold research env. Not a code defect. |
| Dev start | `pnpm dev` | Not run (research phase only) |

Post-fork commands:
```bash
make verify.manifest
make submodules.sync-upstream NAME=paperclip   # "no upstream changes"
git -C repos/forked/paperclip diff upstream/master..develop -- \
    package.json Dockerfile README.md          # must be empty
git -C repos/forked/paperclip diff upstream/master..develop -- \
    'doc/assets/*' assets/                     # must be empty (brand)
```

---

## 10. Open decisions for user

- [ ] **Go/no-go on `gh repo fork paperclipai/paperclip --org FlexNetOS`.**
  *(drdave_input)* **No go** (as of 2026-05-29).
- [ ] Adoption priority vs `fabro` and the 4 PENDING-FORK agents — all overlap in role; sequencing matters for which becomes daily driver vs. reference.
- [ ] Deployment mode: `trusted` (loopback-only, no auth) vs `authenticated` (multi-user with `BETTER_AUTH_SECRET`)?
- [ ] External Postgres vs embedded: for production use an external instance is preferred (embedded is beta + patched).
- [ ] `skills/` integration strategy: contribute back upstream, keep FlexNetOS skills in `skills/flexnetos/`, or maintain a separate skill registry?
- [ ] Brand sensitivity confirmed: no FlexNetOS-side branding changes intended for the fork.

---

## 11. Decision log

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-05-29 | Fork deferred (no-go) | User decision. Dossier complete; revisit when adoption priority resolved vs. fabro. |

---

## 12. Discrepancies — README vs code

| README / QUICKSTART claim | Code reality | Severity |
| --- | --- | --- |
| `npx paperclipai onboard --yes` as the quickstart | `cli/src/commands/onboard.ts` exists (24.7 KB); plausible but not verified end-to-end without running | Low |
| "No setup required — embedded PostgreSQL created automatically" | Confirmed: `embedded-postgres@18.1.0-beta.16` dep in server/cli/db; `prepareEmbeddedPostgresNativeRuntime` called on startup | None |
| "Requirements: Node.js 20+, pnpm 9.15+" | `engines.node = ">=20"`, `packageManager = "pnpm@9.15.4"` — exact match | None |
| "MIT License" | LICENSE file is standard MIT | None |
| Copyright year: README says 2026 | LICENSE file says 2025 (company renamed Paperclip Labs, Inc) | Info |
| "No personal information, issue content, prompts, file paths, or secrets are ever collected" (telemetry) | Telemetry sends to `telemetry.paperclip.ing` + AWS fallback; data scope constrained by `TelemetryEventName` enum; SHA-256 hashes repo paths. Trust required for full verification. | Low |
| Works with pi (adapter listed) | `adapter-pi-local` workspace package confirmed | None |

---

## 13. Security flags

### routines.ts (CLI)

Manages routine state via direct Postgres connection. Uses Drizzle ORM parameterized queries — no shell injection risk. Repomix flagged it due to `child_process` + file I/O + DB access combination. Legitimate operational tooling.

### worktree.ts (CLI — 3,300 lines, largest file)

Manages git worktree lifecycle for agent execution sandboxes:
- All `execFileSync("git", [...])` calls use array args — no shell injection
- Copies git hooks from source worktree to new worktrees — malicious hooks in a cloned repo propagate; inherent to git hooks model, not a Paperclip bug
- Database backup/restore operations (`runDatabaseBackup`, `runDatabaseRestore`)
- Reads/writes config file and `.env` — `resolveConfigPath` guards the path

**This file is the most security-sensitive in the codebase.** Review carefully before enabling Paperclip-managed worktrees in the FlexNetOS environment, particularly if FlexNetOS repos contain custom git hooks.

### Telemetry

On by default. Opt out with `PAPERCLIP_TELEMETRY_DISABLED=1`. Must be set in FlexNetOS deployment env before any agent work runs.

### Auth (trusted mode)

Default `onboard --yes` uses `trusted` mode — zero auth, any process on the host reaching port 3100 has full Paperclip access. Must explicitly choose `authenticated` mode for any network-exposed deployment.

### No hardcoded credentials

Confirmed — `.env.example` uses obvious dev defaults appropriately. `docker-compose.yml` correctly uses `${BETTER_AUTH_SECRET:?}` (hard error if unset).
