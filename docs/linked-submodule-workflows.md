# Linked submodule workflows

The next layer of the FlexNetOS umbrella is workflow linkage: the parent repo
should be able to trigger automation inside submodule repos, and submodule repos
should be able to report status back to the parent.

This turns the submodule tree from a static map into an automated graph.

## Goal

```text
Parent umbrella repo
    │
    ├── knows every child repo from repos/MANIFEST.yaml
    ├── knows each child repo's group and toolchain
    ├── pins each child repo to an exact commit
    └── can trigger child workflows on demand or on schedule
```

Each submodule remains independent, but the parent can coordinate ecosystem-wide
actions such as lint, test, build, release, security scan, upstream sync, and
submodule bumping.

## Parent-to-child workflow graph

```text
┌──────────────────────────────────────────────┐
│ FlexNetOS/.github                            │
│ parent workflow                              │
│                                              │
│ .github/workflows/ecosystem-dispatch.yml     │
└───────────────────────┬──────────────────────┘
                        │
                        │ reads repos/MANIFEST.yaml
                        │ filters by group/toolchain/name
                        │
        ┌───────────────┼────────────────┬────────────────┐
        │               │                │                │
        ▼               ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ ruvector     │ │ ruOS         │ │ n8n          │ │ Archon       │
│ child repo   │ │ child repo   │ │ child repo   │ │ child repo   │
├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────────┤
│ lint.yml     │ │ build.yml    │ │ test.yml     │ │ test.yml     │
│ test.yml     │ │ package.yml  │ │ security.yml │ │ lint.yml     │
│ release.yml  │ │ release.yml  │ │ sync.yml     │ │ build.yml    │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

## Child-to-parent status graph

```text
┌──────────────┐       workflow status       ┌──────────────────────┐
│ child repo   │ ──────────────────────────▶ │ FlexNetOS/.github    │
│ CI run       │                             │ ecosystem dashboard  │
└──────────────┘                             └──────────────────────┘
        │                                               │
        │ artifacts / commit SHA / result               │ issue, PR comment,
        │                                               │ summary markdown,
        ▼                                               ▼
┌──────────────┐                             ┌──────────────────────┐
│ logs         │                             │ ecosystem health     │
│ artifacts    │                             │ report               │
│ releases     │                             └──────────────────────┘
└──────────────┘
```

## Dispatch pattern

GitHub Actions supports cross-repository triggers through `workflow_dispatch` or
`repository_dispatch`.

The parent should eventually provide a workflow like:

```yaml
name: ecosystem-dispatch

on:
  workflow_dispatch:
    inputs:
      group:
        description: MANIFEST group to operate on
        required: false
        default: core
      command:
        description: Child command to run: lint, test, build, release, security
        required: true
        default: test

permissions:
  contents: read
  actions: write

jobs:
  dispatch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Dispatch selected child repos
        env:
          GH_TOKEN: ${{ secrets.FLEXNETOS_BOT_TOKEN }}
          GROUP: ${{ inputs.group }}
          COMMAND: ${{ inputs.command }}
        run: |
          set -euo pipefail

          python3 scripts/manifest-query.py repos/MANIFEST.yaml --fields url,groups |
          while IFS=$'\t' read -r url groups; do
            [[ " $groups " == *" $GROUP "* ]] || continue
            repo="${url#https://github.com/}"
            echo "Dispatching $COMMAND to $repo"

            gh workflow run "${COMMAND}.yml" \
              --repo "$repo" \
              --ref main \
              -f umbrella_repo="${{ github.repository }}" \
              -f umbrella_sha="${{ github.sha }}"
          done
```

For child repos that do not share workflow names, the manifest can gain optional
workflow metadata:

```yaml
- path: repos/owned/ruvector
  url: https://github.com/FlexNetOS/ruvector
  branch: main
  toolchain: [node, cargo]
  groups: [core, owned, daily]
  workflows:
    lint: .github/workflows/lint.yml
    test: .github/workflows/test.yml
    build: .github/workflows/build.yml
    release: .github/workflows/release.yml
```

## Recursive workflow graph

Submodules can also dispatch their own submodules. This allows automation to
follow the same graph as the source tree.

```text
FlexNetOS/.github
│
├── dispatch: group=core command=test
│
▼
repos/owned/ruOS
│
├── runs ruOS tests
├── reads ruOS's own submodule manifest, if present
└── dispatches nested tests
    │
    ▼
    kernel-patches/
    package-recipes/
    device-profiles/
```

Expanded view:

```text
┌──────────────────────┐
│ FlexNetOS/.github    │
│ ecosystem workflow   │
└──────────┬───────────┘
           │ dispatch
           ▼
┌──────────────────────┐
│ child repo           │
│ repo workflow        │
└──────────┬───────────┘
           │ optional nested dispatch
           ▼
┌──────────────────────┐
│ grandchild repo      │
│ component workflow   │
└──────────┬───────────┘
           │ reports result
           ▼
┌──────────────────────┐
│ ecosystem report     │
│ issue / PR / summary │
└──────────────────────┘
```

## Automation cycle

```text
        ┌──────────────────────────────┐
        │ repos/MANIFEST.yaml          │
        │ source of truth              │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ parent workflow              │
        │ selects repos by group       │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ child workflow dispatch      │
        │ lint/test/build/security     │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ status collection            │
        │ logs/artifacts/conclusions   │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ ecosystem report             │
        │ issue, PR comment, summary   │
        └──────────────────────────────┘
```

## Relationship to submodule bumping

The existing submodule bump workflow updates commit pointers. Linked workflows
add a second layer: after a pointer changes, the parent can trigger child checks
or nested checks before accepting that new pointer.

```text
submodule-bump.yml
    │
    ├── updates child commit pointers
    ├── opens PR
    │
    ▼
ecosystem-dispatch.yml
    │
    ├── sees changed submodules
    ├── triggers child repo tests
    ├── triggers child repo security scans
    ├── waits for or summarizes results
    │
    ▼
PR review
    │
    ├── parent CI result
    ├── child CI result
    ├── nested CI result, when available
    │
    ▼
merge only when the graph is healthy
```

## Why this matters

This lets FlexNetOS automate the whole process without collapsing everything
into one repository.

```text
Each repo stays sovereign:
  own code
  own releases
  own history
  own CI
  own storage
  own .gitignore

The parent coordinates:
  what exists
  what version is pinned
  what group it belongs to
  what workflow to trigger
  what result came back
```

The result is a linked repo graph: distributed like many repos, but operable
like one system.
