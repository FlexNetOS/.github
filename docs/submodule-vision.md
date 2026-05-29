# FlexNetOS submodule vision

FlexNetOS uses this repository as an umbrella control plane: every component
stays in its own GitHub repository, while `repos/MANIFEST.yaml` and git
submodule pointers connect those repositories into one reproducible ecosystem.

This avoids two common failure modes:

1. A giant monorepo that stores every project, every history, every heavy
   dependency, and every generated artifact in one place.
2. A loose pile of local folders hidden by `.gitignore`, where important work
   is not reproducible and local changes can be lost.

The target shape is a graph of real repositories. Each node keeps its own
history, issues, releases, CI, and `.gitignore`; the umbrella stores the exact
commit pointers and automation policy.

LifeOS follows the same rule. It is the FlexNetOS frontend/UI-UX product repo,
not the `.github` control plane and not the owner of every runtime it consumes.
Shared runtimes and frameworks such as Rust, Node, Bun, Vite, Vue, and Tauri
belong in the shared toolchain graph when they are useful beyond LifeOS; LifeOS
pins and consumes them through manifests and repo-local wrappers.

## High-level structure

```text
                       FLEXNETOS ECOSYSTEM
                    "connected, not monolithic"

                              │
                              ▼
        ┌──────────────────────────────────────────────┐
        │              FlexNetOS/.github               │
        │         umbrella repo / control plane         │
        │                                              │
        │  community standards                         │
        │  reusable workflows                          │
        │  runner/secrets automation                   │
        │  docs / policies                             │
        │  repos/MANIFEST.yaml                         │
        └──────────────────────────────────────────────┘
                              │
                 stores gitlinks / commit pins
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
 ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
 │ repos/owned/   │  │ repos/forked/  │  │ repos/external/│
 │ first-party    │  │ patched forks  │  │ read-only refs │
 └────────────────┘  └────────────────┘  └────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
  own source of truth   track upstream +     learn from / compare /
  own issues + CI       carry FlexNetOS      reference only
  own releases          changes safely
```

## Directory tree graph

```text
FlexNetOS/.github
│
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
├── SUPPORT.md
├── CODE_OF_CONDUCT.md
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   ├── submodule-bump.yml
│   │   ├── reusable-lint.yml
│   │   ├── reusable-test.yml
│   │   ├── reusable-build.yml
│   │   ├── reusable-security.yml
│   │   ├── reusable-release.yml
│   │   └── reusable-submodule-bump.yml
│   │
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── CODEOWNERS
│   └── dependabot.yml
│
├── docs/
│   ├── automation.md
│   ├── directory-layout.md
│   ├── fork-workflow.md
│   ├── self-hosted-runner.md
│   └── submodule-vision.md
│
├── scripts/
│   ├── submodule-add-all.sh
│   ├── submodule-bump.sh
│   ├── submodule-sync-upstream.sh
│   ├── bootstrap.sh
│   ├── secrets-inject.sh
│   ├── secrets-rotate.sh
│   └── secrets-mirror-to-bws.sh
│
└── repos/
    │
    ├── MANIFEST.yaml
    │   └── single source of truth for all repo pointers
    │
    ├── owned/
    │   │
    │   ├── ruvector/                 -> Git submodule
    │   │   └── points to FlexNetOS/ruvector @ exact commit
    │   │
    │   ├── ruOS/                     -> Git submodule
    │   │   └── points to FlexNetOS/ruOS @ exact commit
    │   │
    │   ├── understand-anything/      -> Git submodule
    │   │   └── points to FlexNetOS/understand-anything @ exact commit
    │   │
    │   ├── ubuntu-lifeos/            -> Git submodule
    │   │   └── points to FlexNetOS/ubuntu-lifeos @ exact commit
    │   │
    │   └── llama.cpp/                -> Git submodule
    │       └── points to FlexNetOS/llama.cpp @ exact commit
    │
    ├── forked/
    │   │
    │   ├── n8n/                      -> Git submodule
    │   │   ├── origin:   FlexNetOS/n8n
    │   │   └── upstream: n8n-io/n8n
    │   │
    │   ├── aionui/                   -> Git submodule
    │   │   ├── origin:   FlexNetOS/AionUi-auto
    │   │   └── upstream: iOfficeAI/AionUi
    │   │
    │   ├── rtk/                      -> Git submodule
    │   │   ├── origin:   FlexNetOS/rtk
    │   │   └── upstream: rtk-ai/rtk
    │   │
    │   ├── archon/                   -> Git submodule, after fork
    │   │   ├── origin:   FlexNetOS/Archon
    │   │   └── upstream: coleam00/Archon
    │   │
    │   └── everything-claude-code/   -> Git submodule, after fork
    │       ├── origin:   FlexNetOS/everything-claude-code
    │       └── upstream: affaan-m/everything-claude-code
    │
    └── external/
        │
        ├── cpython/                  -> Git submodule
        │   └── points to python/cpython @ exact commit
        │
        ├── chroma/                   -> Git submodule
        │   └── points to chroma-core/chroma @ exact commit
        │
        ├── firecrawl/                -> Git submodule
        │   └── points to mendableai/firecrawl @ exact commit
        │
        ├── llm_wiki/                 -> Git submodule
        │   └── points to nashsu/llm_wiki @ exact commit
        │
        ├── mempalace/                -> Git submodule
        │   └── points to mempalace/mempalace @ exact commit
        │
        └── second-brain-starter/     -> Git submodule
            └── points to coleam00/second-brain-starter @ exact commit
```

