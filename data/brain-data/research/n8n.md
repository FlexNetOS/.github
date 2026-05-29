# Research: n8n

**Status:** Pre-adoption research. **Already forked** to FlexNetOS/n8n; only path normalization and branch setup remain.
**Action gated by this dossier:** Set up `develop` branch on FlexNetOS/n8n, replace `repos/n8n/` plain clone with submodule at `repos/forked/n8n/`, add MANIFEST entry.

**Cross-reference:** Matches [my-github-reconciliation.md](my-github-reconciliation.md) D1 — n8n is the highest-priority "do-not-destroy" case. Expected G3a exit: 0 (SAFE — origin already FlexNetOS/n8n, matches MANIFEST upstream pattern).

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream slug | `n8n-io/n8n` |
| Origin (our fork) | `https://github.com/FlexNetOS/n8n.git` |
| Upstream | `https://github.com/n8n-io/n8n.git` |
| Upstream remote | already wired locally as `upstream` |
| Manifest name | `n8n-monorepo` |
| Version | `2.23.0` |
| License | Sustainable Use License + Apache 2.0 (EE files under `LICENSE_EE.md`) |
| Upstream default branch | `master` |
| Runtime requirements | Node `>=22.22` (`engines` field); CONTRIBUTING says "Node 24+" (see §12); pnpm `>=10.22.0` |
| Current local branch | `master` |
| Local state (repos/n8n/) | clean; in sync with origin/master |
| Latest commit | `25a836dfb7 feat(editor): Show data redaction scope dropdown to unlicensed users (#30966)` (2026-05-28) |
| Tracked files | 19,378 |
| Primary language | TypeScript (13,161 files), Vue (1,029), JSON (3,099) |

## 2. Purpose

> *"n8n - Secure Workflow Automation for Technical Teams. n8n is a workflow automation platform that gives technical teams the flexibility of code with the speed of no-code. With 400+ integrations, native AI capabilities, and a fair-code license, n8n lets you build powerful automations while maintaining full control over your data and deployments."*

Monorepo packaged as `n8n-monorepo` (version 2.23.0). 400+ integrations, native AI nodes (LangChain-based), fair-code license. Editor at http://localhost:5678.

**Code vs README verdict:** Code matches the README's claims. The `npx n8n` quick-start in README is for **end users installing from npm**, not for contributors building from source — see §12 for the nuance. AI/LangChain nodes confirmed in `packages/@n8n/nodes-langchain/`. PostHog + RudderStack telemetry is wired into startup (not disclosed in README quick-start).

## 3. Stack inventory

### Package manager / build
- **Package manager:** `pnpm` (enforced — `preinstall` script `block-npm-install.js` blocks `npm install`)
- **Lock file:** `pnpm-lock.yaml` (1.4 MB)
- **Build orchestration:** Turbo (`turbo run build` / `turbo run dev --parallel`)
- **Monorepo structure:** pnpm workspaces under `packages/`

### Runtime requirements (from code)
| Tool | `engines` field | CONTRIBUTING says |
| --- | --- | --- |
| Node.js | `>=22.22` | "version 24 or newer" |
| pnpm | `>=10.22.0` | `pnpm@10.22.0` via corepack |

### Key scripts (from package.json)
| Command | What it does |
| --- | --- |
| `pnpm install` | Install all workspace deps (blocks npm) |
| `pnpm build` | `turbo run build` — full monorepo build |
| `pnpm dev` | `turbo run dev --parallel` — full-stack hot reload |
| `pnpm dev:be` | Backend only (excludes design-system, chat, task-runner, editor-ui) |
| `pnpm dev:fe` | Frontend only (editor-ui + design-system) |
| `pnpm dev:ai` | AI nodes only (langchain + n8n + n8n-core) |
| `pnpm start` | `node scripts/os-normalize.mjs --dir packages/cli/bin n8n` |
| `pnpm test` | `turbo run test` (Jest for backend, Vitest for frontend, Playwright for E2E) |
| `pnpm lint` | `turbo run lint` (Biome + ESLint) |
| `pnpm typecheck` | `turbo run typecheck` |

