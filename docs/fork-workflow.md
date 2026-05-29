# Fork-and-track workflow

How to carry local patches on a third-party repository while staying
current with upstream releases.

## Step 0 — clone & pack with repomix (always, before `gh repo fork`)

The umbrella's hard rule, baked into operator memory and into every
existing research dossier under `data/brain-data/research/`:

> **Never run `gh repo fork` against a new upstream until
> `data/brain-data/research/<name>.md` exists and the §10 "Open
> decisions" gate is resolved.**

Step 0 is the mechanical part of that rule. It produces a reviewable
codebase pack so the dossier is informed by *source*, not README skim:

```bash
make research.pack URL=https://github.com/<owner>/<repo>
# or, equivalently:
scripts/clone-and-pack.sh <owner>/<repo> [BRANCH]
```

What it does (idempotent — safe to re-run):

1. Clones the **original** upstream (never the FlexNetOS fork) into
   `.attic/research-work/<name>/` — gitignored, never committed.
2. Runs `tools/bin/repomix` against the clone, producing:
   - `data/brain-data/research/<name>/repomix-pack.xml` — full pack.
   - `data/brain-data/research/<name>/repomix-pack.compressed.xml` —
     signatures-only compression (tree-sitter), useful for LLM context
     windows.
   - `data/brain-data/research/<name>/repomix-summary.md` — file count,
     pack size, top extensions, top directories, clone HEAD.
3. Seeds a stub dossier at `data/brain-data/research/<name>.md` with
   the umbrella's standard 11-section shape (identity, purpose, stack,
   license, FlexNetOS-side intent, pre-adoption audit, adoption plan,
   sync risk, verification, open decisions, decision log). Existing
   dossiers are left untouched.

**`research.pack` does not call `gh repo fork`.** Forking remains a
deliberate human/agent step gated on the dossier being filled in.

The repomix tool itself is vendored at `tools/repomix/` and pinned via
`tools/bin/repomix` (npx-pinned `repomix@<version>`). See
[`data/brain-data/research/repomix.md`](../data/brain-data/research/repomix.md)
for the adoption dossier, and `FLEXNETOS_NO_TOOL_DOWNLOAD=1` for the
hermetic-mode path through the vendored submodule.

## The pattern

When FlexNetOS forks an upstream project (e.g. `ruvnet/RuVector` →
`FlexNetOS/ruvector`), two properties must hold simultaneously:

1. **Track upstream** — pick up bug fixes and features as they ship.
2. **Carry local diffs** — maintain integrations, CI, and customizations that don't make sense upstream (or that upstream isn't ready to accept).

The pattern below keeps both clean.

## One-time setup

```bash
git clone https://github.com/FlexNetOS/<repo>.git
cd <repo>

# Add the upstream remote
git remote add upstream https://github.com/<upstream-owner>/<repo>.git
git fetch upstream --tags

# Verify
git remote -v
# origin    https://github.com/FlexNetOS/<repo>.git (fetch + push)
# upstream  https://github.com/<upstream-owner>/<repo>.git (fetch + push)
```

## Branch model

| Branch | Tracks | Purpose |
| --- | --- | --- |
| `main` | `upstream/main` (or upstream default) | Mirror of upstream — never commit local changes here directly. |
| `develop` | `origin/develop` | Integration branch for our local changes; PRs target here. |
| `feat/<slug>` | branched from `develop` | Per-change feature branches. |

PRs in FlexNetOS forks target `develop`, not `main`. `main` is reserved
for upstream mirror state.

## Routine syncing

```bash
# Update both remotes
git fetch --all --tags --prune

# Fast-forward main to upstream
git checkout main
git merge --ff-only upstream/main
git push origin main

# Rebase develop on top of the new main
git checkout develop
git rebase main
# Only force-push if the rebase moved commits:
git push origin develop --force-with-lease
```

## Release-tag syncing

When upstream cuts a tagged release we want to mirror:

```bash
git fetch upstream --tags
git tag -l 'v*' | head -5     # find the new tag(s)
git push origin <tag-name>    # push the chosen tag to our fork
```

If we ship our own release with local diffs, prefix the tag with `flex-`
to avoid collisions with upstream:

```text
flex-v1.2.3+local.1
```

## Carrying patches across upstream history rewrites

When upstream rewrites history (force-pushes, drops commits, squash-
merges), replay our commits cleanly:

```bash
git rebase --onto upstream/main <old-base> develop
```

## When upstream accepts our patch

Once upstream merges a PR we have been carrying locally, drop the local
commit from `develop` on the next sync — the rebase will succeed
automatically if the patch is now identical to upstream's accepted
version. If it doesn't, that's a useful signal: upstream changed the
patch in review, and we should adopt the upstream variant rather than
re-applying ours.

## Adopting a new upstream

Choose the lane before you fork:

| Case | Lane | First step |
|------|------|------------|
| FlexNetOS-original, no upstream | `repos/owned/` | `gh repo create FlexNetOS/<name>` |
| Third-party we will patch and track | `repos/forked/` | Step 0 (`make research.pack`) → fill dossier → `gh repo fork` |
| Third-party for reference only | `repos/external/` | No fork — add URL to MANIFEST as-is |

The research-before-fork gate is mandatory for `repos/forked/` entries.
See [`../CLAUDE.md`](../CLAUDE.md) for the full ritual and the
`data/brain-data/research/` dossier schema.

## See also

- [`directory-layout.md`](directory-layout.md) — umbrella layout and the
  `repos/{owned,forked,external}/` submodule tree.
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — commit conventions and
  branch policy.
