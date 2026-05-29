---
description: Agentic OS top-level command — bootstrap, start/stop, status, task, route management
argument-hint: <bootstrap|start|stop|status|task|route|uninstall> [args...]
---

# /agentic-os

Top-level entry point for the agentic-os harness — a persistent multi-agent runtime layered on top of Claude Code that routes tasks across local models, the freellmapi free-tier proxy, and the Anthropic / OpenAI / Gemini cloud APIs.

**Input**: `$ARGUMENTS`

## Subcommands

| Subcommand | What it does |
|---|---|
| `bootstrap` | Clone freellmapi, install deps, generate encryption key, write default config |
| `start` | Start the harness daemon (foreground or via systemd --user) |
| `stop` | Stop the daemon, leaving queue + cost log intact |
| `status` | Print router health, queue stats, last-24h cost |
| `task <prompt>` | Enqueue and (optionally) run a single prompt one-shot |
| `route <name>` | Inspect or change route order in `~/.agentic-os/config.json` |
| `probe [--route auto]` | Hit the `models` endpoint on the picked channel to verify connectivity |
| `uninstall` | Remove daemon, leave config + logs (purge requires `--purge`) |

## Bootstrap (first-run setup)

```bash
bash scripts/agentic-os/bootstrap.sh
```

Effects:
1. Verify Node.js ≥ 20 and `npm` are available.
2. Clone `FlexNetOS/freellmapi` into `$HOME/.agentic-os/freellmapi/` if not present.
3. `npm install` inside that clone (writes nothing outside `$HOME/.agentic-os/`).
4. Generate `.env` with `ENCRYPTION_KEY=$(openssl rand -hex 32)`.
5. Copy `config/agentic-os/default.json` → `~/.agentic-os/config.json` if missing.
6. Print provider-key instructions (env var names + dashboard URL).

**No sudo**. **No network changes**. **No systemd**. Bootstrap is purely user-space.

## Start / Stop

```bash
# Foreground (Ctrl-C to stop)
bash scripts/agentic-os/start.sh

# Detached via systemd --user (after `systemctl --user daemon-reload`)
systemctl --user start ecc-agentic-os.service

# Stop
bash scripts/agentic-os/stop.sh
# or: systemctl --user stop ecc-agentic-os.service
```

Daemon mode loops on the queue at `$config.queuePath` (default `~/.agentic-os/queue.json`).

## One-Shot Task

```bash
node scripts/agentic-os/harness.js --task "Summarize this README in 3 bullets" --route auto
```

Returns the model's response followed by a metadata block (channel, model, tokens, usd, latency).

## Status / Health

```bash
node scripts/agentic-os/harness.js --status
```

Output JSON: `{ health: { channels: [...], budget: {...} }, queue: {...}, last24h: {...} }`.

## Routing

Routes are ordered lists of channels in `config/agentic-os/default.json`. Override at `~/.agentic-os/config.json`:

```json
{
  "routes": {
    "auto": ["local", "freellmapi-free", "anthropic-haiku"],
    "deep": ["anthropic-opus", "anthropic-sonnet"]
  }
}
```

See `docs/agentic-os/ROUTING.md` for the channel catalog.

## Uninstall

```bash
bash scripts/agentic-os/uninstall.sh           # remove daemon, keep data
bash scripts/agentic-os/uninstall.sh --purge   # also remove ~/.agentic-os/
```

Full rollback in `docs/agentic-os/ROLLBACK.md`.

## Safety

- The harness never writes outside `$HOME/.agentic-os/` and the repo.
- The daemon runs as `--user` systemd — no root, no system services.
- Budget cap defaults to **$2.00/day**; cap reached → router downgrades to free-only.
- Kill switch: `bash scripts/agentic-os/stop.sh` or `pkill -f 'agentic-os/harness'`.
