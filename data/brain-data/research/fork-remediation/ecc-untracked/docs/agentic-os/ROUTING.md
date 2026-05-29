# Agentic-OS — Routing

## Channel catalog

A **channel** is a `(provider, model, endpoint)` triple. Channels are static metadata defined in `scripts/agentic-os/lib/model-router.js` under `CHANNEL_CATALOG`.

| Channel | Provider | Model | Cost tier | Notes |
|---|---|---|---|---|
| `local` | local | `auto` | free | needs `localEndpoint` set |
| `freellmapi-free` | freellmapi | `auto` (proxy decides) | free | needs `freellmapi.endpoint` |
| `anthropic-haiku` | anthropic | `claude-haiku-4-5-20251001` | cheap | needs `ANTHROPIC_API_KEY` |
| `anthropic-sonnet` | anthropic | `claude-sonnet-4-6` | mid | needs `ANTHROPIC_API_KEY` |
| `anthropic-opus` | anthropic | `claude-opus-4-7` | expensive | needs `ANTHROPIC_API_KEY` |
| `openai-mini` | openai | `gpt-4o-mini` | cheap | needs `OPENAI_API_KEY` |
| `openai-gpt4o` | openai | `gpt-4o` | mid | needs `OPENAI_API_KEY` |
| `gemini-flash` | gemini | `gemini-2.5-flash` | cheap | needs `GEMINI_API_KEY` |
| `gemini-pro` | gemini | `gemini-2.5-pro` | mid | needs `GEMINI_API_KEY` |

Adding a new channel: add an entry to `CHANNEL_CATALOG` and (optionally) a row in `COST_PER_MILLION_TOKENS` in `cost-tracker.js`. No other code change needed — the catalog is data-driven.

## Routes

A **route** is an ordered list of channel names. The router walks the list and picks the first channel that is **enabled** AND **healthy** AND (if budget exceeded) **free**.

### Default routes

`config/agentic-os/default.json`:

```json
{
  "routes": {
    "auto":      ["local", "freellmapi-free", "anthropic-haiku", "openai-mini", "gemini-flash"],
    "fast":      ["freellmapi-free", "anthropic-haiku", "gemini-flash"],
    "deep":      ["anthropic-opus", "anthropic-sonnet", "openai-gpt4o", "gemini-pro"],
    "free-only": ["local", "freellmapi-free"]
  }
}
```

### What each route is for

- **`auto`** — sensible default: try local first (zero cost, zero latency), then proxy free tier, then cheap cloud.
- **`fast`** — quick drafts; skip local to avoid the cold-start hit on heavy local models.
- **`deep`** — careful work; opt into paid models. Will refuse if budget exhausted.
- **`free-only`** — never pay; if both local and proxy are down, throws `NO_HEALTHY_CHANNELS`.

### Customizing routes

Override at `~/.agentic-os/config.json` — repo default is the base layer.

```json
{
  "routes": {
    "auto": ["local", "anthropic-haiku"],
    "code": ["local", "freellmapi-free", "anthropic-sonnet"]
  }
}
```

You can add new route names freely; the harness reads them by string lookup.

## Selection algorithm (concise)

```
pick(task):
    if task.sticky and stickyMap[task.sticky] is fresh and healthy:
        return that choice

    if budget.dailyUsd >= ceiling:
        candidates = routes[task.route].filter(isFree && enabled && healthy)
    else:
        candidates = routes[task.route].filter(enabled && healthy)

    if candidates empty: throw RouterError('no healthy channels')

    pick first candidate
    record sticky if task.sticky present
    return choice
```

## Health and cooldowns

- Each channel has an in-memory `cooldownUntil` timestamp.
- On 429 / 5xx / timeout / network error → `recordFailure` sets `cooldownUntil = now + cooldownMs` (default 60s).
- A channel in cooldown is skipped by `pick()` until the cooldown expires.
- `recordSuccess` clears the cooldown.
- Cooldowns are **not** persisted across daemon restarts. This is intentional — restarting probes fresh.

## Sticky sessions

For multi-turn conversations, pass `--sticky <id>` (e.g. session/thread id). The first `pick()` records the chosen channel; subsequent picks for the same sticky id return the same channel for up to `stickyTtlMs` (default 30 min).

Why: switching models mid-conversation produces a measurable hallucination spike. Sticky sessions avoid it.

## Budget

- Daily ceiling at `budget.dailyUsd` (default $2.00).
- Each successful completion adds `usd` (computed from `cost-tracker.estimateUsd`) to the day's accumulator.
- When the accumulator ≥ ceiling, `pick()` filters non-free channels out. `free-only` routes are unaffected.
- The day boundary is UTC midnight (`YYYY-MM-DD` from `Date.now()`).

## Tuning

| Want | Edit |
|---|---|
| Cheaper defaults | Reorder `auto` to put `freellmapi-free` before `anthropic-haiku` |
| Refuse all paid | Use `free-only` exclusively |
| Force local-first | Set `localEndpoint` and put `local` first in every route |
| Longer cooldown | Set `cooldownMs` in user config (e.g. 300000 for 5 min) |
| Disable a provider | Set `cloud.<provider>.enabled = false` |
| Different budget | Set `budget.dailyUsd` or export `AGENTIC_BUDGET_USD=N` |
