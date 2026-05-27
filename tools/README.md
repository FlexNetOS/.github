# `tools/` — repo-local toolchain sources

This directory now holds the first materialized pieces of the hermetic toolchain.
Each materialized tool is a shallow git submodule pinned by this umbrella repo.
The goal is that local scripts and CI can move from host/global installs toward
repo-relative tool sources or pinned assets.

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

`tools/MANIFEST.yaml` is the source of truth for path, URL, branch, status, and
purpose. `.gitmodules` stores the actual submodule pins.

## Operating rules

- Prefer repo-local scripts first: `scripts/verify-manifest.py`,
  `scripts/manifest-query.py`, `scripts/verify-markdown.py`, and
  `scripts/hermetic-audit.py` are standard-library Python and do not need yq,
  Node, bunx, or npx.
- Prefer submodules or pinned assets over runtime downloads.
- Keep submodules shallow in `.gitmodules` unless full history is truly needed.
- Do not claim full hermeticity just because source submodules exist. A source
  submodule is the seed. Follow-up passes still need build/bootstrap wrappers,
  checksums for binaries, and CI wiring to call repo-local executables.

## Updating pins

```bash
git submodule update --init --recursive --depth 1
make submodules.bump NAME=actionlint
make submodules.bump NAME=gitleaks
make submodules.bump NAME=trivy
```

Review the resulting gitlink changes before committing.

## Next conversions

1. Build or fetch pinned binaries for the platforms this repo actually runs on.
2. Store checksums beside the assets or in `tools/MANIFEST.yaml`.
3. Add repo-local wrappers such as `tools/bin/actionlint` and update Make/CI to
   prefer those wrappers before host PATH tools.
4. Turn `scripts/hermetic-audit.py --fail` on once the remaining runtime
   downloads are intentionally eliminated or allowlisted.
