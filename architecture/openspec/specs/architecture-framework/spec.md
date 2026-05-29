# architecture-framework Specification

## Purpose
TBD - created by archiving change 2026-05-29-architecture-framework. Update Purpose after archive.
## Requirements
### Requirement: Single common root for architecture artifacts

The umbrella repository SHALL host all design-time architecture artifacts under a single top-level directory named `architecture/`, containing `prd/`, `adr/`, `plan/`, and `openspec/` subdirectories plus a `README.md` index.

#### Scenario: Artifact homes exist under one root

- **WHEN** an agent or contributor looks for PRDs, ADRs, plans, or specs in the umbrella repo
- **THEN** all four SHALL be reachable under `architecture/` (`architecture/prd/`, `architecture/adr/`, `architecture/plan/`, `architecture/openspec/`)
- **AND** `architecture/README.md` SHALL document the lifecycle and index existing PRDs and ADRs

#### Scenario: Spec stage maps to the OpenSpec engine

- **WHEN** the lifecycle references the "spec" stage
- **THEN** it SHALL resolve to `architecture/openspec/` (named `openspec/` so the OpenSpec CLI can locate it)
- **AND** `architecture/README.md` SHALL carry an `architecture/spec → openspec/` pointer for the `/spec` label

### Requirement: Defined artifact lifecycle with cross-links

The framework SHALL define the flow PRD → ADR → OpenSpec change/spec → plan → implement → archive, with relative-markdown cross-links connecting related artifacts.

#### Scenario: Artifacts reference their neighbors

- **WHEN** an ADR records a decision driven by a PRD
- **THEN** the ADR SHALL link back to the PRD
- **AND** the OpenSpec change implementing that decision SHALL link the ADR

### Requirement: Skill outputs route to canonical homes

The repository SHALL declare canonical output paths for the installed artifact-producing skills in `CLAUDE.md` and `AGENTS.md`, overriding each skill's built-in default.

#### Scenario: A planning skill routes to the architecture home

- **WHEN** an agent runs `superpowers:writing-plans` in the umbrella repo
- **THEN** repo instructions SHALL direct the plan to `architecture/plan/YYYY-MM-DD-<slug>-plan.md`
- **AND** NOT to the skill's built-in `docs/superpowers/specs/` default

#### Scenario: No net-new templates are introduced

- **WHEN** any artifact (PRD, ADR, spec, plan) is created under `architecture/`
- **THEN** it SHALL be produced by an already-installed skill
- **AND** the framework SHALL NOT add bespoke artifact templates

### Requirement: Naming, numbering, and status conventions

PRDs SHALL be named `PRD-NNNN-<slug>.md` and ADRs `ADR-NNNN-<slug>.md` with 4-digit sequential numbering; plans SHALL be named `YYYY-MM-DD-<slug>-plan.md`; OpenSpec changes SHALL use date-prefixed slugs and archive to `changes/archive/`.

#### Scenario: An ADR is immutable once accepted

- **WHEN** an ADR reaches status `Accepted`
- **THEN** it SHALL NOT be rewritten
- **AND** a later decision SHALL supersede it via a new ADR referencing it as `Superseded-by ADR-NNNN`

### Requirement: Additive, non-destructive introduction

Introducing the framework SHALL be additive: it SHALL NOT relocate existing `docs/` files, SHALL NOT modify `lifeos/openspec/`, and SHALL NOT run `openspec init` (avoiding `.claude/` churn).

#### Scenario: Existing instances are untouched

- **WHEN** the `architecture/` tree is scaffolded
- **THEN** `lifeos/openspec/` SHALL remain unchanged
- **AND** existing `docs/` files SHALL be linked from `architecture/README.md`, not moved

### Requirement: Submodule-adoption convention

The framework SHALL define how submodules carry their own artifacts: `owned/` repos use the same `architecture/` shape at their root; `forked/` repos place FlexNetOS artifacts on the `develop` branch under `architecture/`; `external/` repos carry none.

#### Scenario: Forked-repo artifacts stay off the upstream branch

- **WHEN** a FlexNetOS architecture artifact is authored for a `repos/forked/<x>` submodule
- **THEN** it SHALL live on that submodule's `develop` branch under `architecture/`
- **AND** SHALL NOT be committed to `main`/`master`, which mirror upstream

