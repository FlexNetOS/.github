# Agentic-OS — Deploy

## Requirements

| Tool | Min version | Notes |
|---|---|---|
| Node.js | 20+ | required by freellmapi; harness itself works on 18+ |
| npm | bundled with Node | required for freellmapi install |
| git | any modern | for cloning freellmapi |
| systemd (Linux) | optional | only if you want background daemon mode |

This was developed and tested on Linux (Ubuntu/Resolute). The harness is pure Node and should run on macOS/Windows as well — the lifecycle shell scripts are POSIX `bash`. Windows users invoke `harness.js` directly.

## One-time bootstrap

```bash
bash scripts/agentic-os/bootstrap.sh
```

This is **idempotent and user-space only**. It will:

1. Verify Node 20+, npm, git.
2. Clone `FlexNetOS/freellmapi` into `~/.agentic-os/freellmapi/`. Re-runs `git pull --ff-only`.
3. Run `npm install` inside that clone.
4. Generate `.env` with a fresh `ENCRYPTION_KEY` (only if missing).
5. Copy `config/agentic-os/default.json` → `~/.agentic-os/config.json` (only if missing).

## Start freellmapi

In a **separate** terminal:

```bash
cd ~/.agentic-os/freellmapi
npm run build
node server/dist/index.js     # production: server + dashboard both on :3001
```

For development / hot-reload:

```bash
cd ~/.agentic-os/freellmapi
npm run dev                   # dashboard on :5173, API on :3001
```

Open the dashboard, add provider keys (Google, Groq, Cerebras, SambaNova, etc.), reorder the fallback chain, then copy the unified key from the **Keys** page header.

## Wire the unified key into harness config

Edit `~/.agentic-os/config.json`:

```json
{
  "freellmapi": {
    "endpoint": "http://localhost:3001/v1",
    "apiKey": "freellmapi-XXXXXXXXXXXX"
  }
}
```

Or use the env override:

```bash
export AGENTIC_FREELLMAPI_KEY=freellmapi-XXXXX
```

## Optional cloud routing

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...
export GEMINI_API_KEY=AIza...
```

Put these in `~/.bashrc` or a `direnv` `.envrc`. The harness reads them at startup.

## Local model (Ollama / llama.cpp / vLLM)

The router treats local as just-another-OpenAI-compatible-base-url. Set in config:

```json
{ "localEndpoint": "http://localhost:11434/v1" }   // Ollama
{ "localEndpoint": "http://localhost:8080/v1" }    // llama.cpp
{ "localEndpoint": "http://localhost:8000/v1" }    // vLLM
```

Or via env: `export AGENTIC_LOCAL_ENDPOINT=http://localhost:11434/v1`.

The harness does not install or manage local stacks. Stand them up separately.

## Run the daemon

### Foreground

```bash
bash scripts/agentic-os/start.sh
```

Logs to stdout/stderr. Ctrl-C to stop, or `bash scripts/agentic-os/stop.sh` from another shell.

### systemd --user (background, auto-restart)

**Important — portability footgun:** the shipped unit file has `WorkingDirectory=%h/_work/repos/everything-claude-code`. That's the repo path on the maintainer's box. If your clone lives anywhere else (`~/projects/ecc`, `~/code/everything-claude-code`, etc.) you **must** edit the `WorkingDirectory=` line **before** symlinking, or systemd will refuse to start the service with `chdir` errors.

Easiest path: copy (don't symlink) the unit and rewrite the path with `sed`:

```bash
mkdir -p ~/.config/systemd/user
sed "s|%h/_work/repos/everything-claude-code|$(pwd)|" \
    scripts/agentic-os/systemd/ecc-agentic-os.service \
    > ~/.config/systemd/user/ecc-agentic-os.service

systemctl --user daemon-reload
systemctl --user enable --now ecc-agentic-os.service

# observe
systemctl --user status ecc-agentic-os.service
journalctl --user -u ecc-agentic-os.service -f
```

If you do prefer a symlink (so future git pulls update it), first edit the unit's `WorkingDirectory=` to your actual repo path, then:

```bash
ln -sf "$(pwd)/scripts/agentic-os/systemd/ecc-agentic-os.service" \
       ~/.config/systemd/user/ecc-agentic-os.service
systemctl --user daemon-reload
```

The unit:
- runs as your user (no root)
- restricts writes to `~/.agentic-os/` and `data/agentic-os/`
- caps memory at 512 MB and CPU at 50%
- auto-restarts on failure with a 10s back-off

## Ports

| Port | Service | Bound to |
|---|---|---|
| 3001 | freellmapi server + dashboard (prod) | `127.0.0.1` by default; do not expose |
| 5173 | freellmapi dashboard (dev) | `127.0.0.1` |
| 11434 | Ollama (if you run it) | `127.0.0.1` |

The harness itself does **not** listen on any port. It's a CLI / daemon that makes outbound HTTP calls only.

## Env variables the harness understands

| Var | Effect |
|---|---|
| `ECC_AGENTIC_OS_CONFIG` | absolute path to a config file (overrides discovery) |
| `AGENTIC_LOCAL_ENDPOINT` | overrides `localEndpoint` |
| `AGENTIC_FREELLMAPI_URL` | overrides `freellmapi.endpoint` |
| `AGENTIC_FREELLMAPI_KEY` | overrides `freellmapi.apiKey` |
| `AGENTIC_BUDGET_USD` | overrides `budget.dailyUsd` |
| `ANTHROPIC_API_KEY` | enables anthropic-* channels |
| `OPENAI_API_KEY` | enables openai-* channels |
| `GEMINI_API_KEY` | enables gemini-* channels |

## Verify

```bash
node scripts/agentic-os/harness.js --status
node scripts/agentic-os/harness.js --probe --route auto
node scripts/agentic-os/harness.js --task "say hi" --route auto
node tests/run-all.js   # all 45 agentic-os tests must pass
```

## When to upgrade

- New free providers added to freellmapi → `cd ~/.agentic-os/freellmapi && git pull && npm install && npm run build` then restart.
- New channels in this repo → restart the daemon to pick them up.
- Updating `config/agentic-os/default.json` does NOT overwrite your `~/.agentic-os/config.json` — overlays only.
