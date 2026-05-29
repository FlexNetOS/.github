# ADR-0001: Single `architecture/` root for design artifacts

**Date**: 2026-05-29
**Status**: accepted
**Deciders**: FlexNetOS
**Related**: [PRD-0001](../prd/PRD-0001-architecture-framework.md) · [OpenSpec change](../openspec/changes/archive/2026-05-29-architecture-framework/proposal.md)

> Routing note: `ecc:architecture-decision-records` defaults to `docs/adr/`.
> Per this framework's convention, ADRs live at
> `architecture/adr/ADR-NNNN-<slug>.md`. This file dogfoods that override.

## Context

The FlexNetOS `.github` umbrella had no home or lifecycle for design-time
artifacts. The sole OpenSpec instance (`lifeos/openspec/`) is local and
untracked; there was no ADR or PRD home; `docs/` mixes operator runbooks with
architecture material. Artifact-producing skills emit to divergent defaults
(`docs/superpowers/plans/`, `.claude/prds/`, `docs/adr/`), guaranteeing sprawl.
We want one discoverable home and a defined PRD→ADR→spec→plan flow, using the
skills we already have rather than new templates.

## Decision

Host all design artifacts under a single top-level `architecture/` root with
`prd/`, `adr/`, `plan/`, and `openspec/` subdirectories plus a `README.md`
index. The spec stage is the OpenSpec engine, kept at the literal directory name
`architecture/openspec/` (the CLI requires it). Introduction is **additive**
(no existing files moved, `lifeos/openspec/` untouched). The
`openspec init`-generated `architecture/.claude/` is **git-ignored** (it fails
markdown lint and the OPSX skills work locally regardless). Skill output is
routed to these homes via an **"Architecture artifacts" block in `CLAUDE.md` and
`AGENTS.md`** that overrides each skill's built-in default.

## Alternatives Considered

### Alternative 1: Split homes (`openspec/` at root + `docs/architecture/{adr,prd}/`)
- **Pros**: ADR/PRD stay near other docs; OpenSpec at canonical repo root.
- **Cons**: two locations to discover; worse for AI navigation.
- **Why not**: the goal is one common root the agent can `cd` into.

### Alternative 2: Unified `architecture/{prd,adr,specs,plans}/`, relocate lifeos specs
- **Pros**: everything co-located, including specs renamed to `specs/`.
- **Cons**: fights the OpenSpec CLI's literal `openspec/` requirement; relocating
  the live lifeos specs risks breaking lifeos tooling.
- **Why not**: high-risk file movement for a cosmetic naming gain.

### Alternative 3: Minimal — ADR/PRD homes only, defer OpenSpec
- **Pros**: smallest change, no `.claude` churn.
- **Cons**: leaves the "spec" stage unhomed; lifecycle incomplete.
- **Why not**: specs were explicitly in scope.

## Consequences

### Positive
- One discoverable root for plans, PRDs, ADRs, and specs; better for humans and agents.
- Complete PRD→ADR→spec→plan lifecycle at umbrella level.
- Additive and low-risk: no relocation, `lifeos/openspec/` untouched, CI stays green.
- Reuses installed skills; zero net-new templates.

### Negative
- Routing is convention-based (instruction files), not mechanically enforced.
- The spec home is named `openspec/`, not `spec/` (CLI constraint); a README pointer bridges the label.
- The PRD/ADR registry in `README.md` is maintained manually.

### Risks
- Skills may ignore the routing convention → mitigated by identical blocks in `CLAUDE.md` + `AGENTS.md` and the README routing table.
- Init-generated `.claude` churn → gitignored; `git ls-files architecture/.claude` must be empty.
- PRD/ADR numbering collisions across concurrent sessions → `architecture/README.md` registry is the numbering source of truth.
