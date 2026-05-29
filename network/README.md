# Network control plane

This directory defines the local network layer for FlexNetOS / LifeOS / Hermes / Aster.

The goal is simple: people and agents should use stable local service names instead of memorizing raw ports.

## Doctrine

- Raw ports are implementation details.
- `.test` domains are the human-facing local names.
- `service-map.yaml` is the source of truth for local domains, ports, health checks, and ownership notes.
- `network/slim/` pins the trusted Slim source as a git submodule.
- Runtime state stays out of git: generated certs, local root CA private keys, `/etc/hosts` changes, logs, PID files, and machine-specific Slim config are never committed.
- Start with one safe mapping, verify, then expand.

## Layout

```text
network/
├── README.md
├── MANIFEST.yaml
├── service-map.yaml
├── slim/                  # git submodule: https://github.com/nilbuild/slim
├── scripts/
│   ├── slim-doctor.sh
│   └── slim-status.sh
└── docs/
    ├── local-domains.md
    ├── slim-review.md
    └── tailscale-vs-slim.md
```

## Layers

1. Source pin: `network/slim` records exactly which Slim source revision we reviewed.
2. Local install: a Slim binary may be installed in `~/.local/bin` or `/usr/local/bin`, depending on the chosen install path.
3. Runtime state: certificates, trust-store entries, host mappings, and daemon state live in OS/user runtime locations, not in this repository.

## First safe rollout

1. Review `network/docs/slim-review.md`.
2. Add or update `network/service-map.yaml`.
3. Install Slim only after inspecting the installer/build path.
4. Map only `workspace.test -> http://127.0.0.1:3090` first.
5. Run `network/scripts/slim-doctor.sh`.
6. Run `network/scripts/slim-status.sh`.
7. Expand the map one service at a time.
