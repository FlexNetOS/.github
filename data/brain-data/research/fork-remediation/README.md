# Fork Remediation — Dirty State Snapshots

Captured 2026-05-28. These three repos were set up from forks (Vision sequence
violated: fork-first instead of clone→research→setup→fork). The dirty working
trees represent FlexNetOS customizations that must be reapplied to the
`develop` branch after each repo is remediated via the correct sequence.

## Contents

| File/Dir | Repo | Type |
|---|---|---|
| `everything-claude-code.patch` | `affaan-m/everything-claude-code` | `git diff HEAD` of 20 tracked files |
| `ecc-untracked/` | same | Full copy of 12 untracked items (agentic-os subsystem) |
| `oh-my-claudecode.patch` | `yeachan-heo/oh-my-claudecode` | `git diff HEAD` of 3 CLAUDE.md files |
| `oh-my-pi.patch` | `can1357/oh-my-pi` | `git diff HEAD` of Cargo.lock + bun.lock |
| `agentic-os-executor.md` | ecc | untracked agent (flat copy — superseded by ecc-untracked/) |
| `agentic-os-kernel.md` | ecc | untracked agent (flat copy — superseded by ecc-untracked/) |
| `agentic-os.md` | ecc | untracked command (flat copy — superseded by ecc-untracked/) |
| `agentic-route.md` | ecc | untracked command (flat copy) |
| `agentic-status.md` | ecc | untracked command (flat copy) |
| `agentic-task.md` | ecc | untracked command (flat copy) |

## What the dirty state means

### everything-claude-code
- Agent/command counts bumped: 60→62 agents, 75→79 commands (agentic-os added)
- Boil-the-Ocean mandate prepended to all CLAUDE.md variants (root + all locale docs)
- `agentic-os` registered in `agent.yaml`
- `yarn.lock` regenerated
- New agentic-os subsystem: 2 agents, 4 commands, config, docs, scripts, tests

### oh-my-claudecode
- Boil-the-Ocean mandate prepended to 3 CLAUDE.md files
  (root, `.github/CLAUDE.md`, `docs/CLAUDE.md`)

### oh-my-pi
- `Cargo.lock`: `pi-natives` crate refactored — split into `pi-ast` + `pi-shell` + `pi-natives`
- `bun.lock`: `tailwindcss` moved from devDependencies to dependencies in one package

## Remediation procedure (per repo)

1. Fresh clone from true upstream onto a feature branch
2. `make research.pack URL=<upstream>` → write dossier at `data/brain-data/research/<name>.md`
3. Verify original works as-is
4. `gh repo fork <upstream> --org FlexNetOS --clone=false`
5. Point local clone at fork: `git remote rename origin upstream && git remote add origin <fork-url>`
6. Create develop branch: `git checkout -b develop`
7. Apply patch: `git apply <name>.patch` (plus copy `ecc-untracked/` contents for ecc)
8. Commit + push develop to fork
9. Register in MANIFEST with `branch: develop`, update from `branch: main`
10. `make submodules.add`
