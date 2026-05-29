---
title: "Memory Mesh Gotchas"
tags: ["memory-mesh", "gotcha", "mempalace", "gitnexus", "ruvector", "understand-anything", "glibc", "rustup", "backend", "architecture", "fix-landed"]
created: 2026-05-19T23:14:34.276Z
updated: 2026-05-20T00:17:57.510Z
sources: ["session 2026-05-19", "advisor feedback", "explore agent surveys"]
links: ["firecrawl-postgres-db-name-gotcha.md", "memory-mesh-architecture-v2.md"]
category: debugging
confidence: high
schemaVersion: 1
---

# Memory Mesh Gotchas

# Memory Mesh Gotchas

Sharp edges encountered while wiring the 4-system mesh. Each is durable — they affect any future re-derivation of this integration.

## 1. MemPalace MCP is stdio-only (no HTTP/SSE upstream)
`mempalace/mcp_server.py` has zero HTTP code. Running `mempalace-mcp` as a detached container command exits immediately (no stdin). Solution: HTTP shim (G009) at `_work/memory-mesh/mempalace/shim/shim.py` imports MemPalace's `tool_*` functions in-process and exposes them as JSON HTTP endpoints. Container command is `python /opt/mempalace-shim/shim.py`, NOT `mempalace-mcp`.

## 2. GitNexus Express 5 / path-to-regexp 8 incompatibility
`gitnexus/src/server/api.ts:721` had `app.options('*', ...)`. Express 5 + path-to-regexp 8 rejects bare `*`. Container crash-loops with: `Missing parameter name at index 1: *`. Fix: replace `'*'` with the RegExp literal `/.*/` — bypasses path-to-regexp entirely. **Uncommitted upstream change** as of session 2026-05-19.

## 3. GitNexus has POST /api/analyze, NOT /api/index
The `mountMCPEndpoints` surface is read-only (no reindex tool). REST has `POST /api/analyze` at `gitnexus/src/server/api.ts:1420` accepting `{path, force?, embeddings?}` returning `202 {jobId, status}`. The MCP HTTP surface (`/api/mcp`) does NOT include analyze — only query/context/impact/detect_changes/rename. **Use REST `/api/analyze` from feeders.**

## 4. ruvector-postgres download-models binary fails to build
`cargo build --release --bin download-models --features "embeddings"` fails (exit 101). The `cargo pgrx package` step that builds the actual extension SUCCEEDS even with the embeddings feature on. Solution: keep `embeddings` in `cargo pgrx package` (removing it breaks gated feature deps in other modules), but **drop the separate `cargo build --bin download-models` step entirely**. MemPalace produces its own embeddings.

## 5. Understand-Anything cannot run headless
UA is a Claude Code plugin. Its `/understand` skill spawns subagents that require LLM access. There is **no standalone CLI**. Headless options: (a) import `@understand-anything/core` Node lib and use `TreeSitterPlugin` + `GraphBuilder` directly for structural analysis (no LLM), (b) shell out via Claude Code with API keys (impractical), or (c) keep existing 14.5 MB knowledge-graph.json as ground truth, only tree-sitter-level diffs for live updates. **Recommendation: (a) for live; (c) for the rich layer.**

## 6. POSTGRES_DB must stay "postgres" for ruvector-postgres
Identical to [[firecrawl-postgres-db-name-gotcha]]. Custom DB names break extension preloads.

## 7. Docker compose `<<:` merge keys are not duplicable
`<<: *anchor1` followed by `<<: *anchor2` on the same node is a YAML parse error. Compose YAML expects the sequence form: `<<: [*anchor1, *anchor2]`. Spent a build cycle on this.

## 8. Background task `exit code 0` does not mean the build succeeded
`docker compose build` in `run_in_background` mode can report exit 0 when the underlying BuildKit step failed. Always confirm with `docker images | grep <expected-tag>` before celebrating. The Dockerfile parse error / build failure goes to stderr but the wrapper exits 0 in some Docker 29 configurations.

Cross-ref: [[memory-mesh-architecture-v2]], [[firecrawl-postgres-db-name-gotcha]].

---

## Update (2026-05-19T23:21:43.533Z)

## 9. ruvector-postgres glibc ABI mismatch
Upstream `crates/ruvector-postgres/Dockerfile` builds in `rustlang/rust:nightly-bookworm-slim` and runs in `postgres:17-bookworm`. Despite both being "bookworm", the nightly Rust image links against glibc 2.38+ (has `__isoc23_strtoll`) while postgres:17-bookworm ships glibc 2.36. Extension fails to load at runtime: `ERROR: could not load library "/usr/lib/postgresql/17/lib/ruvector.so": undefined symbol: __isoc23_strtoll`. Memory mesh fix at `_work/memory-mesh/postgres/Dockerfile`: use `postgres:17-bookworm` as the builder base too, install Rust nightly via rustup on top. Same glibc on both stages.

