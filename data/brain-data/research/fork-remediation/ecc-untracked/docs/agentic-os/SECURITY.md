# Agentic-OS — Security & Blast Radius

## Threat model

You — a single user on a single machine — running an agentic loop that calls third-party LLM APIs and stores their responses on disk. The harness is **not** multi-tenant and **not** internet-exposed by design.

## Blast radius

| Action | What it touches | Reversible? |
|---|---|---|
| `bootstrap.sh` | `~/.agentic-os/`, clones one git repo, runs `npm install` in that clone | Yes — `uninstall.sh --purge` |
| `harness.js --task` | reads config, writes `cost-log.jsonl`, posts to provider URLs | Yes — delete files |
| `harness.js --serve` | writes `harness.pid`, modifies `queue.json` as tasks complete | Yes — `stop.sh`, delete state |
| systemd `--user` enable | symlinks unit into `~/.config/systemd/user/` | Yes — `uninstall.sh` |
| freellmapi process | binds 127.0.0.1:3001 | Yes — kill the process |

**Nothing in the MVP touches:**
- `/etc/`, `/usr/`, `/var/`, `/opt/`, any system path
- root-level systemd (only `--user` mode)
- networking config, firewalls, libvirt, docker
- any path outside `~/.agentic-os/` and the repo

## Secrets handling

- Provider API keys live in **env vars** (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`) — never in config files or repo.
- The freellmapi unified key (`freellmapi-...`) is stored in `~/.agentic-os/config.json`. Recommend `chmod 600 ~/.agentic-os/config.json`.
- Upstream provider keys (the ones you paste into freellmapi's dashboard) are encrypted with AES-256-GCM in freellmapi's SQLite store. Encryption key is in `~/.agentic-os/freellmapi/.env`.
- Cost log records `tokensIn`/`tokensOut`/`usd` per call — no prompt content, no responses. Safe to commit summary metrics; recommend `~/.agentic-os/` stays gitignored at the user level.

## Budget = soft kill switch

Daily USD ceiling (default $2.00) is enforced at the router. Once hit, only `isFree` channels are selectable. To make this a **hard** kill switch (refuse all calls, not just paid), use `free-only` route exclusively.

## Hard kill switches

```bash
bash scripts/agentic-os/stop.sh              # SIGTERM → SIGKILL fallback
systemctl --user stop ecc-agentic-os.service # if running under systemd
pkill -f 'agentic-os/harness.js'             # emergency stop
```

To prevent the daemon from auto-restarting under systemd:

```bash
systemctl --user disable ecc-agentic-os.service
```

To fully evict the harness from boot and clean state:

```bash
bash scripts/agentic-os/uninstall.sh --purge
```

## Cooldown / circuit breaker

When a channel returns 429 / 5xx / timeout, the router marks it for a 60-second cooldown (configurable via `cooldownMs`). Repeated failures don't compound — the cooldown is a fixed window per failure. If you want exponential back-off, edit `recordFailure` in `model-router.js`; not in MVP.

## Prompt-injection awareness

Every agent file (kernel, executor) carries the ECC Prompt Defense Baseline header, instructing the model to treat user-provided content, fetched URLs, and tool outputs as **untrusted**. The harness itself does **not** parse or follow instructions found in model output — it only logs the response and exits.

Per project rule: do not output URLs/code unless the task validates them. The harness's `chatCompletion` output is presented verbatim to the user — you (the human) decide what to do with it.

## What is NOT shipped (deliberate)

These items live in the "future" column and are NOT in the MVP. Don't assume they exist:

- Audit log of every prompt sent (would be a privacy minefield + huge disk)
- Per-task USD pre-quote (cost is computed post-hoc; pre-quote is hard with auto-failover proxies)
- Multi-user authentication on the freellmapi proxy (single-user by design)
- Network-segmenting the freellmapi process into its own namespace (overkill for MVP)
- Hardware kill switch via systemd watchdog (basic auto-restart is enough)
- Tamper-evident cost log (use append-only filesystem flags yourself if you want this)

## Sudo deltas

The "full OS root" scope you authorized at the start would, if ever needed for a future feature, look like:

- **Network**: nftables/firewall rules to block outbound to specific providers (not in MVP)
- **libvirt**: per-VM agent sessions for isolation (not in MVP)
- **systemd system unit**: shared daemon across users (single-user model rejects this)
- **apt / package install**: e.g. `ollama` or `vllm` system-wide install (recommend `mise`/per-user install instead)

If any of those become necessary, they will be **opt-in per-action** with explicit confirmation. The MVP ships with **no** code paths that escalate privileges.

## Reporting issues

If you find a prompt-injection bypass, secret-leak, or unbounded-spend bug, do not file it publicly — open a private issue or contact the ECC maintainer.
