# Open Questions — FlexNetOS umbrella reconciliation

> Schema (validated by `scripts/open-questions-lint.js`): every entry is a `### `
> heading (or a `- [ ]` / `- [x]` checklist item) and MUST contain all three
> labelled fields below. Keep entries append-only; resolve by editing the entry
> in place and moving the decision into CHANGELOG.md / the relevant plan.
>
> Required fields per entry:
> - `**Question:**` — the decision to be made, phrased as a question.
> - `**Candidates:**` — the concrete options under consideration.
> - `**Blocker for resolution:**` — what is needed before this can be decided.

---

### G3 triage — repos/ai-top-utility (stray clone)

**Question:** Should the stray clone at `repos/ai-top-utility` (origin under
`github.com/FlexNetOS/`) be converted into a tracked submodule via the
g3b→g3c→materialize chain, left in place, or removed?

**Candidates:**
- Convert: add to `repos/MANIFEST.yaml` under `owned/`, run g3b backup → g3c move
  → submodule materialize at the canonical mount.
- Leave as an untracked working clone (status quo).
- Remove if it is a throwaway/experiment with no upstream value.

**Blocker for resolution:** Confirmation from the user that `ai-top-utility` is a
keeper that belongs in the umbrella manifest (vs. scratch), and which group
tags it should carry.

### G3 triage — repos/fabro (stray clone, non-FlexNetOS origin)

**Question:** `repos/fabro` has origin `github.com/fabro-sh/fabro` (NOT under
FlexNetOS, g3a reports UNSAFE-MISMATCH/13). Do we fork it into FlexNetOS first,
keep it as an external read-only clone, or drop it?

**Candidates:**
- Fork to `FlexNetOS/fabro`, then add under `forked/` with `upstream:` set, then
  convert via the g3 chain (requires the research-before-fork dossier first).
- Add as an `external/` submodule pointing directly at `fabro-sh/fabro` (no fork).
- Remove the stray clone if it is not needed.

**Blocker for resolution:** A research dossier at
`data/brain-data/research/fabro.md` (research-before-fork rule) plus a user
go/no-go on forking vs. external-tracking vs. drop.

### G3 triage — repos/paperclip (stray clone, non-FlexNetOS origin)

**Question:** `repos/paperclip` has origin `github.com/paperclipai/paperclip`
(NOT under FlexNetOS, g3a reports UNSAFE-MISMATCH/13). Fork, external-track, or
drop?

**Candidates:**
- Fork to `FlexNetOS/paperclip`, add under `forked/` with `upstream:`, convert.
- Add as an `external/` submodule pointing at `paperclipai/paperclip`.
- Remove the stray clone if not needed.

**Blocker for resolution:** A research dossier at
`data/brain-data/research/paperclip.md` (research-before-fork rule) plus a user
go/no-go on forking vs. external-tracking vs. drop.

### G4/G5 — MANIFEST→.gitmodules materialize vs. existing submodules.add

**Question:** Should a new MANIFEST→`.gitmodules` lockfile (materialize) pattern
replace the existing, working `scripts/submodule-add-all.sh` machinery?

**Candidates:**
- Keep `submodule-add-all.sh` as-is (current working path); add only read-only
  verification on top.
- Introduce a `materialize` step that regenerates `.gitmodules` deterministically
  from `repos/MANIFEST.yaml` as the single source of truth, deprecating the
  imperative add flow.
- Hybrid: materialize for new entries, keep add for one-offs.

**Blocker for resolution:** Deferred from the additive-tooling pass because it
refactors working code; needs a coordinator-owned design decision and a
migration/rollback plan before any `.gitmodules` regeneration is attempted.

### G15 — release canon: RELEASING.md vs .omc/RELEASE_RULE.md

**Question:** Which document is the canonical source of release rules for the
umbrella — a committed `RELEASING.md`, or the `.omc/RELEASE_RULE.md` cache used
by the `release` skill?

**Candidates:**
- `RELEASING.md` is canonical; `.omc/RELEASE_RULE.md` is a derived/cached copy.
- `.omc/RELEASE_RULE.md` is canonical; `RELEASING.md` is human-facing narrative.
- Single file only (pick one, delete/redirect the other).

**Blocker for resolution:** User decision on canon ownership, plus confirmation
of whether the `release` skill must read a specific path.

### G16 — wiki/ growth policy

**Question:** What is the growth/retention policy for the `wiki/` directory as it
accumulates knowledge documents?

**Candidates:**
- Unbounded append with periodic manual curation.
- Size/age-based pruning with an index and archive.
- Move long-form knowledge into a dedicated knowledge backend, keep `wiki/` as an
  index only.

**Blocker for resolution:** User direction on how much knowledge should live in
the committed repo vs. external memory backends, and who owns curation.
