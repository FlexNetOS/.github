<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-28 -->

# tools/

## Purpose

Pinned tool wrappers and vendored upstream sources for hermetic CI. `tools/bin/` holds thin wrapper scripts that invoke pinned versions of each tool; `tools/<name>/` holds the pinned upstream source or binary.

## Key Files

| File | Description |
| --- | --- |
| `MANIFEST.yaml` | Tool asset manifest — pinned versions and expected SHA256 hashes for `make verify.tool-assets` |

## Subdirectories

| Directory | Purpose |
| --- | --- |
| `bin/` | Thin wrapper scripts: `actionlint`, `repomix`, `gitleaks`, `trivy` |
| `actionlint/` | Pinned actionlint binary (platform-specific) |
| `bun/` | Pinned Bun runtime |
| `cpython/` | CPython source (pinned upstream submodule) |
| `gitleaks/` | Pinned gitleaks binary for secret scanning |
| `node/` | Pinned Node.js runtime |
| `trivy/` | Pinned Trivy vulnerability scanner binary |
| `uv/` | Pinned uv Python package manager |
| `repomix/` | Gitignored local repomix clone (NOT a submodule) |

## For AI Agents

### Working In This Directory

- `tools/repomix/` is gitignored — it is a local clone, NOT registered in MANIFEST.yaml or .gitmodules
- To update a pinned tool: edit `tools/MANIFEST.yaml`, update the SHA256, run `make verify.tool-assets`
- Wrapper scripts in `tools/bin/` should be thin: just invoke the pinned binary with `$@`
- Never install tool binaries globally — they belong here under `tools/`

### Testing Requirements

- `make verify.tools` validates `tools/MANIFEST.yaml` structure
- `make verify.tool-assets` checks SHA256 hashes of pinned binaries
- Both must exit 0 before any PR

### Common Patterns

- Wrapper scripts: `#!/usr/bin/env bash` → exec the pinned binary path
- MANIFEST.yaml entries: `name`, `version`, `url`, `sha256`, `path`
