# Agentic-OS — Rollback

Complete uninstall, ordered by destructiveness (least → most).

## Level 1 — Stop, keep state

Stops the daemon. Preserves config, queue, cost log, and the freellmapi clone — so you can restart any time.

```bash
bash scripts/agentic-os/stop.sh
# or
systemctl --user stop ecc-agentic-os.service
```

## Level 2 — Disable auto-start

```bash
systemctl --user disable ecc-agentic-os.service
```

The unit symlink stays in place but won't start at boot or on demand.

## Level 3 — Remove systemd unit (default uninstall)

```bash
bash scripts/agentic-os/uninstall.sh
```

Effects:
- Stops the daemon (see Level 1)
- `systemctl --user disable --now ecc-agentic-os.service`
- Removes `~/.config/systemd/user/ecc-agentic-os.service`
- Reloads user systemd
- **Preserves** `~/.agentic-os/` (config, queue, cost log, freellmapi clone)

## Level 4 — Full purge (destroys all state)

```bash
bash scripts/agentic-os/uninstall.sh --purge
```

Everything from Level 3, plus:
- `rm -rf ~/.agentic-os/` — removes:
  - `config.json` (your unified key + provider settings)
  - `queue.json` (pending tasks lost)
  - `cost-log.jsonl` (historical spend lost)
  - `harness.pid`
  - `freellmapi/` (proxy clone, its `.env` with ENCRYPTION_KEY, its SQLite key store — **all upstream provider keys you added go with it**)

If you want to keep the freellmapi clone and just wipe harness state, do it manually:

```bash
rm -f ~/.agentic-os/{config,queue,harness.pid}.json ~/.agentic-os/cost-log.jsonl
```

## Level 5 — Remove the in-repo files

If you want to wipe the agentic-os subsystem from the repo entirely, the files to remove are:

```
agents/agentic-os-kernel.md
agents/agentic-os-executor.md
commands/agentic-os.md
commands/agentic-task.md
commands/agentic-route.md
commands/agentic-status.md
scripts/agentic-os/                    (entire directory)
config/agentic-os/                     (entire directory)
tests/agentic-os/                      (entire directory)
docs/agentic-os/                       (entire directory, including this file)
data/agentic-os/                       (entire directory)
```

That's a no-op if you haven't enabled it — none of those touch system or other-feature state.

The skill source `skills/agentic-os/SKILL.md` and `skills/autonomous-agent-harness/SKILL.md` are the **upstream** ECC skills — leave them alone unless you also want to remove the skill definitions.

## Confirm the box is clean

```bash
ls -la ~/.agentic-os/                            # should be missing or empty
systemctl --user status ecc-agentic-os.service   # should say "not-found"
pgrep -fl 'agentic-os/harness.js' || echo "no processes"
ls -la ~/.config/systemd/user/ | grep ecc        # should be empty
```

## Recovery

If you purged and want to start over:

```bash
bash scripts/agentic-os/bootstrap.sh
```

The clone, install, and config regen will run again.
