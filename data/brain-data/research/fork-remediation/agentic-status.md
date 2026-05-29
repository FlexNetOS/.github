---
description: Health, queue, and spend dashboard for the agentic-os harness
argument-hint: [--json] [--watch]
---

# /agentic-status

Print the current health of the agentic-os harness.

**Input**: `$ARGUMENTS`

## What Gets Reported

1. **Daemon state** — running PID, uptime (from `~/.agentic-os/harness.pid` mtime) or "not running".
2. **Channel health** — each channel: enabled, healthy/cooldown, success/failure count.
3. **Queue** — pending, running, done, failed.
4. **Cost (last 24h)** — total USD, total tokens, breakdown by channel.
5. **Budget** — used / ceiling.
6. **freellmapi reachability** — `GET` on the `models` endpoint at `http://localhost:3001/v1/models` returns 200 / fail.

## Implementation

```bash
node scripts/agentic-os/harness.js --status
node scripts/agentic-os/harness.js --probe --route auto
```

For `--watch`: re-run every 5 seconds. For `--json`: omit human-readable formatting; emit the raw JSON from `--status`.

## Example Output

```
agentic-os status @ 2026-05-21T14:22:00Z

Daemon       running (pid 18234, up 2h17m)
freellmapi   reachable (15 models advertised)
Local        not configured

Channels
  freellmapi-free  ✓ healthy   succ=18  fail=0
  anthropic-haiku  ✓ healthy   succ=4   fail=1
  openai-mini      ⏸ cooldown  until 14:23:12  (429)
  gemini-flash     ✗ disabled  (no GEMINI_API_KEY)

Queue        pending=2  running=0  done=18  failed=1

Last 24h     34 requests  74,210 tokens  $0.087
Budget       $0.087 / $2.00
```
