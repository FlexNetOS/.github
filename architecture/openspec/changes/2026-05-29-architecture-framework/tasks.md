# Tasks — Architecture & Planning Artifact Framework

Execution breakdown for change `2026-05-29-architecture-framework`. Checked off
as implemented. This list is the plan for OpenSpec-driven work (no separate
`architecture/plan/` entry needed for the bootstrap itself).

## 1. Scaffold the `architecture/` tree (additive)

- [ ] `architecture/openspec/config.yaml` — `schema: spec-driven` + umbrella `context:` (mirror `lifeos/openspec/config.yaml`)
- [ ] `architecture/openspec/project.md` — umbrella project context for OPSX
- [ ] `architecture/openspec/specs/.gitkeep`, `architecture/openspec/changes/archive/.gitkeep`
- [ ] `architecture/prd/.gitkeep`, `architecture/adr/.gitkeep`, `architecture/plan/.gitkeep`
- [ ] `architecture/README.md` — lifecycle map, routing table, PRD/ADR registry tables, links to existing design docs

## 2. Seed the dogfood artifacts

- [ ] `architecture/prd/PRD-0001-architecture-framework.md` — intent / scope / success criteria
- [ ] `architecture/adr/ADR-0001-architecture-artifact-homes.md` — the homes decision (MADR), Accepted
- [ ] `architecture/openspec/specs/architecture-framework/spec.md` — capability truth (this change's delta promoted)
- [x] `architecture/openspec/changes/2026-05-29-architecture-framework/proposal.md` — this design doc
- [x] `architecture/openspec/changes/2026-05-29-architecture-framework/tasks.md` — this file
- [ ] `architecture/openspec/changes/2026-05-29-architecture-framework/specs/architecture-framework/spec.md` — change-local spec delta

## 3. Wire the skill-routing defaults

- [ ] Add an **"Architecture artifacts"** convention block to `CLAUDE.md` (project, repo-root)
- [ ] Add the same convention block to `AGENTS.md`
- [ ] Add one `architecture/` entry to `docs/directory-layout.md`

## 4. Verify & commit

- [ ] `make verify.markdown` green on all new/edited files
- [ ] `make verify` full pass
- [ ] Commit incrementally (Conventional Commits) on `feat/architecture-framework`
- [ ] Update root `CHANGELOG.md` `[Unreleased]`, `SESSIONS.md`, `TODO.md` via `/wrap-up`

## 5. Deferred (NOT this change)

- Cross-repo rollout of the `architecture/` convention to submodules
- Registry generator / MANIFEST-driven adopted-by index
- Any `docs/` file relocation / consolidation
- Promotion to an org-wide inheritable standard