## 10. GitNexus has no public symbol-enumeration HTTP route
Feeders cannot do `GET /api/symbols?repo=...` — that route doesn't exist (returns 404). Per explore findings at `gitnexus/src/server/api.ts:1003`, symbol/structure enumeration must go through `/api/graph` or via the MCP HTTP tool surface (`/api/mcp`) with the `query` tool. The memory-mesh gitnexus-feeder (v2) successfully calls `/api/analyze` for reindex but the delta-push path still has to be wired through `/api/graph`. Treat as a known follow-up.

## 11. Postgres state dir persists across compose down without -v
`docker compose down` without `-v` keeps the host-mounted state dir (`_work/memory-mesh/state/postgres/`). Postgres sees an existing data dir on next boot and **skips** all `/docker-entrypoint-initdb.d/*.sql` scripts — so `CREATE EXTENSION ruvector` never runs again. Wipe the dir with `sudo rm -rf state/postgres` (root-owned by the postgres uid) before bringing up to force initdb.

---

## Update (2026-05-19T23:27:10.345Z)

## 12. MemPalace `tool_add_drawer` rejects '/' in wing/room names
`mempalace.mcp_server.tool_add_drawer` runs `sanitize_name` on wing and room args. Any path-traversal character (`/`, `\`, `..`) raises ValueError, which the tool catches and returns `{"success": false, "error": "room contains invalid path characters"}`. The shim (v1) returned HTTP 200 anyway, masking the failure. Fix in two places: (a) shim returns HTTP 400 when MemPalace's inner result is `{success: false}`, (b) ingest scripts slug room names — replace `/` with `_`.

## 13. Postgres healthy ≠ extension loaded
`postgres:17` healthcheck just runs `pg_isready`. The init.sql can fail (e.g., extension load error) and the container still reports `healthy`. Always verify with `psql -tc "SELECT extname FROM pg_extension WHERE extname='ruvector';"` after start.

## 14. ruvector-postgres glibc mismatch persists across base images
Even with `postgres:17-bookworm` as the builder base (matching runtime), the built `.so` still requires `__isoc23_strtoll` (glibc 2.38+). The bookworm image ships 2.36. The culprit must be something pulled in by `rustup-init` or a transitive C dep. Not the docker FROM line. Next investigation steps: `ldd /usr/lib/postgresql/17/lib/ruvector.so` inside the runtime container to see which library brings in 2.38, then either install that lib from bookworm-backports or switch builder to `postgres:17-trixie` (when available) for matched-glibc symbol set.

## 15. Background docker compose build can swallow BuildKit output
`run_in_background: true` with `docker compose build` may produce a 0-byte output file even while the build is actively running (verified via `ps -ef | grep cargo`). Workaround: use foreground when the error matters, or `docker buildx build ... --progress=plain` directly.

---

## Update (2026-05-19T23:41:16.398Z)

## 16. MemPalace mcp_server.py imports ChromaBackend DIRECTLY — backend abstraction is partial
The README and `backends/` directory advertise pluggable storage. The registry pattern (RFC 001 §3) works for `palace.get_collection(...)` and other library callers. **But `mcp_server.py:66-67` does `from .backends.chroma import ChromaBackend` and `mcp_server.py:360` calls `ChromaBackend.make_client(_config.palace_path)` directly.** So every MCP tool — `tool_add_drawer`, `tool_search`, etc. — runs through ChromaDB regardless of what's registered or what `MEMPALACE_BACKEND` says.

Monkey-patching `palace._DEFAULT_BACKEND` from the shim does not affect MCP calls because `mcp_server` never goes through `palace.get_collection`.

To actually swap the backend at the MCP layer, you would need to: (a) modify `mcp_server.py` to route through the registry, OR (b) patch `mcp_server.ChromaBackend = RuvectorPostgresBackend` AND ensure the new class is API-compatible with `ChromaBackend.make_client(path)` and the other class methods mcp_server uses. (b) is fragile because the new backend's class shape would have to mirror ChromaBackend down to private internals.

For memory-mesh v1 we keep MEMPALACE_BACKEND=chromadb in practice. Drawers still land in MemPalace and are queryable; ChromaDB-on-disk persists at `/var/lib/mempalace/palace`. The ruvector-postgres container runs and is available for direct SQL use (it has 154 ruvector functions ready) — but MemPalace's MCP path does not currently feed it.

Future direction: file an upstream issue / PR against mempalace to route mcp_server through `palace.get_collection()` so the backend abstraction works at the MCP layer too. Until then, treat MEMPALACE_BACKEND as advisory.

---

## Update (2026-05-20T00:17:57.510Z)

## 17. (RESOLVED) G002 backend abstraction now reaches the MCP layer
Earlier gotcha #16 claimed MemPalace's `mcp_server.py` bypassed the backend abstraction. **Fixed 2026-05-19**: patch at `mempalace/mcp_server.py:369-400` adds an early-return in `_get_collection()` that delegates to `palace.get_collection()` whenever `palace._DEFAULT_BACKEND` is not a `ChromaBackend`. ChromaBackend's path is untouched (no regressions). 3 new tests in `mempalace/tests/test_backend_routing.py` cover the new branch; 57 existing drawer tests still pass.

With this patch + the shim's `palace._DEFAULT_BACKEND = RuvectorPostgresBackend()` swap, **setting `MEMPALACE_BACKEND=ruvector_postgres` now actually routes all MCP drawer writes into postgres-ruvector**. Verified: 9,639 gitnexus + 2,370 ua drawers live in `mp_var_lib_mempalace_palace_mempalace_drawers` table with full embeddings.

## 18. RuvectorPostgresBackend must accept BOTH calling conventions
MemPalace's `palace.get_collection()` calls `_DEFAULT_BACKEND.get_collection(palace_path, collection_name=..., create=...)` POSITIONAL while the BaseBackend contract is keyword-only `get_collection(*, palace=PalaceRef, ...)`. ChromaBackend tolerates both via `_normalize_get_collection_args`. RuvectorPostgresBackend must do the same — implementation accepts `*args, **kwargs` and unpacks either form.

## 19. RuvectorPostgresCollection.__init__ must tolerate missing table
On first instantiation the per-palace table doesn't exist. `_infer_dim()` queries `pg_attribute WHERE attrelid = %s::regclass` which raises `psycopg2.errors.UndefinedTable`. Wrap in try/except + `self._conn.rollback()` so subsequent commands on the same connection don't fail with "current transaction is aborted".

## 20. Embedding-on-add and embedding-on-query fallbacks
MemPalace's chroma backend handles embedding generation via `ChromaBackend._resolve_embedding_function()`. Other backends must either embed themselves or call back to chroma's EF. Pragmatic fix in RuvectorPostgresCollection.add/upsert/query: lazy-import the EF and use it when embeddings/query_embeddings aren't supplied. Couples slightly to chroma but matches MemPalace's existing embedding pipeline (single source of EF truth — same model dimensions, same tokenizer).

## 21. ua-watch feedback loop: filter inotify events to write-only
Watchdog's default `on_any_event` fires on `accessed` events too. Since extract.mjs READS every file (updating atime), inotify IN_ACCESS triggered another fire → infinite loop at ~3s cadence. Fix: subclass `FileSystemEventHandler` with explicit `on_created/on_modified/on_deleted/on_moved` only. Verified silent idle + single fire on real edit.

## 22. ua-watch ignores .git, .gitnexus, .understand-anything, node_modules, etc.
These dirs contain build artifacts that GitNexus's analyze pass writes (touching .gitnexus/) and that node tooling churns (node_modules/). Without an ignore filter, ua-watch keeps firing on artifact churn. The `_IGNORED_DIR_NAMES` set in `ua-watch/app.py` excludes any path with `/.git/`, `/.gitnexus/`, `/.understand-anything/`, `/.omc/`, `/node_modules/`, `/__pycache__/`, `/.venv/`, `/venv/`, `/dist/`, `/build/`, `/.pytest_cache/`, `/.mypy_cache/`, `/.chroma/`.

## 23. extract.mjs (UA core lib) must use BUILT @understand-anything/core
The Dockerfile uses Docker BuildKit `additional_contexts: ua-core-src: <path>` to COPY in the upstream `understand-anything-plugin/packages/core` source, then `pnpm install && pnpm build` to produce `dist/`. Without the build step, `import { TreeSitterPlugin } from '@understand-anything/core'` fails — there's no pre-built dist in the source repo. Build takes ~30s.

These five fixes (G002 routing, signature tolerance, init-tolerance, embedding fallback, ua-watch event filtering) turn the v1 mesh from "partial" to "fully verified end-to-end with 12K+ drawers live in postgres-ruvector".

