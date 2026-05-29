# Slim review

Repository: https://github.com/nilbuild/slim

## Decision

Pin Slim source in this repo as `network/slim`, then install and test it separately. Do not let installation side effects be hidden inside a source commit.

## Why Slim is useful

Slim can give local services stable HTTPS/domain names so humans and agents can say `workspace.test` instead of `127.0.0.1:3090`.

That fits the LifeOS direction: local services become named surfaces, not random ports.

## Trust boundary

Slim is network infrastructure, not a normal application dependency.

Treat it as privileged because it may touch some combination of:

- local DNS or hosts routing
- local HTTPS certificates
- local root CA trust
- privileged ports or proxy listeners
- long-running daemons

## Rules

- Do not pipe remote install scripts directly into a shell.
- Inspect install/build scripts before running them.
- Keep the reviewed source revision pinned as a submodule.
- Keep generated certs, local CA private keys, logs, PID files, and machine-specific config out of git.
- Test one mapping first: `workspace.test -> http://127.0.0.1:3090`.
- Prefer `.test` for local-only domains.
- Use Tailscale for remote/tailnet reachability; use Slim for local domain/HTTPS ergonomics.

## Rollout gates

1. Source pin exists: `network/slim` submodule.
2. Installer/build path inspected.
3. `slim --version` works, if a binary is installed.
4. `network/scripts/slim-doctor.sh` passes or clearly reports missing prerequisites.
5. Only `workspace.test` is mapped first.
6. Browser/curl verification passes.
7. Add more services from `network/service-map.yaml` one at a time.

## Non-goals

This plan does not commit OS trust-store changes, generated certificates, or `/etc/hosts` content. Those are machine-local runtime state.
