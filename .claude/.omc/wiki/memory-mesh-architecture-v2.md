---
title: "Memory Mesh Architecture v2"
tags: ["memory-mesh", "mempalace", "gitnexus", "ruvector", "understand-anything", "integration"]
created: 2026-05-19T23:14:07.780Z
updated: 2026-05-19T23:14:07.780Z
sources: ["_work/memory-mesh/brief.md", "_work/memory-mesh/.omc/plans/memory-mesh.md", "session 2026-05-19"]
links: ["firecrawl-auto-restart-policy.md", "memory-mesh-gotchas.md"]
category: architecture
confidence: high
schemaVersion: 1
---

# Memory Mesh Architecture v2

# Memory Mesh Architecture v2

Local-first always-on memory system wiring 4 systems into one MCP recall surface. Lives at `_work/memory-mesh/`, not inside any of the 4 source repos.

## Containers (final v2 set)
| Container | Role |
|---|---|
| `postgres-ruvector` | Postgres 17 + ruvector ext (SQL vector + 270+ funcs). Built from a memory-mesh-local Dockerfile that skips ruvector's `download-models` binary (fails to compile upstream; we don't need it because MemPalace provides embeddings). |
| `mempalace` | HTTP shim (G009) wrapping MemPalace tool functions. Stdio MCP doesn't work in detached containers — shim is mandatory. |
| `gitnexus-server` | Code KG; HTTP on :4747. |
| `gitnexus-feeder` | :4748 sidecar; receives commit notifications; POSTs `/api/analyze` to gitnexus, then pushes deltas to MemPalace shim. |
| `ua-watch` | inotify file watcher. UA has no headless mode — uses `@understand-anything/core` Node lib + tree-sitter-only static analysis (no LLM). |

## Source-of-truth rule
MemPalace is canonical. Everything stored as drawers with `source_file` provenance:
- `ua:<node-id>` — from UA's `nodes[]` array (bootstrap from existing 14.5 MB graph; live deltas via watcher)
- `gitnexus:<symbol-id>` — from GitNexus reindex deltas
- conversation drawers — no provenance prefix

The agent queries MemPalace only.

## Event-driven push chain
```
git commit → .git/hooks/post-commit (fail-open curl :4748)
           → gitnexus-feeder POST /api/analyze (gitnexus:4747)
           → fetch new symbols → diff vs prior cache
           → POST /v1/add_drawer (mempalace shim :8090)

file edit → ua-watch inotify (debounce 2s)
          → tree-sitter parse via UA core lib
          → diff vs prior knowledge-graph.json
          → POST /v1/add_drawer (mempalace shim :8090)
```

## Key file paths
- Compose: `_work/memory-mesh/docker-compose.yaml`
- Plan: `_work/memory-mesh/.omc/plans/memory-mesh.md` (v2)
- Ledger: `_work/memory-mesh/.omc/ultragoal/goals.json` (9 stories: G001-G009)
- MemPalace backend (added upstream): `_work/repos/mempalace/mempalace/backends/ruvector_postgres.py`
- HTTP shim: `_work/memory-mesh/mempalace/shim/shim.py`
- GitNexus bug fix (uncommitted upstream): `_work/repos/GitNexus/gitnexus/src/server/api.ts:721`
- Postgres Dockerfile: `_work/memory-mesh/postgres/Dockerfile` (forks upstream RuVector one)

All 5 containers: `restart: unless-stopped`. Pattern same as [[firecrawl-auto-restart-policy]] from this workspace.

See [[memory-mesh-gotchas]] for the sharp edges hit during the build.