### Key packages
| Package | Role |
| --- | --- |
| `packages/cli` | Express server, REST API, CLI commands |
| `packages/core` | Workflow execution engine |
| `packages/workflow` | Core workflow interfaces/types |
| `packages/editor-ui` | Vue 3 frontend (Pinia state, Vite build) |
| `packages/nodes-base` | 400+ built-in integration nodes |
| `packages/@n8n/nodes-langchain` | AI/LangChain nodes |
| `packages/@n8n/instance-ai` | AI assistant backend |
| `packages/@n8n/design-system` | Vue component library |
| `packages/@n8n/config` | Centralized config management (`@Env()` decorators) |
| `packages/@n8n/api-types` | Shared TS interfaces (FE ↔ BE) |

### Technology stack
- **Frontend:** Vue 3 + TypeScript + Vite + Pinia + Storybook
- **Backend:** Node.js + TypeScript + Express + TypeORM
- **Database:** TypeORM — SQLite (default) or PostgreSQL
- **Testing:** Jest (unit/backend), Vitest (frontend), Playwright (E2E)
- **Code quality:** Biome (formatting) + ESLint + lefthook git hooks
- **DI container:** `@n8n/di` (IoC)
- **Feature flags:** PostHog
- **Telemetry:** PostHog + RudderStack (wired into base-command startup; can be disabled)

### Env vars (from `.env.local.example` + code scan)
| Var | Required? | Notes |
| --- | --- | --- |
| `N8N_USER_FOLDER` | optional | Local data folder |
| `N8N_LICENSE_TENANT_ID` | optional | For Enterprise license SDK |
| `N8N_LICENSE_ACTIVATION_KEY` | optional | Enterprise activation key |
| `N8N_LICENSE_CERT` | optional | Ephemeral Enterprise cert |
| `N8N_AI_ENABLED` | optional | Enables AI features globally |
| `N8N_AI_ASSISTANT_BASE_URL` | optional | AI assistant service URL |
| `N8N_AI_ANTHROPIC_KEY` | optional | Claude API key for AI workflow builder |
| `LANGSMITH_ENDPOINT` / `LANGSMITH_PROJECT` / `LANGSMITH_TRACING` | optional | LangSmith tracing (LangChain SDK) |

Env file name is **`.env.local.example`** (not `.env.example`) — copy to `.env.local`, load with `pnpm exec dotenvx run -f .env.local -- <cmd>`.

### Required services / ports
- Port **5678** — n8n editor UI
- Database: SQLite by default (file-based); PostgreSQL optional
- Redis: needed for queue mode and multi-main only
- Mailpit: E2E tests only

### Security flags
- **Telemetry ON by default:** PostHog (`packages/cli/src/commands/base-command.ts`) + RudderStack proxy wired at startup. Can be disabled via config.
- **`.ee.` files Enterprise-only:** source under EE license, not SUL.
- No hardcoded credentials found in scan.
- n8n ships Claude (`N8N_AI_ANTHROPIC_KEY`) and LangSmith integrations — those keys come from env, not hardcoded.

## 4. License caveat (READ BEFORE ADOPTING)

**Dual license:**
- Files containing `.ee.` in filename or `.ee` in dirname → **n8n Enterprise License** (`LICENSE_EE.md`). These are NOT licensed under SUL and require a paid Enterprise key to use.
- Everything else → **Sustainable Use License (SUL)** — permits self-hosting and internal use; **restricts SaaS/hosted offerings** that compete with n8n's cloud product.
- Third-party components retain their own licenses.
- **Branches other than `master` are explicitly unlicensed** (stated verbatim in `LICENSE.md` first paragraph).

**For FlexNetOS intent (internal automation only):** SUL is permissive enough. Hosted/SaaS use requires legal review.

## 5. FlexNetOS-side intent

Fits the umbrella's "workflow automation" role:
- Drive cross-repo automation that doesn't fit GitHub Actions
  (long-running, external API orchestration, scheduled jobs).
- Native AI node integration for the FlexNetOS agent fleet.
- Potential to wire into `mempalace`, `ruvector`, `understand-anything`
  via custom nodes.

## 6. Pre-adoption audit

