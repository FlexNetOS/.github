# Proposal — Architecture & Planning Artifact Framework

- **Change ID:** `2026-05-29-architecture-framework`
- **Status:** Proposed
- **Date:** 2026-05-29
- **Author:** FlexNetOS (session SESSION-2026-05-29)
- **Capability:** `architecture-framework`

## Why

The FlexNetOS `.github` umbrella produces design-time artifacts — plans, PRDs,
ADRs, specs — but has no single home or lifecycle for them. Today:

- The only spec framework instance is `lifeos/openspec/`, scoped to one subsystem.
- There is no ADR home and no PRD home anywhere in the repo.
- `docs/` is a flat pile mixing operator runbooks with architecture material.
- Planning artifacts land wherever the producing skill defaults to
  (e.g. `writing-plans` → `docs/superpowers/specs/`), so they scatter.

The result is poor discoverability for both humans and agents, and no defined
flow connecting "why" (PRD) → "what was decided" (ADR) → "how" (spec) →
"the steps" (plan).

We already own every tool needed to *produce* these artifacts as installed
skills. The gap is purely organizational: **where each artifact lives, how they
are named, and how they connect.** This change closes that gap with zero
net-new template machinery.

## What changes

Introduce a single, AI-navigable common root — `architecture/` — that hosts the
whole framework, plus the conventions and skill-routing that make the existing
skills emit into it.

### Goals

1. One top-level `architecture/` directory holding `prd/`, `adr/`, `plan/`, and
   the `openspec/` engine, with a `README.md` that maps the lifecycle and indexes
   the artifacts.
2. A defined lifecycle: **PRD → ADR → OpenSpec change/spec → plan → implement →
   archive**, with cross-links making the four homes a connected graph.
3. Skill outputs routed to the canonical homes via an authoritative convention
   block in `CLAUDE.md` + `AGENTS.md` (and OpenSpec's own `config.yaml`).
4. A documented adoption convention for submodules (umbrella vs. `owned/` vs.
   `forked/` vs. `external/`), to be rolled out to repos in a later phase.

### Non-goals (this change)

- ❌ No changes to any submodule under `repos/` — cross-repo rollout is a later phase.
- ❌ No relocation of existing `docs/` files — they are linked, not moved.
- ❌ No `openspec init` / `.claude/` skill installation — the OPSX skills are
  already available globally; the `openspec/` data tree is hand-scaffolded.
- ❌ No registry generator or MANIFEST-driven "adopted-by" automation — the
  README registry is maintained manually for now.
- ❌ No new artifact templates — outputs come from the installed skills as-is.

## The design

### Directory shape

```text
my-github/
├── architecture/                  # single common root for the framework
│   ├── README.md                  # lifecycle map + routing table + PRD/ADR registry + links
│   ├── prd/                       # PRD-NNNN-<slug>.md
│   ├── adr/                       # ADR-NNNN-<slug>.md
│   ├── plan/                      # YYYY-MM-DD-<slug>-plan.md
│   └── openspec/                  # the "spec" stage = OpenSpec OPSX engine
│       ├── config.yaml            #   schema: spec-driven + umbrella context
│       ├── project.md
│       ├── specs/<capability>/spec.md
│       └── changes/<id>/  +  changes/archive/
│
└── lifeos/openspec/               # UNCHANGED — the proven nested subsystem instance
```

The spec stage folder is named `openspec/` (not `spec/`) because the OpenSpec
CLI resolves a directory named literally `openspec/`. The lifecycle's "spec"
step therefore maps to `architecture/openspec/`; the `README.md` carries an
`architecture/spec → openspec/` pointer for the `/spec` mental label.

### Lifecycle & skill routing

```text
 PRD ──forces──▶ ADR(s) ──informs──▶ OpenSpec change ──feeds──▶ plan ──▶ implement ──▶ archive change
 (why/what)      (decisions)         (the how + tasks)          (steps)               (spec.md = truth)
```

| Stage | Skill (already installed) | Canonical output path |
|---|---|---|
| PRD | `ecc:plan-prd`, `ecc:prp-prd` | `architecture/prd/PRD-NNNN-<slug>.md` |
| ADR | `ecc:architecture-decision-records` | `architecture/adr/ADR-NNNN-<slug>.md` |
| Spec | `ccg:spec-research` → `spec-plan` → `spec-impl` | `architecture/openspec/` (run `openspec`/`opsx` from inside `architecture/`) |
| Plan | `superpowers:writing-plans`, `oh-my-claudecode:plan` | `architecture/plan/YYYY-MM-DD-<slug>-plan.md` |

The "defaults" mechanism: these skills (except OpenSpec) have no per-repo config
file, so the steering mechanism is an authoritative, version-controlled
**"Architecture artifacts"** convention block in `CLAUDE.md` + `AGENTS.md` that
declares the four paths. An agent reading repo instructions routes outputs there,
overriding a skill's own built-in default (e.g. `writing-plans`'
`docs/superpowers/specs/`). OpenSpec self-routes once `config.yaml` exists.

