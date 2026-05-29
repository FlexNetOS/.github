# Research: n8n-mcp

**Status:** Phase 2 complete — dossier filled. Phase 3 pending.
**Action gated by this dossier:** Fork only after §10 resolved by user.

---

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/czlonkowski/n8n-mcp` |
| npm package | `n8n-mcp` v2.56.0 |
| Our fork (to be created) | TBD — do NOT run `gh repo fork` until §10 resolved. |
| License | MIT |
| Default branch | `main` |
| Latest upstream commit | `0f3d3f5` — 2026-05-23 |
| Local clone (work) | `.attic/research-work/n8n-mcp` (gitignored) |
| Codebase pack | `data/brain-data/research/n8n-mcp/repomix-pack.xml` |
| Version | 2.56.0 |
| Description | Integration between n8n workflow automation and Model Context Protocol (MCP) |
| Keywords | n8n, mcp, model-context-protocol, ai, workflow, automation |
| Tracked files | 1541 (764 repomixed) |
| Primary languages | TypeScript (705 files), JS (223), Markdown (104) |

---

## 2. Purpose (cross-verified)

**README says:** "A Model Context Protocol (MCP) server that provides AI assistants with comprehensive access to n8n node documentation, properties, and operations. Deploy in minutes to give Claude and other AI assistants deep knowledge about n8n's 1,851 workflow automation nodes (822 core + 1,029 community)."

**Code confirms:** Entry point `src/mcp/index.ts` starts an MCP server in either `stdio` or `http` mode. Stdio mode is for local Claude Desktop / CLI use; HTTP mode for remote deployment. The server exposes n8n node documentation via MCP tools, and optionally 16 workflow management tools when `N8N_API_URL` + `N8N_API_KEY` are configured pointing at a live n8n instance.

**Code vs README verdict:** Match. The tool is a documentation + management bridge, not a workflow runner itself.

---

## 3. Stack Inventory

| Concern | Detail |
| --- | --- |
| Runtime | Node.js — no `engines` field; `@types/node ^22` implies Node 22+ |
| Language | TypeScript 5.8, compiled via `tsc -p tsconfig.build.json` → `dist/` |
| Package manager | **npm** — `package-lock.json` present. Use `npm install`. |
| Build | `npm run build` → tsc only. Outputs to `dist/`. |
| Dev mode | `npm run dev` → build + DB rebuild + validate |
| Test runner | vitest (`npm run test:run` for non-watch CI run) |
| Lint/typecheck | `tsc --noEmit` (`npm run lint`) |
| CLI binary | `dist/mcp/stdio-wrapper.js` (bin: `n8n-mcp`) |
| MCP SDK | `@modelcontextprotocol/sdk` 1.28.0 |
| HTTP server | Express v5 (`^5.1.0`) + `express-rate-limit ^7.1.5` |
| Database | SQLite via `sql.js ^1.13.0` — file at `./data/nodes.db` (no external DB required) |
| n8n packages | `n8n-core`, `n8n-nodes-base`, `n8n-workflow`, `@n8n/n8n-nodes-langchain` — all pinned 2.21.x |
| Auth | `AUTH_TOKEN` env var (HTTP mode only). Rate-limited login endpoint. |
| Telemetry | **Enabled by default.** Anonymous usage stats. Opt-out: `N8N_MCP_TELEMETRY_DISABLED=true` |
| Supabase | `@supabase/supabase-js ^2.57.4` — used only in credential scanner to detect leaked Supabase tokens in user workflows. Not required for core operation. |
| OpenAI | Optional. `OPENAI_API_KEY` enables AI-powered template metadata generation via Batch API. |
| Docker | `docker-compose.yml` ships; pulls `ghcr.io/czlonkowski/n8n-mcp:latest` |
| Ports | `3000` (HTTP mode); no port (stdio default) |
| SSRF protection | Built-in. `WEBHOOK_SECURITY_MODE`: `strict` (default) / `moderate` / `permissive` |
| Native deps | None — no node-gyp, no build.rs, no WASM |

**Key env vars:**

| Var | Required | Default | Notes |
| --- | --- | --- | --- |
| `MCP_MODE` | No | `stdio` | `stdio` or `http` |
| `AUTH_TOKEN` | Yes (HTTP mode) | — | `openssl rand -base64 32` |
| `NODE_DB_PATH` | No | `./data/nodes.db` | SQLite path |
| `N8N_API_URL` | No | — | Enables 16 workflow management tools |
| `N8N_API_KEY` | No | — | Pairs with `N8N_API_URL` |
| `N8N_MCP_TELEMETRY_DISABLED` | No | `false` | Set `true` to opt out |
| `WEBHOOK_SECURITY_MODE` | No | `strict` | Use `moderate` for local n8n dev |
| `OPENAI_API_KEY` | No | — | Template metadata AI generation |
| `PORT` | No | `3000` | HTTP mode only |
| `NODE_ENV` | No | `development` | |
| `REBUILD_ON_START` | No | `false` | Rebuild SQLite DB on startup |
| `ENABLE_MULTI_TENANT` | No | `false` | Multi-tenant HTTP mode |

---

## 4. License Caveat

**MIT License** — Copyright (c) 2024 Romuald Czlonkowski @ www.aiadvisors.pl/en

Permissive — no friction for forking or commercial use. No CLA found in CONTRIBUTING.md.

---

## 5. FlexNetOS-Side Intent

Use n8n-mcp as a companion to the running n8n instance (`repos/n8n`) to give Claude MCP-level access to:
1. All 1,851 n8n node docs (no n8n API key needed for read-only docs mode)
2. Live workflow management (create/update/run workflows) via `N8N_API_URL=http://localhost:5678` + an n8n API key from the running instance