## Nested submodules: plugins all the way down

A submodule may itself contain submodules. The model is recursive: each child
repo can expose its own plugin surface, dependencies, fixtures, models, or
reference trees without forcing the parent to vendor those files.

```text
FlexNetOS/.github
│
├── repos/owned/ruOS
│   │
│   ├── its own source code
│   ├── its own CI
│   ├── its own issues
│   ├── its own releases
│   │
│   └── submodules inside ruOS
│       │
│       ├── kernel-patches/        -> another repo pointer
│       ├── package-recipes/       -> another repo pointer
│       └── device-profiles/       -> another repo pointer
│
├── repos/owned/ruvector
│   │
│   ├── its own source code
│   ├── its own CI
│   ├── its own issues
│   ├── its own releases
│   │
│   └── submodules inside ruvector
│       │
│       ├── embedding-models/      -> another repo pointer
│       ├── graph-kernels/         -> another repo pointer
│       └── benchmark-datasets/    -> another repo pointer
│
├── repos/forked/n8n
│   │
│   ├── FlexNetOS fork
│   ├── tracks upstream n8n
│   ├── carries local FlexNetOS patches
│   │
│   └── submodules inside n8n, if needed
│       │
│       ├── custom-nodes/          -> another repo pointer
│       ├── workflow-templates/    -> another repo pointer
│       └── credential-schemas/    -> another repo pointer
│
└── repos/external/cpython
    │
    ├── external upstream reference
    ├── not edited directly
    │
    └── upstream may have its own nested dependencies
```

The pointer chain looks like this:

```text
┌────────────────────┐
│ FlexNetOS/.github  │
│ umbrella pointer   │
└─────────┬──────────┘
          │
          │ gitlink: exact commit
          ▼
┌────────────────────┐
│ repos/owned/ruOS   │
│ real repo          │
└─────────┬──────────┘
          │
          │ gitlink: exact commit
          ▼
┌────────────────────┐
│ ruOS dependency    │
│ real repo          │
└─────────┬──────────┘
          │
          │ gitlink: exact commit
          ▼
┌────────────────────┐
│ nested component   │
│ real repo          │
└────────────────────┘
```

## Why this beats `.gitignore` as the main organizing tool

`.gitignore` hides files from one repository. It does not make hidden state
reproducible, reviewable, or recoverable. It also does not explain ownership.

```text
┌────────────────────────────────────────────┐
│ One regular repo                           │
├────────────────────────────────────────────┤
│ source code                                │
│ generated files                            │
│ model files                                │
│ datasets                                   │
│ build outputs                              │
│ cloned external tools                      │
│ local edits to third-party projects        │
│ node_modules / venvs / caches              │
└────────────────────────────────────────────┘
                      │
                      ▼
            .gitignore tries to hide mess
                      │
                      ▼
       hidden files are not versioned,
       not reproducible, and easy to lose
```

