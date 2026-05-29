---
title: "Firecrawl Postgres DB Name Gotcha"
tags: ["firecrawl", "postgres", "pg_cron", "gotcha", "docker"]
created: 2026-05-19T20:31:16.176Z
updated: 2026-05-19T20:31:16.176Z
sources: ["apps/nuq-postgres/Dockerfile", "session 2026-05-19 build failure"]
links: ["firecrawl-self-hosted-setup.md"]
category: debugging
confidence: high
schemaVersion: 1
---

# Firecrawl Postgres DB Name Gotcha

# Firecrawl Postgres DB Name Gotcha

**TL;DR:** In `.env`, `POSTGRES_DB` must remain `postgres`. Any other value crashes the `nuq-postgres` container during init.

## Symptom
```
nuq-postgres-1 | psql:/docker-entrypoint-initdb.d/010-nuq.sql:2: ERROR: can only create extension in database postgres
nuq-postgres-1 | DETAIL: Jobs must be scheduled from the database configured in cron.database_name, since the pg_cron background worker reads job descriptions from this database.
```
Container exits with code 3. The `api` container then crashes with `getaddrinfo ENOTFOUND nuq-postgres` because the postgres container is gone.

## Root cause
`apps/nuq-postgres/Dockerfile` hardcodes the pg_cron config:
```dockerfile
printf "\n# Added for pg_cron\ncron.database_name = 'postgres'\n" >> "$conf_sample"
```
This goes into `postgresql.conf.sample`, which is templated into `postgresql.conf` at initdb time. `pg_cron` requires that `CREATE EXTENSION pg_cron` be run inside the database named in `cron.database_name`, so the init script (`010-nuq.sql`) only works when `POSTGRES_DB=postgres`.

## Fix
In `/home/drdave/_work/repos/firecrawl/.env`:
```
POSTGRES_USER=postgres
POSTGRES_DB=postgres
POSTGRES_PASSWORD=<your strong password>
POSTGRES_HOST=nuq-postgres
POSTGRES_PORT=5432
```
Then wipe the bad volume and re-create:
```bash
docker compose down -v   # -v REMOVES the postgres data volume
docker compose up -d
```

## If you really want a custom DB name
Either:
1. Modify `apps/nuq-postgres/Dockerfile` to use the same env var when setting `cron.database_name`, OR
2. Edit `apps/nuq-postgres/nuq.sql` so `CREATE EXTENSION pg_cron` runs against the `postgres` DB explicitly, then the rest against `${POSTGRES_DB}`.

Both are upstream-fragile — easier to just leave the DB name as `postgres` for self-hosted.

Cross-ref: [[firecrawl-self-hosted-setup]].

