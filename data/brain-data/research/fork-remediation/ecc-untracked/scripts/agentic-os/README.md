# scripts/agentic-os

Runtime for the **agentic-os harness** — a persistent multi-agent layer on top of Claude Code that routes tasks across local models, the [freellmapi](https://github.com/FlexNetOS/freellmapi) free-tier proxy, and the Anthropic / OpenAI / Gemini cloud APIs.

## Files

| File | Purpose |
|---|---|
| `harness.js` | Main daemon + one-shot CLI. Modes: `--task`, `--enqueue`, `--serve`, `--status`, `--probe`. |
| `bootstrap.sh` | Clone freellmapi, install deps, generate encryption key, write default config. **No sudo.** |
| `start.sh` | Start the daemon in the foreground. |
| `stop.sh` | Stop the daemon (SIGTERM → SIGKILL fallback). |
| `status.sh` | Human-readable status snapshot. |
| `uninstall.sh` | Remove systemd unit; `--purge` wipes `~/.agentic-os/`. |
| `systemd/ecc-agentic-os.service` | User systemd unit (no root). |
| `lib/model-router.js` | Picks a channel per task; tracks health, cooldowns, budget, sticky sessions. |
| `lib/freellmapi-client.js` | OpenAI-compatible HTTP client. |
| `lib/task-queue.js` | Persistent JSON task queue. |
| `lib/cost-tracker.js` | Append-only JSONL cost log + summary. |
| `lib/state.js` | Generic atomic JSON state read/write. |
| `lib/config.js` | Config loader with env override. |

## Quick start

```bash
bash scripts/agentic-os/bootstrap.sh         # one-time setup
# (start freellmapi separately: cd ~/.agentic-os/freellmapi && npm run build && node server/dist/index.js)
node scripts/agentic-os/harness.js --task "say hi" --route auto
bash scripts/agentic-os/start.sh             # daemon (foreground)
```

## Architecture

See `docs/agentic-os/DESIGN.md`. TL;DR:

```
[ kernel agent ] → harness.js --task → ModelRouter.pick(task)
                                       │
                                       ├─ local  (OpenAI-compat)
                                       ├─ freellmapi-free (proxy → 14 free providers)
                                       └─ anthropic / openai / gemini direct
                                       │
                                       ▼
                                  chat completion
                                       │
                                       ▼
                            cost log + reflection + result
```

## Where data lives

- `~/.agentic-os/config.json` — user override of repo default
- `~/.agentic-os/queue.json` — persistent task queue
- `~/.agentic-os/cost-log.jsonl` — append-only spend log
- `~/.agentic-os/harness.pid` — daemon PID file
- `~/.agentic-os/freellmapi/` — cloned proxy + its SQLite key store
- `data/agentic-os/reflections.jsonl` — per-run reflections (repo-tracked, optional)

## Safety

The harness writes to `~/.agentic-os/` and `data/agentic-os/`. Nothing else. No sudo, no system services, no network changes. The systemd unit runs `--user` mode.
