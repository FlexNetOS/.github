# LifeOS system architecture

LifeOS is the FlexNetOS frontend and user-experience layer. It is a separate
product repository, not the `FlexNetOS/.github` control-plane repository.

This repo (`FlexNetOS/.github`) records the ecosystem-level policy: where repos
mount, which tools are shared, how the supply chain is pinned, and how agents
should reason about the graph. LifeOS owns the frontend product experience.
Shared toolchains and dependencies should not be trapped inside LifeOS when they
also serve the rest of FlexNetOS.

## Decision

Treat shared tools as FlexNetOS-level system resources. Treat LifeOS as a
consumer of those resources.

In practice:

1. LifeOS owns LifeOS-specific product code: the shell, desktop, panels, routes,
   settings surfaces, themes, app registry, UI services, design-system usage,
   and user-facing workflows.
2. Shared language runtimes and build tools live at the ecosystem/toolchain
   layer: Rust, Node, Bun, Python, LLVM, package runners, scanners, linters, and
   other tools used by more than one FlexNetOS component.
3. Shared frontend frameworks and build-time dependencies also live at the
   shared frontend/toolchain layer when multiple components may use them: Vite,
   Vue, Tauri, TypeScript, frontend test tooling, and shared component/design
   libraries.
4. LifeOS pins what it needs through manifests and repo-local wrappers. The
   wrappers may point upward to the shared toolchain graph instead of downloading
   mutable global tools.
5. Lightweight leaf packages may remain normal locked package dependencies while
   the system matures. Anything required to build, boot, recover, or audit the
   ecosystem should graduate into the pinned shared toolchain graph.

## Target mental model

```text
ElementArk
└── FlexNetOS ecosystem
    ├── my-github / FlexNetOS/.github
    │   ├── GitHub org defaults
    │   ├── reusable CI
    │   ├── repo/submodule manifest
    │   ├── hermetic toolchain policy
    │   └── runner/secrets/recovery control plane
    │
    ├── toolchains/
    │   ├── rust
    │   ├── node
    │   ├── bun
    │   ├── python
    │   ├── llvm
    │   └── scanners-linters-release-tools
    │
    ├── frontend/
    │   ├── toolchains/
    │   │   ├── vite
    │   │   ├── vue
    │   │   ├── tauri
    │   │   └── typescript
    │   ├── libs/
    │   │   ├── design-system
    │   │   ├── shared-ui
    │   │   └── shared-runtime-bridges
    │   └── lifeos/
    │       ├── bin/
    │       ├── lib/
    │       ├── config/
    │       ├── usr/
    │       ├── var/
    │       ├── sys/
    │       ├── tmp/        # or tmt/ if the final naming chooses that
    │       ├── apps/
    │       ├── shell/
    │       ├── desktop/
    │       ├── panels/
    │       ├── services/
    │       └── themes/
    │
    ├── backend/
    ├── agents/
    ├── services/
    ├── infra/
    ├── distro/
    └── recovery/
```

## Ownership rule

Use this rule before adding a dependency or subrepo:

| Question | Home |
| --- | --- |
| Only LifeOS uses it and it is product/UI code | LifeOS repo |
| Multiple FlexNetOS components use it | shared `toolchains/`, `libs/`, or ecosystem repo |
| Needed to build, verify, recover, or audit the ecosystem | FlexNetOS-level pinned toolchain |
| Third-party project needs source-level control or patching | fork/submodule with upstream recorded |
| Small leaf package with no system role | normal locked dependency is acceptable for now |

## LifeOS repo contract

LifeOS should feel self-contained to a builder, but it should not own every
shared dependency. The preferred shape is:

```text
frontend/lifeos/
├── lifeos.manifest.yaml       # product dependency contract
├── package.json               # frontend package contract
├── Cargo.toml                 # Rust/Tauri contract when applicable
├── tools/                     # repo-local wrappers, not random global PATH use
│   ├── node   -> shared Node wrapper/pin
│   ├── bun    -> shared Bun wrapper/pin
│   ├── cargo  -> shared Rust wrapper/pin
│   └── vite   -> shared frontend tool wrapper/pin
└── src/ or app-specific tree
```

The wrapper target can be a submodule, binary asset, or build output recorded by
the FlexNetOS toolchain manifest. The point is determinism: the builder should
not need to guess which global Node, Rust, Vite, or Vue version is installed.

## Fresh OS / zip-extract doctrine

The long-term target remains:

1. Clone or extract the ecosystem.
2. Initialize the declared subrepo graph in safe batches.
3. Use repo-local wrappers and pinned assets first.
4. Avoid hidden global PATH requirements, mutable package-manager installs, and
   legacy runtime pins.
5. Upgrade/fork/vendor tools that demand stale runtimes instead of freezing the
   whole OS around old dependencies.

## Current local note

A local nested `lifeos/` repository currently exists inside this checkout and has
no configured remote. Until a canonical remote and mount path are chosen, do not
blindly commit it into `FlexNetOS/.github` as plain files. The likely next step
is to turn it into a real first-party repo/submodule mounted under a frontend
path, or relocate it to the canonical LifeOS repo path and leave this control
plane with only manifests and docs.