- [x] Fork already at `FlexNetOS/n8n`. **No `gh repo fork` needed.**
- [x] `upstream` remote wired locally in `repos/n8n/`.
- [x] License reviewed — SUL for internal use is acceptable; EE files need Enterprise key.
- [x] Active upstream — very active (thousands of branches, frequent commits, 2.23.0 current).
- [ ] No `develop` branch yet. Must create from `origin/master` before adoption.
- [x] Build verified: `node packages/cli/bin/n8n --version` → `2.23.0` ✓ (node_modules installed, CLI dist built).
- [x] Upstream uses `master`, not `main`. Fork workflow adapts accordingly.
- [x] Telemetry present and ON by default — expected for this project; can be disabled.
- [ ] Sync cadence not agreed — see §10.

## 7. Adoption plan

Case: **already forked — just normalize**.

1. Create `develop` branch and push to fork:
   ```bash
   cd repos/n8n
   git fetch upstream master
   git checkout master && git merge --ff-only upstream/master
   git push origin master                       # mirror upstream
   git checkout -b develop origin/master 2>/dev/null || git checkout develop
   git push -u origin develop
   ```
2. Replace plain clone with submodule:
   ```bash
   # From umbrella root
   rm -rf repos/n8n
   mkdir -p repos/forked
   git submodule add --depth=1 -b develop \
       https://github.com/FlexNetOS/n8n.git \
       repos/forked/n8n
   cd repos/forked/n8n
   git remote add upstream https://github.com/n8n-io/n8n.git
   ```
3. MANIFEST entry (FORKED section):
   ```yaml
   - path: repos/forked/n8n
     url: https://github.com/FlexNetOS/n8n
     upstream: https://github.com/n8n-io/n8n
     branch: develop
     toolchain: [node, pnpm, docker]
     groups: [forked, automation, workflow]
     notes: |
       Workflow automation platform (fair-code SUL license — see
       LICENSE.md). Upstream uses `master`; fork's `master` mirrors
       upstream, `develop` carries FlexNetOS changes.
   ```
4. Phase B (org-only rename) on `develop`:
   - `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`
   - Branch protection on `master` (mirror): linear history, block direct pushes
   - Branch protection on `develop`: PR + 1 review
   - `.github/FUNDING.yml`: copy from umbrella
   - `.github/FLEXNETOS-ENV.md`: env-scaffold pointer
   - `.github/workflows/ci.yml`: thin caller using umbrella reusables
5. Skip Phase D for upstream's `.env.local.example` — leave alone.

## 8. Sync risk

**Medium.** Upstream very active:
- `package.json` changes most weeks (versions, deps). We never edit it → fast-forward.
- Upstream `.github/workflows/` may change. Our caller has different filename (`ci.yml`) → no conflict.
- Big refactors in upstream's `packages/` could create textual conflicts
  on our `develop` if we have commits in same files. Mitigate: keep
  FlexNetOS commits scoped to **new files** or clearly-owned dirs.
- Node/pnpm engine bumps happen regularly — track them.

## 9. Verification

Phase 3 setup **BLOCKED** (2026-05-28):

| Step | Command | Exit | Result |
| --- | --- | --- | --- |
| Env file | `cp .env.local.example .env.local` | 0 | ✓ `.env.local` created |
| node_modules | `bunx pnpm@10.32.1 install` | 0 | ⚠ Install ran but postinstalls NOT applied (see below) |
| Build | `bunx pnpm@10.32.1 exec node .../turbo run build --continue` | 1 | ✗ 24 of 59 packages fail |
| Launch | `node packages/cli/bin/n8n start` | 1 | ✗ MissingModuleError: community-packages.ee dist not built |

**Root cause:** `pnpm 11.4.0` (mise-managed on this host) ignores `pnpm.onlyBuiltDependencies`. This prevents postinstall scripts from running during `pnpm install`, so `turbo` and `tsdown` native binaries are never downloaded and their `.bin/` symlinks are never created. All downstream builds that depend on those tools then fail in cascade.

**Fix (requires clean reinstall with pnpm 10.x):**
```bash
cd repos/n8n
rm -rf node_modules          # clear pnpm 11.x-poisoned install
bunx pnpm@10.32.1 install    # pnpm 10.x respects onlyBuiltDependencies, runs postinstalls
# Verify turbo and tsdown are now in .bin/:
ls node_modules/.bin/turbo node_modules/.bin/tsdown
# Build:
bunx pnpm@10.32.1 exec node node_modules/turbo/bin/turbo run build --continue
# Launch:
node packages/cli/bin/n8n start &
curl http://localhost:5678/healthz   # expect HTTP 200
```

