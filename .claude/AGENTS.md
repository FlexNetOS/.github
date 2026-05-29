<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-28 -->

# .claude/

## Purpose
Claude Code configuration for the FlexNetOS/.github umbrella. Contains skills, hooks, session config, settings, and agent definitions used by Claude Code in this project.

## Key Files

| File | Description |
|------|-------------|
| `settings.json` | Project Claude Code settings — permissions, hooks, environment |
| `settings.local.json` | Local overrides (not committed) |
| `settings.canonical.json` | Canonical reference for settings structure |
| `ecc-tools.json` | ECC tool registry |
| `identity.json` | Project identity metadata |
| `.doctor-allowlist` | Allowlist for `make claude.doctor` portable-path checks |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `skills/` | Local project skills (clone-setup, wrap-up, etc.) |
| `plugins/` | Installed Claude Code plugins (cached) |
| `projects/` | Per-project persistent memory |
| `agents/` | Agent definitions |
| `session-env/` | Session environment snapshots |
| `homunculus/` | Homunculus agent config |
| `ide/` | IDE integration config |
| `downloads/` | Cached downloads |
| `.omc/` | OMC state for Claude config work |

## For AI Agents

### Working In This Directory
- `settings.json` is tracked; `settings.local.json` is gitignored
- Run `make claude.doctor` after any settings change to catch hardcoded paths
- Never add absolute user-home paths to tracked settings files — use portable refs (`$HOME`, `~/`)
- Skills in `skills/` are invoked via `/skill-name` in Claude Code

### Testing Requirements
- `make claude.doctor` must exit 0 (no hardcoded paths in tracked config)
- `make config.doctor` for combined Claude + Codex check

### Common Patterns
- Hooks live in `settings.json` under `hooks` key
- Permissions in `settings.json` under `permissions.allow`
