---
description: Inspect or update the agentic-os routing table
argument-hint: <show|set|reset> [route-name] [channel,channel,...]
---

# /agentic-route

Manage the channel order for each route in the agentic-os harness.

**Input**: `$ARGUMENTS`

## Subcommands

| Form | Effect |
|---|---|
| `show` | Print all routes and the channels they fall through, with current health |
| `show <route>` | Detail one route |
| `set <route> <c1,c2,c3>` | Replace route's channel list at `~/.agentic-os/config.json` |
| `reset <route>` | Restore route from `config/agentic-os/default.json` |
| `reset all` | Reset every route to repo default |

## Available Channels

See `docs/agentic-os/ROUTING.md` and `scripts/agentic-os/lib/model-router.js` (CHANNEL_CATALOG).

Common selections:
- `local` — your Ollama / llama.cpp / vLLM endpoint
- `freellmapi-free` — the freellmapi proxy aggregating 10+ free-tier providers
- `anthropic-haiku` / `anthropic-sonnet` / `anthropic-opus`
- `openai-mini` / `openai-gpt4o`
- `gemini-flash` / `gemini-pro`

## Implementation

1. Read `config/agentic-os/default.json` (repo) + `~/.agentic-os/config.json` (user override).
2. For `show`: print merged view + call `harness.js --status` for current channel health.
3. For `set`: validate every channel name against the catalog; reject unknown channels with the full available list.
4. For `reset`: delete the user override for that route key.

## Examples

```
/agentic-route show
/agentic-route show deep
/agentic-route set auto local,freellmapi-free,anthropic-haiku
/agentic-route reset deep
```