Note: `mise exec pnpm@10.32.1` also fails on this host (GitHub API 401 when downloading pnpm 10.32.1 via aqua). Use `bunx pnpm@10.32.1` instead (downloads via npm registry).

## 10. Open decisions for user ~~DO NOT FORK UNTIL SOURCE CLONE IS PROPERLY SET UP~~ **ALL DECISIONS RESOLVED ✓ — adoption cleared**

- [x] **License:** SUL approved for FlexNetOS internal-automation use case.
- [x] **Sync cadence:** as-needed (not scheduled). Manual bumps via `make submodules.bump`.
- [x] **Local changes:** none in repos/n8n/ (clean HEAD, no FlexNetOS-side commits).
- [x] **Telemetry:** free tier only — PostHog/RudderStack remain on but no paid features.
- [x] **EE files:** local-host-only, all-free community setup. No Enterprise license needed; `.ee.` code paths stay dormant.

## 11. Decision log

| Date | Decision | Notes |
| --- | --- | --- |
| 2026-05-28 | License: SUL approved | Internal automation use only |
| 2026-05-28 | Sync cadence: as-needed | `make submodules.bump GROUP=forked NAME=n8n` when needed |
| 2026-05-28 | Telemetry: free tier | PostHog/RudderStack enabled, no paid plan |
| 2026-05-28 | EE files: not activated | Community free tier; no Enterprise license |

## 12. Discrepancies — README vs code

| README / CONTRIBUTING / QUICKSTART claims | Code reality | Severity |
| --- | --- | --- |
| README quick-start: `npx n8n` (implies npm works) | `preinstall` script blocks `npm install` in the dev repo. `npx n8n` is for **end-user** install from npm registry — a different path. Dev setup must use `pnpm install`. | info (different audience; not a dev-path discrepancy) |
| CONTRIBUTING: "Node.js version 24 or newer is required" | `engines.node` in `package.json` says `>=22.22` | warn (CONTRIBUTING more restrictive; use Node 24 to be safe) |
| `.env.example` (common convention) | Actual file is **`.env.local.example`**, loaded via `dotenvx` (`pnpm exec dotenvx run -f .env.local -- <cmd>`), NOT a plain `cp .env.example .env` pattern | block (wrong filename breaks setup) |
| README: port 5678 (Docker example) | ✓ Confirmed — code binds 5678 | none |
| README: "400+ integrations" | `packages/nodes-base/nodes/` confirms many integration nodes | none |
| LICENSE.md: branches other than `master` not licensed | Not disclosed in README | warn (relevant for fork — all FlexNetOS work must stay on `develop`, never browse unlicensed branches for code) |
| No mention of telemetry in quick-start | PostHog + RudderStack wired into `base-command.ts` startup by default | info (can disable; not deceptive, but worth knowing) |
| CONTRIBUTING: `corepack prepare pnpm@10.22.0 --activate` | `engines.pnpm >= 10.22.0` — consistent | none |

## 13. Build fix — Phase 3 unblocked (2026-05-29)

The §9 build failure was resolved without a clean reinstall. Root cause: pnpm 11.x partially installed node_modules but did not run `tsc-alias` post-build for some workspace packages, leaving `@/` path aliases unresolved in their `dist/` files. Additionally `@n8n/utils` was not symlinked into `packages/cli/node_modules/@n8n/`.

**Actual fix applied (SESSION-2026-05-29-002):**

```bash
cd repos/n8n

# 1. Fix unresolved @/ path aliases in packages/core dist (35 occurrences)
#    (tsc compiled but tsc-alias step was skipped in prior partial build)
cd packages/core
node ../../node_modules/tsc-alias/dist/bin/index.js -p tsconfig.build.json
cd ../..

# 2. Re-install with pnpm 10.x to restore missing workspace symlinks
bunx pnpm@10.32.1 install --frozen-lockfile
#    → @n8n/utils symlink now created in packages/cli/node_modules/@n8n/

# 3. Full turbo build to compile the 6 packages missing dist/
#    (turbo bin is a sh shim — execute directly, do NOT prefix with 'node')
node_modules/.bin/turbo run build --filter='!@n8n/extension-sdk'
#    → 59/59 tasks successful (35 cached), 1m17s

# 4. Health check
node node_modules/@dotenvx/dotenvx/src/cli/dotenvx.js run -f .env.local \
  -- node packages/cli/bin/n8n start &
sleep 20
curl http://localhost:5678/healthz   # → HTTP 200 {"status":"ok"}
```

