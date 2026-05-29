# Agentic-OS — Design

## Goals

1. **One CLI entrypoint** — `harness.js` takes any task, picks a model, logs cost.
2. **No external dependencies for the harness itself** — pure Node stdlib (`http`, `https`, `fs`, `crypto`, `path`).
3. **File-based memory** — JSON / JSONL files in `~/.agentic-os/`. No DB, no Redis.
4. **Provider-agnostic** — every upstream is OpenAI-compatible HTTP. The same code talks to Ollama, freellmapi, and direct OpenAI.
5. **User-space only** — runs without sudo, no network changes, no system services.

## Non-goals (for MVP)

- MCP wrapping of freellmapi (skipped per advisor — adds layers, no benefit)
- A web UI (use freellmapi's own dashboard for provider key management)
- Multi-user / multi-tenant (single user, single machine)
- Vector DB / embedding store (use Claude Code's memory + file-based notes)
- Production-grade kill switches (covered as a "future" item in [SECURITY.md](SECURITY.md))

## Architecture layers

```
┌─────────────────────────────────────────────────────────────┐
│  USER                                                       │
│   ├─ /agentic-os, /agentic-task slash commands              │
│   └─ node scripts/agentic-os/harness.js --task "..."        │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  KERNEL AGENT (agents/agentic-os-kernel.md)                 │
│   - parse intent, choose route, choose sticky               │
│   - delegate to executor                                    │
│   - synthesize result                                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  HARNESS (scripts/agentic-os/harness.js)                    │
│   - lib/config.js       loads + env-overlays config         │
│   - lib/model-router.js picks channel, tracks health        │
│   - lib/task-queue.js   persistent JSON queue               │
│   - lib/freellmapi-client.js HTTP to OpenAI-compatible URL  │
│   - lib/cost-tracker.js JSONL cost log + summary            │
│   - lib/state.js        atomic JSON read/write              │
└──────────────────────────────┬──────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼───────┐    ┌─────────▼─────────┐    ┌───────▼──────────┐
│ local         │    │ freellmapi proxy  │    │ cloud (direct)   │
│ (Ollama,      │    │ :3001  → 14 free  │    │ Anthropic,       │
│  llama.cpp,   │    │ providers w/      │    │ OpenAI,          │
│  vLLM)        │    │ auto-failover     │    │ Gemini           │
└───────────────┘    └───────────────────┘    └──────────────────┘
```

## Data flow for a single task

1. Caller invokes `harness.js --task "..." --route auto`
2. `loadConfig()` merges repo default + `~/.agentic-os/config.json` + env overrides
3. `ModelRouter` instantiated with merged config
4. `router.pick({route})` walks `routes.auto`, filtering on:
   - channel enabled (catalog says it's known, env keys present, etc.)
   - channel healthy (no active cooldown)
   - budget — if daily USD > ceiling, only `isFree` channels remain
5. `freellmapi-client.chatCompletion(choice, messages)` issues POST `/v1/chat/completions`
6. On success: `costTracker.append(usage)` + `router.recordSuccess(choice, usage)`
7. On HTTP failure: `router.recordFailure(choice, {status})` — cooldown starts; retry up to `maxAttempts`
8. Result printed: text + metadata block (channel, model, tokens, usd, latency)

## Channel catalog

`scripts/agentic-os/lib/model-router.js` exports `CHANNEL_CATALOG`, a frozen map of channel name → `{provider, model, isLocal, isFree, requiresLocalEndpoint, requiresFreellmapi}`. Adding a channel is a one-line entry there + (optionally) a cost row in `cost-tracker.js`.

Current channels:
- `local` (auto, local OpenAI-compatible URL)
- `freellmapi-free` (auto via the proxy)
- `anthropic-haiku`, `anthropic-sonnet`, `anthropic-opus`
- `openai-mini`, `openai-gpt4o`
- `gemini-flash`, `gemini-pro`

## Routes

Routes are ordered channel lists. The router picks the first healthy enabled candidate. Defaults:

```json
{
  "auto":      ["local", "freellmapi-free", "anthropic-haiku", "openai-mini", "gemini-flash"],
  "fast":      ["freellmapi-free", "anthropic-haiku", "gemini-flash"],
  "deep":      ["anthropic-opus", "anthropic-sonnet", "openai-gpt4o", "gemini-pro"],
  "free-only": ["local", "freellmapi-free"]
}
```

## Persistence

| File | Purpose |
|---|---|
| `~/.agentic-os/config.json` | user override of repo default |
| `~/.agentic-os/queue.json` | persistent task queue (JSON array, atomic writes) |
| `~/.agentic-os/cost-log.jsonl` | append-only spend log |
| `~/.agentic-os/harness.pid` | daemon PID for stop/status |
| `~/.agentic-os/freellmapi/` | cloned proxy + its SQLite key store |
| `data/agentic-os/reflections.jsonl` | repo-tracked optional reflections |

## Failure model

- **Provider 429 / 5xx / timeout** → `router.recordFailure` sets `cooldownUntil = now + 60s` for that channel; harness retries on the next candidate.
- **All channels in cooldown** → `RouterError('no healthy channels for route X')`; harness returns exit 1 with structured error.
- **Budget exceeded mid-day** → next `pick()` filters to `isFree` channels only; surfaced in `--status` output.
- **freellmapi unreachable** → channel `freellmapi-free` returns error → cooldown → harness falls through to cloud channels.
- **Local endpoint not configured** → channel `local` is disabled (filtered out at `isChannelEnabled`).

## Future extensions (deferred from MVP)

| Item | Note |
|---|---|
| Additional specialist agents (`@dev`, `@writer`, `@researcher`, `@ops`) | Per the `agentic-os` skill — the current MVP ships kernel + executor only |
| MCP wrapper around freellmapi | Adds a layer with no benefit; skipped |
| Real-time cost projection on `pick()` | Today we only sum recorded spend |
| Multi-key sharding for freellmapi | Lives in freellmapi itself |
| Reflection-driven route reordering | Reflections are logged but not yet fed back into routing |
| Computer-use / browser-use channel | The catalog has a slot for it; implementation deferred |
