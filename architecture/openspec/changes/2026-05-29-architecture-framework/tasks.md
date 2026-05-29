# Tasks — Architecture & Planning Artifact Framework

Zero-decision execution for change `2026-05-29-architecture-framework`. Checkbox
format (OpenSpec parses these). Items map to `design.md` file manifest + PBT.

## 1. Scaffold the openspec engine

- [ ] 1.1 Write `architecture/openspec/config.yaml` with umbrella `context:` + `rules:`
- [ ] 1.2 Write `architecture/openspec/project.md` (umbrella OPSX context)
- [ ] 1.3 Add `architecture/openspec/specs/.gitkeep` and `architecture/openspec/changes/archive/.gitkeep`
- [ ] 1.4 Promote current-truth spec `architecture/openspec/specs/architecture-framework/spec.md`

## 2. Scaffold artifact homes

- [ ] 2.1 Add `architecture/prd/.gitkeep`, `architecture/adr/.gitkeep`, `architecture/plan/.gitkeep`
- [ ] 2.2 Write `architecture/README.md` (lifecycle map, routing table, PRD/ADR registry, links to existing docs)

## 3. Seed dogfood artifacts (via existing skills)

- [ ] 3.1 `architecture/prd/PRD-0001-architecture-framework.md` via `ecc:plan-prd`
- [ ] 3.2 `architecture/adr/ADR-0001-architecture-artifact-homes.md` via `ecc:architecture-decision-records`
- [ ] 3.3 Cross-link PRD-0001 ↔ ADR-0001 ↔ OpenSpec change (relative links)

## 4. Wire routing defaults

- [ ] 4.1 Add identical "Architecture artifacts" block to `CLAUDE.md` (override `docs/superpowers/plans/`, `.claude/prds/`/`.claude/PRPs/prds/`, `docs/adr/`)
- [ ] 4.2 Add the same block to `AGENTS.md`
- [ ] 4.3 Add one `architecture/` entry to `docs/directory-layout.md`

## 5. Verify invariants (PBT) & commit

- [x] 5.1 `no_tracked_local_claude`: `architecture/.claude/` gitignored, `git ls-files architecture/.claude` empty
- [ ] 5.2 `markdown_lint_clean`: `python3 scripts/verify-markdown.py .` exits zero
- [ ] 5.3 `routing_consistency`: CLAUDE.md and AGENTS.md list identical canonical paths
- [ ] 5.4 `additive_scope`: `git diff --name-only` touches only architecture/**, CLAUDE.md, AGENTS.md, docs/directory-layout.md, .gitignore
- [ ] 5.5 `make verify` full pass
- [ ] 5.6 Commit incrementally (Conventional Commits) on `feat/architecture-framework`

## 6. Close out

- [ ] 6.1 Archive the change (`openspec archive 2026-05-29-architecture-framework`) → `changes/archive/`
- [ ] 6.2 Update root `CHANGELOG.md` [Unreleased], `SESSIONS.md`, `TODO.md` via `/wrap-up`

## 7. Deferred (NOT this change)

- [ ] Cross-repo rollout of the `architecture/` convention to submodules
- [ ] Registry generator / MANIFEST-driven adopted-by index
- [ ] Any `docs/` file relocation / consolidation
- [ ] `verify-markdown.py` change to skip git-ignored `.claude` (local-only cosmetics)
