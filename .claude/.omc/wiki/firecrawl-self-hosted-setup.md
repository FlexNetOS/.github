---
title: "Firecrawl Self-Hosted Setup"
tags: ["firecrawl", "docker", "self-host", "setup", "scraping"]
created: 2026-05-19T20:30:57.904Z
updated: 2026-05-19T20:30:57.904Z
sources: ["SELF_HOST.md", "docker-compose.yaml", "session 2026-05-19"]
links: ["firecrawl-auto-restart-policy.md", "firecrawl-postgres-db-name-gotcha.md"]
category: environment
confidence: high
schemaVersion: 1
---

# Firecrawl Self-Hosted Setup

# Firecrawl Self-Hosted Setup

Self-hosted Firecrawl on this host (drdave-TRX50-AI-TOP), Docker-based.

## Instance URL
**`http://localhost:3002`** — open API, no API key required (USE_DB_AUTHENTICATION=false).

## Repo location
`/home/drdave/_work/repos/firecrawl` — cloned from `mendableai/firecrawl` (depth=1).

## Stack (5 containers)
| Container | Image | Role |
|---|---|---|
| `firecrawl-api-1` | `firecrawl-api` (locally built) | API + workers + harness, exposes `:3002` |
| `firecrawl-playwright-service-1` | `firecrawl-playwright-service` | Headless browser scraping |
| `firecrawl-redis-1` | `redis:alpine` | Session store, rate limit |
| `firecrawl-rabbitmq-1` | `rabbitmq:3-management` | Queue broker |
| `firecrawl-nuq-postgres-1` | `firecrawl-nuq-postgres` | NuQ job queue (Postgres + pg_cron) |

All 5 are set to `restart: unless-stopped` via [[firecrawl-auto-restart-policy]].

## Config files (created during setup)
- `.env` — required envs (PORT, HOST, USE_DB_AUTHENTICATION=false, BULL_AUTH_KEY, POSTGRES_*)
- `docker-compose.override.yaml` — adds the restart policy on top of upstream `docker-compose.yaml` (so `git pull` won't conflict)

## Bring up / tear down
```bash
cd /home/drdave/_work/repos/firecrawl
docker compose build          # build images (~5–10 min first time)
docker compose up -d          # start all containers
docker compose ps             # status
docker compose logs -f api    # tail api logs
docker compose down           # stop, keep volumes
docker compose down -v        # stop, wipe postgres volume (forces initdb on next up)
```

## Verify
```bash
curl -X POST http://localhost:3002/v1/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"]}'
# → {"success":true,"data":{"markdown":"Example Domain\n...","metadata":{...,"statusCode":200,...}}}
```

## Admin queue UI
`http://localhost:3002/admin/<BULL_AUTH_KEY>/queues` — secret lives in `.env`.

## Known gotchas
- **POSTGRES_DB must stay `postgres`** — see [[firecrawl-postgres-db-name-gotcha]].
- Many "variable not set" warnings on `docker compose` commands are benign (Supabase, OpenAI, proxy, SearXNG etc. — all optional for self-hosted).