**Result:** n8n starts clean with zero ERROR/FATAL log entries. DB migrations run and complete. `/healthz` → 200.

**Key learnings:**
- `node_modules/.bin/turbo` is a `#!/bin/sh` wrapper — run as shell, not `node node_modules/.bin/turbo`
- `@n8n/extension-sdk` excluded from build (`--filter='!@n8n/extension-sdk'`) — causes build failures
- `tsc-alias` must be run AFTER `tsc` for any package using the `@/` path alias
- pnpm 11.x breaks workspace symlinks; always use `bunx pnpm@10.32.1` for this repo

## 14. Self-hosting environment variables — all free features

Full comprehensive `.env.local` applied at `repos/n8n/.env.local` (gitignored, 585 lines).
The file is organized into 23 sections, each citing the source config file.

**Key free-feature flags to set explicitly:**

| Variable | Value | Why |
| --- | --- | --- |
| `N8N_ENCRYPTION_KEY` | `openssl rand -hex 32` | **Required** — without it credentials cannot be encrypted |
| `N8N_USER_MANAGEMENT_JWT_SECRET` | `openssl rand -hex 24` | Stable sessions across restarts |
| `N8N_USER_FOLDER` | `$HOME/.n8n` | Data directory (dotenvx expands `$HOME`) |
| `N8N_AI_ENABLED` | `true` | Unlocks all AI nodes and workflow builder |
| `N8N_COMMUNITY_PACKAGES_ENABLED` | `true` | Enables npm community node installation |
| `N8N_PYTHON_ENABLED` | `true` | Python in Code node (requires Python 3 on host) |
| `N8N_MFA_ENABLED` | `true` | TOTP-based MFA |
| `N8N_METRICS` | `true` | Prometheus endpoint at `/metrics` |
| `N8N_PUBLIC_API_DISABLED` | `false` | REST API at `/api/v1/` |
| `N8N_DIAGNOSTICS_ENABLED` | `false` | **Opt out** of PostHog/RudderStack telemetry |
| `N8N_SECURE_COOKIE` | `false` | Must be false for `http://`; true for `https://` |
| `N8N_SSRF_PROTECTION_ENABLED` | `false` (dev) / `true` (prod) | Blocks requests to private IPs |
| `DB_TYPE` | `sqlite` | Default; switch to `postgresdb` for production |
| `EXECUTIONS_MODE` | `regular` | Single-process; use `queue` + Redis for multi-worker |

**EE-only variables (never set without license):** `N8N_SOURCE_CONTROL_*`, `N8N_EXTERNAL_SECRETS_*`, `N8N_SSO_SAML_LOGIN_ENABLED`, `N8N_SSO_OIDC_LOGIN_ENABLED`, `N8N_MULTI_MAIN_SETUP_*`.

**Source config files** (all under `packages/@n8n/config/src/configs/`):
`generic.config.ts`, `database.config.ts`, `executions.config.ts`, `security.config.ts`, `auth.config.ts`, `instance-settings-config.ts`, `instance-settings-loader.config.ts`, `ai.config.ts`, `ai-assistant.config.ts`, `ai-builder.config.ts`, `agents.config.ts`, `instance-ai.config.ts`, `logging.config.ts`, `endpoints.config.ts`, `cache.config.ts`, `user-management.config.ts`, `password.config.ts`, `mfa.config.ts`, `workflows.config.ts`, `tags.config.ts`, `workflow-history.config.ts`, `templates.config.ts`, `version-notifications.config.ts`, `credentials.config.ts`, `diagnostics.config.ts`, `deployment.config.ts`, `nodes.config.ts`, `runners.config.ts`, `event-bus.config.ts`, `public-api.config.ts`, `ssrf-protection.config.ts`, `sso.config.ts` + `packages/core/src/binary-data/binary-data.config.ts` + CLI module configs: `community-packages.config.ts`, `insights.config.ts`, `otel.config.ts`, `push.config.ts`, `redaction.config.ts`, `runtime-credentials.config.ts`, `token-exchange.config.ts`, `quick-connect.config.ts`.
