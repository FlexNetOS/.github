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

## Remaining debt after Phase 1

Known non-hermetic surfaces that still need conversion:

- GitHub-hosted actions such as `actions/checkout`, `actions/setup-node`, CodeQL, Trivy,
  and upload-artifact execute remote action bundles.
- Reusable language workflows still use setup actions and language package managers for
  caller repositories.
- `scripts/bootstrap.sh` still needs a follow-up mode that locates repo-local tools before
  checking the host.
- The manifest describes many submodules, but `.gitmodules` is not yet materialized in
  this checkout.

## Conversion rule

When a tool is needed, prefer this order:

1. repo-local executable or script under `tools/` or `scripts/`
2. git submodule pointing to the tool source/binary-builder repo
3. pinned in-repo release asset with checksum
4. temporary network download only when captured by `scripts/hermetic-audit.py` as debt

No new workflow should add an untracked global install or opaque runtime download without
also adding an entry to the audit/manifest plan.
