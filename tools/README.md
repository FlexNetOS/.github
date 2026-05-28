# `tools/` — repo-local toolchain sources and pinned binaries

This directory now holds the first materialized pieces of the hermetic toolchain.
Each materialized source tool is a shallow git submodule pinned by this umbrella
repo, and the tools used by self-CI have repo-local wrappers under `tools/bin/`.

## Repo-local executable wrappers

| Wrapper | Backing asset | Purpose |
| --- | --- | --- |
| `tools/bin/actionlint` | `actionlint` release tarball | Lint GitHub Actions workflows. |
| `tools/bin/gitleaks` | `gitleaks` release tarball | Secret scanning without global install. |
| `tools/bin/trivy` | `trivy` release tarball | Filesystem and IaC scanning without the Trivy action wrapper. |

The wrappers call `scripts/toolchain.py`, which reads `tools/assets.json`, fetches
the pinned release archive only when the local cache is missing, verifies the
archive SHA-256, extracts the binary into `tools/.cache/bin/`, and then execs it.
Set `FLEXNETOS_NO_TOOL_DOWNLOAD=1` to force offline/cache-only operation.

Common commands:

```bash
# Materialize every pinned Linux x64 asset into tools/.cache/.
python3 scripts/toolchain.py ensure

# Run the same wrapper Make/CI use.
tools/bin/actionlint .github/workflows/*.yml

# Verify already downloaded archives against tools/assets.json.
python3 scripts/toolchain.py verify-assets
```

`tools/.cache/` is generated and intentionally not committed. The committed
pin/checksum data lives in `tools/assets.json`; the source-submodule graph lives
in `tools/MANIFEST.yaml` and `.gitmodules`.

## Materialized upstream toolchain submodules

| Path | Upstream | Purpose |
| --- | --- | --- |
| `tools/actionlint/` | `rhysd/actionlint` | GitHub Actions workflow lint source. |
| `tools/gitleaks/` | `gitleaks/gitleaks` | Secret scanning source. |
| `tools/trivy/` | `aquasecurity/trivy` | Filesystem and IaC scanner source. |
| `tools/node/` | `nodejs/node` | Latest-stable Node runtime source. |
| `tools/bun/` | `oven-sh/bun` | Bun runtime/package manager source. |
| `tools/uv/` | `astral-sh/uv` | Python package/tool runner source. |
| `tools/cpython/` | `python/cpython` | CPython runtime source. |

`tools/MANIFEST.yaml` is the source of truth for source path, URL, branch,
status, and purpose. `.gitmodules` stores the actual submodule pins.

## Operating rules

- Prefer repo-local wrappers first: Make and self-CI should call `tools/bin/*`
  before host PATH tools.
- Prefer repo-local scripts for checks that do not need external tools:
  `scripts/verify-manifest.py`, `scripts/manifest-query.py`,
  `scripts/verify-markdown.py`, and `scripts/hermetic-audit.py` are
  standard-library Python and do not need yq, Node, bunx, or npx.
- Prefer submodules or pinned assets over opaque runtime downloads.
- Keep submodules shallow in `.gitmodules` unless full history is truly needed.
- Do not claim full hermeticity yet: release archives are pinned and verified,
  but generated caches and Trivy vulnerability DB updates are still runtime
  materialization steps.

## Updating pins

```bash
git submodule update --init --recursive --depth 1
make submodules.bump NAME=actionlint
make submodules.bump NAME=gitleaks
make submodules.bump NAME=trivy
```

For binary assets, update `tools/assets.json` with the new release URL and
SHA-256 from the upstream checksum file, then run:

```bash
rm -rf tools/.cache
python3 scripts/toolchain.py ensure
python3 scripts/toolchain.py verify-assets
```

Review the resulting manifest/checksum changes before committing.

## Next conversions

1. Add pinned assets or build wrappers for Node, Bun, uv, and CPython when CI
   jobs actually need those runtimes.
2. Move Trivy DB caching/mirroring into a repo-owned or runner-owned artifact so
   Trivy can run with `FLEXNETOS_NO_TOOL_DOWNLOAD=1`.
3. Turn `scripts/hermetic-audit.py --fail` on once the remaining runtime
   downloads are intentionally eliminated or allowlisted.
