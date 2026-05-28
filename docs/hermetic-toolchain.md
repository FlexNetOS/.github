# Hermetic toolchain conversion

This repo is moving toward a "fresh OS zip extract" operating model:

1. Start from a machine with no project-specific tools installed.
2. Extract the repo archive.
3. Run repo-local scripts and repo-local tool assets only.
4. Avoid global package managers, PATH edits, system installs, and runtime downloads.
5. Where practical, every toolchain, tool, dependency, and deep dependency is tracked as
   a git submodule or committed repo asset with an explicit version.

## Desired end state

- `tools/` contains the repo-owned toolchain graph.
- `tools/MANIFEST.yaml` records every repo-local tool source, pin, platform, and purpose.
- `scripts/` invokes tools through repo-relative paths, never global PATH discovery first.
- CI workflows call the same repo-local scripts that humans run locally.
- Legacy runtime requirements, such as Node 20-only actions, are treated as bugs in the
  tool. The fix is to update, fork, vendor, or submodule the tool so it runs on the
  latest stable runtime.

## Phase 1: stop avoidable runtime downloads

This phase replaces simple verifier dependencies with repo-local scripts:

- `scripts/verify-manifest.py` replaces CI/local `yq` for `repos/MANIFEST.yaml` checks.
- `scripts/verify-markdown.py` replaces CI/local `npx markdownlint-cli2` for the rules we
  currently enforce in this umbrella repo.
- `scripts/hermetic-audit.py` reports workflow/script patterns that still fetch tools,
  install into system paths, or depend on global commands.

These scripts use Python standard library only. Python itself is still a host dependency
until the CPython/toolchain submodule path is materialized.

## Phase 2: remove yq from submodule automation and seed tool sources

This phase adds `scripts/manifest-query.py`, a small shell-friendly TSV query
surface for the same manifest subset validated by `scripts/verify-manifest.py`.
It replaces yq in:

- `scripts/submodule-add-all.sh`
- `scripts/submodule-bump.sh`
- `scripts/submodule-sync-upstream.sh`
- `runner/ephemeral-spawn.sh`
- `.github/workflows/reusable-submodule-bump.yml`

It also materializes shallow source submodules for the first repo-local toolchain
seeds: actionlint, gitleaks, Trivy, Node, Bun, uv, and CPython. These are source
pins, not yet runnable hermetic binaries.

## Phase 3: repo-local wrappers for pinned security/lint binaries

This phase adds `tools/assets.json` and `scripts/toolchain.py` as the first
pinned binary materialization path. The committed JSON records release URLs,
versions, and SHA-256 checksums for Linux x64 archives. Generated archives and
extracted binaries live under `tools/.cache/` and are verified before every first
use.

Repo-local wrappers now exist for:

- `tools/bin/actionlint`
- `tools/bin/gitleaks`
- `tools/bin/trivy`

`Makefile`, self-CI actionlint, reusable actionlint, reusable Gitleaks, and
reusable Trivy now call those wrappers instead of installing tools globally or
using remote action wrappers for those scanners.

## Remaining debt after Phase 3

Known non-hermetic surfaces that still need conversion:

- GitHub-hosted actions such as `actions/checkout`, CodeQL, and upload-artifact
  still execute remote action bundles.
- Reusable language workflows still use setup actions and language package
  managers for caller repositories that actually contain Node, Bun, Python, or
  Rust projects.
- `scripts/toolchain.py` still performs a network fetch when a pinned archive is
  absent from `tools/.cache/`; this is checksum-verified but not yet a fully
  offline zip-extract path.
- Trivy may still download/update its vulnerability database at runtime unless a
  runner cache or repo-owned DB mirror is added.
- CPython, Node, Bun, and uv source submodules are present, but executable
  wrappers/build outputs still need to be added before those runtimes are truly
  repo-local.

## Conversion rule

When a tool is needed, prefer this order:

1. repo-local executable or script under `tools/` or `scripts/`
2. git submodule pointing to the tool source/binary-builder repo
3. pinned in-repo release asset with checksum
4. temporary network download only when captured by `scripts/hermetic-audit.py` as debt

No new workflow should add an untracked global install or opaque runtime download without
also adding an entry to the audit/manifest plan.