The submodule model moves large or independent work into real repositories:

```text
┌────────────────────────────────────────────┐
│ FlexNetOS/.github                          │
├────────────────────────────────────────────┤
│ repos/MANIFEST.yaml                        │
│ .gitmodules                                │
│ submodule commit pointers                  │
│ automation                                 │
└────────────────────────────────────────────┘
                      │
                      ▼
        each big thing becomes its own repo
                      │
                      ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ ruvector     │ │ ruOS         │ │ n8n fork     │
│ own repo     │ │ own repo     │ │ own repo     │
└──────────────┘ └──────────────┘ └──────────────┘
        │                │                │
        ▼                ▼                ▼
 own .gitignore    own .gitignore    own .gitignore
 own storage       own storage       own storage
 own releases      own releases      own releases
 own CI            own CI            own CI
```

Instead of one parent `.gitignore` trying to hide every generated or local
thing, each component owns its own ignore rules, dependency rules, artifacts,
and storage boundaries. The umbrella only tracks the clean commit pointer.

## Why this beats a giant monorepo for storage

```text
Without submodules:

┌──────────────────────────────────────────┐
│ giant monorepo                           │
├──────────────────────────────────────────┤
│ ruvector                                 │
│ ruOS                                     │
│ llama.cpp                                │
│ cpython                                  │
│ chroma                                   │
│ n8n                                      │
│ archon                                   │
│ firecrawl                                │
│ generated assets                         │
│ histories of all of the above            │
└──────────────────────────────────────────┘
                  │
                  ▼
      huge clone, huge history,
      slow CI, hard cleanup,
      storage pressure
```

```text
With submodules:

┌──────────────────────────────────────────┐
│ FlexNetOS/.github                        │
├──────────────────────────────────────────┤
│ pointer to ruvector commit               │
│ pointer to ruOS commit                   │
│ pointer to llama.cpp commit              │
│ pointer to cpython commit                │
│ pointer to chroma commit                 │
│ pointer to n8n commit                    │
│ pointer to archon commit                 │
└──────────────────────────────────────────┘
                  │
                  ▼
        tiny parent repo, exact map
```

The real code remains in independent repositories:

```text
GitHub.com/FlexNetOS/ruvector
GitHub.com/FlexNetOS/ruOS
GitHub.com/FlexNetOS/llama.cpp
GitHub.com/python/cpython
GitHub.com/chroma-core/chroma
GitHub.com/FlexNetOS/n8n
GitHub.com/FlexNetOS/Archon
```

The parent stores metadata and pointers, not every component's full history.

## Plugin model

Think of every repo as a cartridge or plugin. It can be replaced, forked,
pinned, tested, and released independently.

```text
                         ┌───────────────┐
                         │ FlexNetOS OS  │
                         │ control plane │
                         └───────┬───────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        ▼                        ▼                        ▼
┌───────────────┐        ┌───────────────┐        ┌───────────────┐
│ memory layer  │        │ agent layer   │        │ distro layer  │
├───────────────┤        ├───────────────┤        ├───────────────┤
│ ruvector      │        │ Archon        │        │ ruOS          │
│ chroma        │        │ n8n           │        │ ubuntu-lifeos │
│ mempalace     │        │ AionUi        │        │ weftos        │
└───────────────┘        └───────────────┘        └───────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
┌───────────────┐        ┌───────────────┐        ┌───────────────┐
│ nested repos  │        │ nested repos  │        │ nested repos  │
│ models        │        │ workflows     │        │ packages      │
│ datasets      │        │ tools         │        │ kernels       │
└───────────────┘        └───────────────┘        └───────────────┘
```

## Summary

```text
Not one giant repo.
Not random ignored folders.
A graph of real repos, pinned together by commit pointers.
```

FlexNetOS uses submodules so every component remains a sovereign repo, while
the umbrella repo acts like a precise wiring harness that connects them into
one reproducible operating system.
