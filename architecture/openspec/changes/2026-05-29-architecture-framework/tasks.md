# Tasks — Architecture & Planning Artifact Framework

Zero-decision execution for change `2026-05-29-architecture-framework`. Checkbox
format (OpenSpec parses these). Items map to `design.md` file manifest + PBT.

## 1. Scaffold the openspec engine

- [x] 1.1 Write `architecture/openspec/config.yaml` with umbrella `context:` + `rules:`
- [x] 1.2 Write `architecture/openspec/project.md` (umbrella OPSX context)
- [x] 1.3 Add `architecture/openspec/specs/.gitkeep` and `architecture/openspec/changes/archive/.gitkeep`
- [x] 1.4 Promote current-truth spec `architecture/openspec/specs/architecture-framework/spec.md` (via `openspec archive`)

## 2. Scaffold artifact homes

- [x] 2.1 Add `architecture/plan/.gitkeep` (`prd/`, `adr/` hold seeded artifacts, no gitkeep needed)
- [x] 2.2 Write `architecture/README.md` (lifecycle map, routing table, PRD/ADR registry, links to existing docs)

## 3. Seed dogfood artifacts (via existing skills)

- [x] 3.1 `architecture/prd/PRD-0001-architecture-framework.md` via `ecc:plan-prd`
- [x] 3.2 `architecture/adr/ADR-0001-architecture-artifact-homes.md` via `ecc:architecture-decision-records`
- [x] 3.3 Cross-link PRD-0001 <-> ADR-0001 <-> OpenSpec change (relative links, both directions)

## 4. Wire routing defaults

- [x] 4.1 Add identical "Architecture artifacts" block to `CLAUDE.md`
- [x] 4.2 Add the same block to `AGENTS.md`
- [x] 4.3 Add one `architecture/` entry to `docs/directory-layout.md`

## 5. Verify invariants (PBT) & commit

- [x] 5.1 `no_tracked_local_claude`: `architecture/.claude/` gitignored, `git ls-files architecture/.claude` empty
- [x] 5.2 `markdown_lint_clean`: `make verify.markdown` exits zero (74 files)
- [x] 5.3 `routing_consistency`: CLAUDE.md and AGENTS.md blocks byte-identical
- [x] 5.4 `additive_scope`: `git diff --name-only origin/develop` within the allowed set
- [x] 5.5 `make verify` full pass (EXIT=0)
- [x] 5.6 Commit incrementally (Conventional Commits) on `feat/architecture-framework`

## 6. Close out

- [ ] 6.1 Archive the change (`openspec archive 2026-05-29-architecture-framework`) -> `changes/archive/`
- [ ] 6.2 Update root `CHANGELOG.md` [Unreleased], `SESSIONS.md`, `TODO.md` via `/wrap-up`

## 7. Deferred (NOT this change)

- [ ] Cross-repo rollout of the `architecture/` convention to submodules
- [ ] Registry generator / MANIFEST-driven adopted-by index
- [ ] Any `docs/` file relocation / consolidation
