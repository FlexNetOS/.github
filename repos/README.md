# `repos/` — the FlexNetOS submodule tree

This directory is the canonical mount point for every project that belongs in
the FlexNetOS umbrella, referenced as **git submodules**. Nothing here lives
as a vendored copy — each subdirectory is a pointer at a real GitHub
repository.

## Why submodules and not a monorepo

- Each project keeps its own issues, releases, CI, and history.
- The umbrella tracks a **specific commit** of each project — reproducible
  on a fresh checkout, but easy to bump in a single PR.
- Heavy projects (cpython, llama.cpp, screenpipe, ruvector) stay out of
  this repo's pack files; the umbrella stays small and clones fast.
- Selective initialization — `git submodule update --init repos/owned/ruvector`
  pulls only what you need.

## Layout

```text
repos/
├── MANIFEST.yaml         single source of truth — toolchain tags, groups, branches
├── README.md             (this file)
├── owned/                FlexNetOS-owned originals
├── forked/               FlexNetOS forks of third-party upstreams
└── external/             read-only clones of upstream we don't intend to patch
```

The split exists so the **fork-and-track** workflow (see
[`docs/fork-workflow.md`](../docs/fork-workflow.md)) is operationally
distinct from owned originals and from passive read-only clones.

## `MANIFEST.yaml`

This is the source of truth. Every submodule has an entry. `.gitmodules`
is **generated** from this file by `scripts/submodule-add-all.sh` and is
never hand-edited.

Entry fields:

| Field | Purpose |
| --- | --- |
| `path` | submodule mount point relative to repo root |
| `url` | clone URL (the `origin` remote) |
| `upstream` | optional — for forks, the upstream URL we periodically sync from |
| `branch` | branch to track |
| `toolchain` | list — used by CI and the per-toolchain dependabot config |
| `groups` | list — used to bulk-operate (`make submodules.bump GROUP=core`) |
| `partial_clone` | optional `blob:none` / `tree:0` filter for very large repos |
| `notes` | freeform |

## Common operations

```bash
# First-time clone of this repo + every submodule (depth-1, fast)
git clone --recurse-submodules --shallow-submodules \
  https://github.com/FlexNetOS/.github.git

# After a fresh clone (or after the manifest changes)
make submodules.init

# Bring a single submodule up to its tracked branch HEAD
make submodules.bump GROUP=core
# …or by name
git -C repos/owned/ruvector fetch && git -C repos/owned/ruvector merge --ff-only origin/main
git add repos/owned/ruvector && git commit -m "chore(submodule): bump ruvector to <sha>"

# For forked/ — pull upstream changes into our fork
make submodules.sync-upstream GROUP=forked

# Status report (dirty submodules, ahead-of-tracking, etc.)
make submodules.status
```

## Adding a new submodule

1. Add an entry to `MANIFEST.yaml`.
2. Run `scripts/submodule-add-all.sh` — it detects missing entries and
   `git submodule add`s them.
3. Commit the resulting `.gitmodules` + new submodule pointer in one PR.

## CI implications

The reusable workflows in `.github/workflows/` skip the `repos/` tree by
default — each submodule has its own CI. The umbrella's CI verifies the
manifest is consistent (no missing submodules, no orphaned `.gitmodules`
entries, branch tracking matches).