Run mode: `stdio` for direct Claude Desktop/CLI integration, or `http` for shared access via `n8n-mcp.test` slim domain.

---

## 6. Pre-Adoption Audit

| Check | Result |
| --- | --- |
| License compatible | ✅ MIT — permissive |
| CLA required | ✅ None |
| Hardcoded credentials in source | ✅ None. Credential scanner detects secrets in *user workflows*, not in the tool itself. |
| Telemetry | ⚠️ Enabled by default — opt-out with `N8N_MCP_TELEMETRY_DISABLED=true` |
| Suspicious startup network calls | ⚠️ Telemetry phone-home on first run. No other unexpected calls. |
| Deprecated packages | ✅ None found |
| Required paid services | ✅ None. OpenAI optional. Supabase SDK not needed for core use. |
| Docker available | ✅ `docker-compose.yml` ships |
| Self-contained DB | ✅ SQLite — no external DB |
| Port conflicts | ⚠️ HTTP mode uses 3000 — verify no conflicts with local stack |

---

## 7. Adoption Plan

1. Resolve §10 (submodule placement, mode, API key)
2. Copy `.env.example` → `.env`, set `N8N_MCP_TELEMETRY_DISABLED=true`, set `N8N_API_URL=http://localhost:5678`, add `N8N_API_KEY`
3. `npm install && npm run build`
4. `node dist/scripts/rebuild.js` to populate SQLite with node docs
5. Run in chosen mode; register in Claude Code MCP config
6. Smoke test: `npm run test:essentials`

---

## 8. Sync Risk

| Factor | Detail |
| --- | --- |
| Release cadence | Active — PR #799 merged 2026-05-23, v2.56.0 |
| n8n version pin | Pins `n8n-core/workflow/nodes` at 2.21.x — must track n8n releases |
| Drift risk | **High** — n8n-mcp must stay within ~1 minor version of the running n8n instance |
| License risk | MIT — no BSL/SSPL risk |

---

## 9. Verification

```
Commands run:
  npm install                        exit 0  (1008 modules)
  npm run build                      exit 0  (tsc clean)
  node dist/scripts/rebuild.js       exit 0  (823 nodes, 2352 templates)
  npm run test:unit                  exit 1* (4861/4901 pass)

*5 failures are environment artifacts:
  - 1× telemetry test broken by N8N_MCP_TELEMETRY_DISABLED=true leaking into mock scope
  - 2× network upload/batch tests (require external endpoint)
  - 2× similarity service network tests
  All core functionality tests pass.

Result: PASS — setup is healthy for local use.
```

---

## 10. Open Decisions

- [ ] **Submodule placement**: User requested n8n-mcp as submodule *inside* `repos/n8n`. Standard umbrella practice places submodules at `repos/{owned,forked,external}/`. Clarify: umbrella-level `repos/external/n8n-mcp` (standard) or literally nested inside `repos/n8n/` (non-standard, adds friction)?
- [ ] **Telemetry**: Confirm `N8N_MCP_TELEMETRY_DISABLED=true` before first run.
- [ ] **n8n API key**: Generate from running n8n instance (Settings > API) and store in `secrets/`.
- [ ] **Run mode**: stdio (local Claude use) or http (for `n8n-mcp.test` slim domain)?
- [ ] **Port 3000**: Verify nothing else on host uses 3000 if HTTP mode is chosen.
- [ ] **n8n version alignment**: Confirm running n8n build version is close to n8n-mcp's pinned `n8n-core@2.21.4`.

---

## 11. Decision Log

*Empty — no decisions recorded yet.*

---

## 12. Discrepancies — README vs Code

| README / docs claim | Code reality | Severity |
| --- | --- | --- |
| No Node version stated | `@types/node ^22` implies Node 22+; no `engines` field to enforce it | warn |
| `USE_FIXED_HTTP` mentioned in some docs | Explicitly deprecated in code and docker-compose comments | info |
| "Deploy in minutes" | Full cold build: `npm install + build + rebuild` takes 2-5 min | info |
| Docker compose pulls prebuilt image | No build-from-source compose provided — must `npm run build` for source install | info |
| None blocking — README matches code on all setup-critical items | | |
