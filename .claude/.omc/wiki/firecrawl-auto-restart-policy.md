---
title: "Firecrawl Auto Restart Policy"
tags: ["firecrawl", "docker", "restart-policy", "resilience", "compose-override"]
created: 2026-05-19T20:31:30.319Z
updated: 2026-05-19T20:31:30.319Z
sources: ["docker-compose.override.yaml", "session 2026-05-19 verification"]
links: ["firecrawl-self-hosted-setup.md"]
category: decision
confidence: high
schemaVersion: 1
---

# Firecrawl Auto Restart Policy

# Firecrawl Auto Restart Policy

All 5 Firecrawl containers run with `restart: unless-stopped`, configured via a local Docker Compose override rather than editing the upstream `docker-compose.yaml`.

## Why an override file, not edit-in-place
Upstream `docker-compose.yaml` is tracked in git. Editing it would conflict with every future `git pull` from `mendableai/firecrawl`. Compose auto-merges `docker-compose.override.yaml` (default name) on every `up`/`build`, so the override travels with the local checkout without polluting upstream.

## The override
`/home/drdave/_work/repos/firecrawl/docker-compose.override.yaml`:
```yaml
name: firecrawl
services:
  api:                { restart: unless-stopped }
  playwright-service: { restart: unless-stopped }
  redis:              { restart: unless-stopped }
  rabbitmq:           { restart: unless-stopped }
  nuq-postgres:       { restart: unless-stopped }
```

## What `unless-stopped` covers
| Event | Auto-restart? |
|---|---|
| Container process crashes (segfault, OOM, internal panic) | ✅ Yes |
| Host process kills container PID directly (`kill -9 <hostpid>`) | ✅ Yes (verified — `restarts=1` in 2s) |
| Docker daemon restarts (host reboot) | ✅ Yes (daemon is `enabled` in systemd) |
| `docker stop` or `docker compose stop` | ❌ No (intentional stop) |
| `docker kill <container>` | ❌ No (Docker treats this as explicit stop; logs `"stopping restart-manager"`) |

## Verification commands
```bash
# 1. Confirm the policy is actually applied on each container
docker inspect --format '{{.Name}}: {{.HostConfig.RestartPolicy.Name}}' \
  $(docker ps --filter "name=firecrawl-" -q)

# 2. Real-world crash test — kill the host PID (NOT docker kill)
PID=$(docker inspect --format '{{.State.Pid}}' firecrawl-api-1)
sudo kill -9 $PID    # simulates unexpected crash
docker inspect --format '{{.RestartCount}}' firecrawl-api-1   # should become 1 within ~2s

# 3. Confirm daemon comes back after reboot
systemctl is-enabled docker   # → enabled
```

## Why `docker kill` doesn't trigger restart
Docker 29's `docker kill` API call explicitly tells the daemon "this was a user-initiated stop" — you'll see `level=info msg="stopping restart-manager"` in `journalctl -u docker.service`. Don't use it to test the restart policy. Use a host-level `kill -9` of the container's PID instead.

Cross-ref: [[firecrawl-self-hosted-setup]].

