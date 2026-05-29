# Design — Architecture & Planning Artifact Framework

Implementation design for change `2026-05-29-architecture-framework`, synthesized
from multi-model planning (Claude + codex/gpt-5.5; antigravity unavailable). This
is a zero-decision plan: every step is mechanical, every ambiguity resolved.

## Implementation approach (ordered, mechanical)

1. Scaffold `architecture/openspec/` data files: `config.yaml` (with umbrella
   `context:` + `rules:`), `project.md`, and `.gitkeep` in `specs/` and
   `changes/archive/`.
2. Promote the change-local spec delta to current truth at
   `architecture/openspec/specs/architecture-framework/spec.md`.
3. Scaffold artifact homes: `architecture/prd/.gitkeep`,
   `architecture/adr/.gitkeep`, `architecture/plan/.gitkeep`.
4. Seed dogfood artifacts: `PRD-0001-architecture-framework.md` (via
   `ecc:plan-prd`) and `ADR-0001-architecture-artifact-homes.md` (via
   `ecc:architecture-decision-records`), cross-linked to each other and the
   OpenSpec change.
5. Write `architecture/README.md`: lifecycle map, routing table, PRD/ADR
   registry tables, and relative links to existing design docs.
6. Add the identical **Architecture artifacts** routing block to `CLAUDE.md`
   and `AGENTS.md`, overriding the real built-in skill defaults
   (`docs/superpowers/plans/`, `.claude/prds/` or `.claude/PRPs/prds/`,
   `docs/adr/`).
7. Add one `architecture/` entry to `docs/directory-layout.md`.
8. Verify (`make verify`) and commit incrementally; then archive the change.

## PBT properties (invariants + falsification)

| Property | Definition | Falsification |
|---|---|---|
| `single_root_reachability` | Each of `prd/`, `adr/`, `plan/`, `openspec/` exists under `architecture/` and is named canonical in the README routing table. | Any class absent, points outside `architecture/`, or missing from README. |
| `no_tracked_local_claude` | No `architecture/.claude/**` path is tracked. | `git ls-files architecture/.claude` returns any path. |
| `markdown_lint_clean` | `python3 scripts/verify-markdown.py .` exits zero after adding tracked docs. | Verifier reports untagged/unclosed fences or multiple H1s in changed files. |
| `openspec_literal_directory` | Spec engine lives at `architecture/openspec/`; no physical `architecture/spec/` is created. | `test -d architecture/spec` succeeds, or docs instruct a physical `architecture/spec/` path. |
| `routing_consistency` | The routing block in `CLAUDE.md` and `AGENTS.md` lists the same canonical paths for all four artifact classes. | The two files disagree on any path or omit a class. |
| `additive_scope` | Framework delivery changes only `architecture/**`, `CLAUDE.md`, `AGENTS.md`, `docs/directory-layout.md`, `.gitignore`. | `git diff --name-only` includes `repos/**`, `lifeos/**`, or unrelated docs. |
| `cross_link_graph` | PRD-0001 ↔ ADR-0001 ↔ OpenSpec change are mutually linked; README links both registries. | Any required relative link missing or pointing to a non-existent tracked path. |
| `numbering_format` | PRDs match `PRD-[0-9]{4}-<slug>.md`, ADRs `ADR-[0-9]{4}-<slug>.md`, plans `YYYY-MM-DD-<slug>-plan.md`. | Any seeded artifact violates its filename convention. |

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Init-generated `architecture/.claude/` markdown breaks CI. | Keep it gitignored; assert `git ls-files architecture/.claude` is empty. |
| CI fails on untagged code fences in new docs. | Language-tag every fence (`text`/`bash`/`yaml`/`markdown`); run the verifier pre-commit. |
| Agents keep writing to built-in skill defaults. | Identical routing blocks in both root instruction files + the README table. |
| OpenSpec can't discover the spec tree from the wrong CWD. | Document that umbrella OpenSpec commands run from `architecture/`. |
| Concurrent sessions allocate the same PRD/ADR number. | `architecture/README.md` registry is the numbering source of truth; seed only `0001`. |
| Current spec vs change-local delta conflated. | `specs/architecture-framework/spec.md` is current truth; the change-local file is the ADDED delta. |
| Existing `docs/` content accidentally relocated. | Only edit `docs/directory-layout.md`; link all other docs from the README. |
| Submodule-adoption language triggers premature submodule edits. | State rollout to `repos/{owned,forked,external}` is deferred + documentation-only. |

## File manifest

```text
architecture/README.md
architecture/prd/.gitkeep
architecture/prd/PRD-0001-architecture-framework.md
architecture/adr/.gitkeep
architecture/adr/ADR-0001-architecture-artifact-homes.md
architecture/plan/.gitkeep
architecture/openspec/config.yaml
architecture/openspec/project.md
architecture/openspec/specs/.gitkeep
architecture/openspec/specs/architecture-framework/spec.md
architecture/openspec/changes/archive/.gitkeep
architecture/openspec/changes/2026-05-29-architecture-framework/proposal.md
architecture/openspec/changes/2026-05-29-architecture-framework/tasks.md
architecture/openspec/changes/2026-05-29-architecture-framework/design.md
architecture/openspec/changes/2026-05-29-architecture-framework/specs/architecture-framework/spec.md
CLAUDE.md
AGENTS.md
docs/directory-layout.md
.gitignore
```
