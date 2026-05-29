# architecture/ — FlexNetOS umbrella design framework

Single common root for the umbrella's design-time artifacts: **plans, PRDs, ADRs,
and specs**. Artifacts are produced by existing skills (no bespoke templates) and
routed here by the **Architecture artifacts** block in `CLAUDE.md` / `AGENTS.md`.

## Lifecycle

```text
 PRD ──forces──▶ ADR(s) ──informs──▶ OpenSpec change ──feeds──▶ plan ──▶ implement ──▶ archive
 why / what      decisions           the how + tasks            steps               spec = truth
```

Early stages are skippable for small changes. For OpenSpec-driven work the change's
own `tasks.md` is the plan; `plan/` is for cross-cutting or non-OpenSpec plans.

## Layout

| Path | Holds | Produced by |
|---|---|---|
| `prd/` | `PRD-NNNN-<slug>.md` | `ecc:plan-prd`, `ecc:prp-prd` |
| `adr/` | `ADR-NNNN-<slug>.md` (Nygard/MADR) | `ecc:architecture-decision-records` |
| `plan/` | `YYYY-MM-DD-<slug>-plan.md` | `writing-plans`, `oh-my-claudecode:plan` |
| `openspec/` | the "spec" stage — OpenSpec OPSX engine (`specs/`, `changes/`) | `ccg:spec-research` → `spec-plan` → `spec-impl` |

> `architecture/spec` -> `openspec/`. The spec stage is the OpenSpec engine; the
> folder is named `openspec/` because the OpenSpec CLI resolves that literal name.
> Run `openspec`/`opsx` from `architecture/`.

## Routing (the override)

These skills default elsewhere; in this repo they route into `architecture/`:

| Stage | Skill built-in default | Routed to |
|---|---|---|
| PRD | `.claude/prds/` or `.claude/PRPs/prds/` | `architecture/prd/` |
| ADR | `docs/adr/` | `architecture/adr/` |
| Plan | `docs/superpowers/plans/` | `architecture/plan/` |
| Spec | OpenSpec `openspec/` at CWD | `architecture/openspec/` (run from `architecture/`) |

## Conventions

- PRD/ADR numbering is 4-digit sequential; **this README registry is the source of
  truth** for the next number (avoids collisions across concurrent sessions).
- ADRs are immutable once `accepted`; supersede via a new ADR, never rewrite.
- Cross-link related artifacts with relative markdown links.
- Every fenced code block in tracked `architecture/**/*.md` must be language-tagged
  and closed (`make verify.markdown`).
- `architecture/.claude/` (OpenSpec init tooling) is git-ignored — not committed.

## PRD registry

| PRD | Title | Status | Date |
|---|---|---|---|
| [PRD-0001](prd/PRD-0001-architecture-framework.md) | Architecture & Planning Artifact Framework | Active | 2026-05-29 |

## ADR registry

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](adr/ADR-0001-architecture-artifact-homes.md) | Single `architecture/` root for design artifacts | accepted | 2026-05-29 |

## Submodule adoption (documented; rollout deferred)

| Lane | Convention |
|---|---|
| Umbrella (this repo) | `architecture/` holds cross-cutting / org-level artifacts. |
| `repos/owned/<x>` | Same `architecture/` shape at the submodule root. `lifeos/openspec/` is the local precedent. |
| `repos/forked/<x>` | FlexNetOS artifacts on the `develop` branch under `architecture/`; never on upstream-tracking `main`/`master`. |
| `repos/external/<x>` | None — read-only references carry no artifacts. |

## Related existing docs

- [`../docs/directory-layout.md`](../docs/directory-layout.md) — repo-wide layout (Model B submodules).
- [`../docs/lifeos-system-architecture.md`](../docs/lifeos-system-architecture.md) — lifeos subsystem architecture.
- [`../docs/submodule-vision.md`](../docs/submodule-vision.md) — why the submodule structure.
- [`../VISION.md`](../VISION.md) — the six roles of this umbrella.
