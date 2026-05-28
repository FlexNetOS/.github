# CHANGELOG

> Applied changes to the FlexNetOS/.github umbrella repo. Entries are dated and reference the source TODO item, research slug, or `SESSION-` ID where applicable.
> Forward-looking work lives in `TODO.md`. Per-session logs live in `SESSIONS.md`. Deep research artifacts live in `data/brain-data/research/`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the repo aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on release-please overlap:** the `reusable-release.yml` / release-please flow also generates a `CHANGELOG.md` (release `1.0.0` section lives on `origin/release-please--branches--main`). This hand-maintained `[Unreleased]` section is the agent/maintainer working log; when release-please cuts a version it will prepend a dated release section above `[Unreleased]`. See `UA-2026-05-28-001` in `USER.TODO.md` for the reconciliation decision the maintainer must confirm.

---

## [Unreleased]

### Added
- `TODO.md` — agent-side working TODO list (separate from `USER.TODO.md`). (SESSION-2026-05-28-002)
- `CHANGELOG.md` — this file; tracks applied changes per project convention. (SESSION-2026-05-28-002)
- `SESSIONS.md` — per-session log with `SESSION-YYYY-MM-DD-NNN` IDs. (SESSION-2026-05-28-002)
- `data/brain-data/research/my-github-reconciliation.md` — full ralplan consensus deliverable (iteration 3, APPROVED) covering VISION/PLAN/USER.TODO gap analysis, the `.claude` vs `Claude` directory resolution, and the 17-gap reconciliation plan. (research: my-github-reconciliation; SESSION-2026-05-28-001)
- `USER.TODO.md` — `## Agent-flagged user actions` append-only section with `UA-2026-05-28-001` (CHANGELOG ↔ release-please reconciliation). (SESSION-2026-05-28-002)

### Changed
- `.gitignore` — added `tools/repomix/` under "Tool/upstream clones pending fork decision" so the local repomix clone never enters the index; companion to the `feedback-always-commit` + clone-stays-gitignored policy. (SESSION-2026-05-28-003; commit `3dd0ef4`)

### Removed
- _(none yet)_

### Notes
- Convention established 2026-05-28: research/plans → `data/brain-data/research/`; root carries `TODO.md` (agent), `USER.TODO.md` (human; agent appends only to `## Agent-flagged user actions`), `CHANGELOG.md` (applied), `SESSIONS.md` (per-session log). The four files were lost when left untracked and wiped by a routine branch operation; this restoration commits them so the loss cannot recur (see memory `feedback-always-commit`).

---

## Conventions

- **Date format:** ISO 8601 (YYYY-MM-DD).
- **Sections per release:** Added / Changed / Deprecated / Removed / Fixed / Security (Keep a Changelog standard).
- **Cross-references:** implement a `TODO.md` item → `(TODO: <item>)`; implement a research recommendation → `(research: <slug>)`; tie to a session → `(SESSION-YYYY-MM-DD-NNN)`; satisfy a human-action item → `(unblocks: UA-YYYY-MM-DD-NNN)`.
- **Pre-first-cut:** entries land under `[Unreleased]`. release-please prepends dated release sections above it.