**Plan/tasks overlap rule:** OpenSpec changes already contain a `tasks.md`.
For OpenSpec-driven work, that `tasks.md` *is* the plan and stays in
`openspec/changes/<id>/`. `architecture/plan/` is only for cross-cutting or
non-OpenSpec implementation plans. No duplication.

### Naming, numbering, statuses

| Artifact | Filename | Numbering | Status |
|---|---|---|---|
| PRD | `PRD-NNNN-<slug>.md` | 4-digit sequential | `Draft → Active → Shipped → Superseded` |
| ADR | `ADR-NNNN-<slug>.md` | 4-digit sequential | `Proposed → Accepted → Deprecated \| Superseded-by ADR-NNNN` |
| Spec capability | `openspec/specs/<capability>/spec.md` | kebab capability name | OpenSpec-managed (truth = current) |
| Spec change | `openspec/changes/<YYYY-MM-DD-slug>/` | date-prefixed slug | OpenSpec-managed → `changes/archive/` |
| Plan | `YYYY-MM-DD-<slug>-plan.md` | date-prefixed | `Active → Done` |

- ADRs follow MADR layout, one decision per file, immutable once Accepted
  (supersede, never rewrite history).
- Date-prefixed change slugs mirror the proven `lifeos/openspec/changes/archive/2026-05-25-…`.
- Cross-links (relative markdown): PRD → its ADRs; ADR → the PRD + the change it
  drives; change → the ADRs it implements; plan → the spec/change it executes.
- `architecture/README.md` is also the registry: index tables of all PRDs and
  ADRs with status. Maintained manually.
- All files must pass `make verify.markdown` (single H1, etc.).

### Submodule-adoption convention

| Lane | Convention |
|---|---|
| Umbrella (`my-github` root) | `architecture/` holds cross-cutting / org-level artifacts. |
| `repos/owned/<x>` | Same `architecture/` shape at the submodule root for subsystem-specific artifacts. `lifeos/openspec/` is the precedent. |
| `repos/forked/<x>` | FlexNetOS artifacts live on the `develop` branch under `architecture/`, kept off `main`/`master` (which mirror upstream). |
| `repos/external/<x>` | None — read-only references carry no artifacts. |

Placement rule: affects >1 repo or the org → umbrella `architecture/`; scoped to
one subsystem → that submodule's `architecture/`.

## Alternatives considered

1. **Split homes** (`openspec/` at root + `docs/architecture/{adr,prd}/`).
   Rejected: the user wants one common root for AI navigation; two homes is
   harder to discover.
2. **Unified `architecture/{prd,adr,specs,plans,changes}/`** with the 4 lifeos
   specs relocated under it. Rejected: fights the OpenSpec CLI's `openspec/`
   expectation and risks breaking lifeos tooling by moving live specs.
3. **Minimal — ADR/PRD homes only, defer OpenSpec.** Rejected: leaves the "spec"
   stage unhomed at umbrella level; the lifecycle would be incomplete.

## Risks & mitigations

- **Concurrent-session branch churn** in the shared checkout → mitigated by doing
  this work in a dedicated git worktree on `feat/architecture-framework`.
- **Skill default drift** (a skill ignores the convention block) → mitigated by
  stating paths in both `CLAUDE.md` and `AGENTS.md` and in `architecture/README.md`.
- **`.claude/` CI churn** from `openspec init` → avoided by hand-scaffolding the
  `openspec/` data tree instead of running init.

## Impact

- New: `architecture/` tree (additive, no deletions).
- Edited: `CLAUDE.md`, `AGENTS.md` (convention block), `docs/directory-layout.md`
  (one entry).
- Unchanged: `lifeos/openspec/`, all of `repos/`, all existing `docs/` files.

See `tasks.md` for the execution breakdown and
`specs/architecture-framework/spec.md` for the capability delta.
