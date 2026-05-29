# PRD-0001 — Architecture & Planning Artifact Framework

- **Status:** Active
- **Date:** 2026-05-29
- **Owner:** FlexNetOS
- **Related:** [ADR-0001](../adr/ADR-0001-architecture-artifact-homes.md) · [OpenSpec change](../openspec/changes/archive/2026-05-29-architecture-framework/proposal.md)

> Routing note: `ecc:plan-prd` defaults to `.claude/prds/`. Per this framework's
> convention, PRDs live at `architecture/prd/PRD-NNNN-<slug>.md`. This file
> dogfoods that override.

## Problem

The FlexNetOS `.github` umbrella produces design-time artifacts — plans, PRDs,
ADRs, specs — but has no single home or lifecycle for them. The only spec
instance (`lifeos/openspec/`) is local and subsystem-scoped; there is no ADR or
PRD home; `docs/` mixes operator runbooks with architecture material. The cost:
poor discoverability for humans and agents, and no defined flow from "why" to
"the steps."

## Evidence

- Observed in-repo: no `architecture/`, `adr/`, or `prd/` directory existed
  before this change; `docs/` is a flat pile (`directory-layout.md`,
  `fork-workflow.md`, `automation.md`, …).
- Observed: `lifeos/openspec/` is the sole OpenSpec instance and is untracked
  (`git ls-files lifeos/` is empty) — a local precedent, not a shared standard.
- Observed: artifact-producing skills emit to divergent defaults
  (`docs/superpowers/plans/`, `.claude/prds/`, `docs/adr/`), guaranteeing sprawl.

## Users

- **Primary**: agents and contributors authoring design artifacts in the
  umbrella repo (and, by documented convention, in `repos/owned` /
  `repos/forked` submodules).
- **Not for**: external consumers of FlexNetOS repos; `repos/external`
  read-only references; upstream-tracking `main`/`master` branches of forks.

## Hypothesis

We believe a **single `architecture/` root (prd/adr/plan/openspec) plus skill
routing** will **make design artifacts discoverable and connect them into a
PRD→ADR→spec→plan lifecycle** for **umbrella agents and contributors**.
We'll know we're right when **all four artifact classes resolve under
`architecture/`, the installed skills emit there, and `make verify` stays
green**.

## Success Metrics

| Metric | Target | How measured |
|---|---|---|
| Artifact classes homed under `architecture/` | 4 of 4 | `ls architecture/{prd,adr,plan,openspec}` |
| Routing declared in both instruction files | Consistent | `architecture` block present + identical in `CLAUDE.md` and `AGENTS.md` |
| CI markdown gate | Green | `python3 scripts/verify-markdown.py .` exits zero (tracked files) |
| Additive footprint | No collateral edits | `git diff --name-only` limited to architecture/**, CLAUDE.md, AGENTS.md, docs/directory-layout.md, .gitignore |

## Scope

**MVP** — Umbrella-level framework: scaffold `architecture/` (prd/adr/plan/openspec),
seed the dogfood PRD-0001/ADR-0001 + the OpenSpec change, add the routing block to
`CLAUDE.md`/`AGENTS.md`, and document `architecture/` in `docs/directory-layout.md`.

**Out of scope**

- Cross-repo rollout to submodules — deferred; convention is documented only.
- Registry generator / MANIFEST-driven adopted-by index — manual README registry for now.
- Relocating existing `docs/` files — linked, not moved.
- Promotion to an org-wide inheritable standard — later phase.

## Delivery Milestones

<!-- Status: pending | in-progress | complete -->

| # | Milestone | Outcome | Status | Plan |
|---|---|---|---|---|
| 1 | Umbrella framework | `architecture/` exists, dogfood artifacts seeded, routing wired, CI green | in-progress | [design.md](../openspec/changes/archive/2026-05-29-architecture-framework/design.md) |
| 2 | Submodule rollout | `owned`/`forked` submodules carry `architecture/` per convention | pending | — |
| 3 | Registry automation | README registry generated, optionally MANIFEST-driven | pending | — |

## Open Questions

- [ ] How should PRD/ADR numbering avoid collisions across concurrent agent sessions? (current answer: README registry is source of truth)
- [ ] Should `scripts/verify-markdown.py` skip git-ignored `.claude` dirs to make local `make verify` match CI? (deferred)

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Agents keep writing to built-in skill defaults | Medium | Medium | Identical routing blocks in both instruction files + README table |
| Init-generated `architecture/.claude/` breaks CI | Low | High | Gitignored; assert `git ls-files architecture/.claude` empty |
| Untracked drafts wiped by concurrent session | Medium | High | Isolated worktree; commit incrementally |

---
*Status: DRAFT — requirements only. Implementation planning lives in the OpenSpec change design.md.*
