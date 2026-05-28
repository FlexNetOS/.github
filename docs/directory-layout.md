# Directory layout — FlexNetOS umbrella (Model B)

All FlexNetOS repositories live as git submodules **inside** this umbrella
repo (`FlexNetOS/.github`). Contributors clone the umbrella once and
initialize the submodules they need. There are no separate sibling clones.

## The layout

```text
~/workspace/my-github/            ← the FlexNetOS/.github checkout
│
├── repos/
│   ├── owned/                    # FlexNetOS-original repos (no upstream)
│   │   ├── ruvector/             ← git submodule → FlexNetOS/ruvector
│   │   ├── ruOS/                 ← git submodule → FlexNetOS/ruOS
│   │   ├── understand-anything/  ← …
│   │   └── …
│   │
│   ├── forked/                   # FlexNetOS forks tracking a third-party upstream
│   │   ├── n8n/                  ← git submodule → FlexNetOS/n8n (upstream: n8n-io/n8n)
│   │   ├── rtk/                  ← git submodule → FlexNetOS/rtk
│   │   └── …
│   │
│   └── external/                 # Read-only upstream references (no local patches)
│       ├── cpython/              ← git submodule → python/cpython
│       ├── chroma/               ← git submodule → chroma-core/chroma
│       └── …
│
├── repos/MANIFEST.yaml           ← single source of truth for all submodule pointers
├── .gitmodules                   ← generated from MANIFEST (keep in sync)
│
├── .github/workflows/            ← reusable CI templates consumed by downstream repos
├── docs/                         ← this file and its siblings
├── scripts/                      ← Makefile-backed operator scripts
└── …
```

## Three lanes, one rule

| Lane | What lives here | Fork required? |
|------|----------------|----------------|
| `repos/owned/` | FlexNetOS-original projects — no upstream to track | No — `gh repo create` |
| `repos/forked/` | Third-party repos we patch and stay current with | Yes — after the research.pack gate |
| `repos/external/` | Third-party repos we reference read-only | No — clone URL only |

`repos/MANIFEST.yaml` is authoritative. `.gitmodules` mirrors it.
Use `make submodules.add` (never `git submodule add` directly) to register a new entry.

## Getting started locally

```bash
# Clone the umbrella
git clone https://github.com/FlexNetOS/.github.git ~/workspace/my-github
cd ~/workspace/my-github

# Initialize all submodules (shallow, depth=1)
make submodules.init

# Or initialize a specific group only
make submodules.init GROUP=core
```

## Per-project conventions

Each submodule keeps its own toolchain config. Prefer per-project environments
rather than relying on host state:

| Stack | Convention |
|-------|-----------|
| Python | `.venv/` inside the submodule, created with `uv venv` or `python3 -m venv .venv`. |
| Node | `node_modules/` inside the submodule; toolchain via [`mise`](https://mise.jdx.dev). |
| Rust | Per-project `target/` directory (the cargo default). |

Per-project files **must not** leak into `$HOME` or `~/.local/bin`.

## Devcontainer interaction

The base devcontainer at `$HOME/.devcontainer/devcontainer.json` mounts
the project directory, not all of `$HOME`. Files written outside the
project tree are invisible inside the container — keep work inside the
submodule root.

## What does NOT go in `repos/`

- Generated artifacts (`target/`, `dist/`, `build/`, `.cache/`) — these live inside each submodule.
- Scratch experiments unrelated to any tracked repo — `work/` or `personal/` scratch dirs.
- Anything you would not commit. Lockfiles and CI configs are tracked; `.env.local` is not.

## See also

- [`fork-workflow.md`](fork-workflow.md) — branch model and upstream-sync pattern for `forked/`.
- [`submodule-vision.md`](submodule-vision.md) — why this structure beats a monorepo or `.gitignore` soup.
- [`self-hosted-runner.md`](self-hosted-runner.md) — where runner state lives (outside `repos/`).
