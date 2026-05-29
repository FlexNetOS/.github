# Agentic-OS

A persistent multi-agent runtime layered on top of Claude Code. Routes tasks across **local models**, the **freellmapi** free-tier proxy (10+ free LLM providers ~1.3B tokens/month), and the **Anthropic / OpenAI / Gemini** cloud APIs.

Status: **experimental MVP**, shipped during the ECC `v2.0.0-rc.1` window. User-space only — no sudo, no system services, no network changes.

## What it gives you

- A single CLI to fire one-shot tasks at a price/quality tier (`auto` / `fast` / `deep` / `free-only`)
- A persistent queue for asynchronous workloads
- Automatic fail-over between providers with cooldowns
- Sticky sessions for multi-turn flows
- A per-day USD budget with downgrade-to-free behavior when exceeded
- Append-only cost log (`~/.agentic-os/cost-log.jsonl`)
- Optional systemd `--user` unit for background operation

## Quick start

```bash
# 1. One-time setup (clones FlexNetOS/freellmapi into ~/.agentic-os/freellmapi)
bash scripts/agentic-os/bootstrap.sh

# 2. Start freellmapi (separate terminal)
cd ~/.agentic-os/freellmapi && npm run build && node server/dist/index.js

# 3. Add provider keys at the freellmapi dashboard, copy unified key into
#    ~/.agentic-os/config.json under freellmapi.apiKey

# 4. Fire a task
node scripts/agentic-os/harness.js --task "Summarize this README in 3 bullets" --route auto

# 5. Optional — run as a daemon
bash scripts/agentic-os/start.sh
```

## Documents

| Doc | What's in it |
|---|---|
| [DESIGN.md](DESIGN.md) | Architecture, data flow, layer responsibilities |
| [DEPLOY.md](DEPLOY.md) | Bootstrap, systemd unit, env vars, ports |
| [ROUTING.md](ROUTING.md) | Channel catalog and route configuration |
| [MODELS.md](MODELS.md) | Free-tier model catalog (freellmapi providers) |
| [ROLLBACK.md](ROLLBACK.md) | Complete uninstall instructions |
| [SECURITY.md](SECURITY.md) | Blast radius, budget cap, kill switch, sudo deltas |

## When NOT to use this

- You only want a single one-off chat — just use the Claude Code REPL.
- You want a hosted service — this is single-user, file-based, by design.
- You need GA reliability — this is `experimental` for the RC window.
- You need MCP wiring — explicitly skipped for MVP; freellmapi is plain HTTP.

## Where things live

```
agents/agentic-os-kernel.md                 # COO / router agent
agents/agentic-os-executor.md               # generic task executor
commands/agentic-os.md                      # /agentic-os
commands/agentic-task.md                    # /agentic-task
commands/agentic-route.md                   # /agentic-route
commands/agentic-status.md                  # /agentic-status
scripts/agentic-os/harness.js               # main daemon + CLI
scripts/agentic-os/lib/*                    # router, queue, cost, freellmapi client
scripts/agentic-os/{bootstrap,start,stop,status,uninstall}.sh
scripts/agentic-os/systemd/ecc-agentic-os.service
config/agentic-os/{default,routes.example,free-models}.json
tests/agentic-os/*.test.js                  # 45 unit tests
data/agentic-os/                            # repo-tracked reflections (optional)
~/.agentic-os/                              # runtime state (user-owned)
```

## Smoke test (no keys needed)

```
node tests/run-all.js
```

All 45 agentic-os tests must pass.
