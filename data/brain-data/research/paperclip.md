# Research: paperclip

**Status:** Pre-adoption research. **Third-party upstream — needs fork.**
**Action gated by this dossier:** `gh repo fork paperclipai/paperclip --org FlexNetOS` + branch setup + submodule at `repos/forked/paperclip/`.

**Cross-reference:** Matches [my-github-reconciliation.md](my-github-reconciliation.md) Reservation 2 — paperclip origin is NOT under FlexNetOS, so G3a will exit 13 (UNSAFE-MISMATCH). Operator must triage via this dossier before fork.

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/paperclipai/paperclip.git` |
| Our fork (to be created) | `https://github.com/FlexNetOS/paperclip` |
| License | **MIT** |
| Upstream default branch | `master` |
| Current local branch | `master` |
| Local state | clean; in sync with origin/master |
| Latest upstream commit | `de367435 docs(readme): align README with brand guidelines (PAPA-439) (#6810)` (2026-05-27) |
| Docs site | `https://paperclip.ing/docs` |
| Community | Discord + Twitter (`@papercliping`) |

## 2. Purpose (per README)

> *"Paperclip is the app people use to manage AI agents for work."*

Managed-agent UI/runtime — give it tasks, it dispatches AI agents,
operator monitors and intervenes. Brand-conscious (recent commit was
"brand guidelines alignment"), suggesting a commercially-oriented project
even though MIT-licensed.

Repo structure (high-signal): `cli/`, `server/`, `ui/`, `packages/`,
`scripts/`, `tests/`, `evals/`, `releases/`, `report/`, `screenshots/`,
`skills/`, `security/`, `doc/`, `docker/`, `assets/`, `patches/`.
`skills/` may align with the FlexNetOS skill registry concept.

## 3. Stack inventory

- Root `package.json`: `"name": "paperclip"`, `"private": true`, `"type": "module"`.
- Root `Dockerfile`.
- `.env.example` present.
- `.agents/`, `.claude/` directories — overlap with FlexNetOS
  conventions.
- `cli/`, `server/`, `ui/` separation suggests Node/TS across three
  process boundaries. Verify on adoption whether single TS monorepo or
  language splits.

## 4. FlexNetOS-side intent

Overlaps `fabro` (graph orchestration) and the existing PENDING-FORK
agents. Distinct because:
- **End-user-facing app** (UI present), not just runtime library / CLI.
- **`skills/` directory** may align with FlexNetOS skill registry.
- **Brand-conscious upstream** — keep FlexNetOS modifications scoped to
  org-side surfaces; do NOT touch upstream brand materials.

Likely use: candidate for daily AI-agent management surface, with
`skills/` being the most interesting hook for FlexNetOS-wide skill
standardization.

## 5. Pre-adoption audit

- License is MIT — no friction to fork.
- Local clone clean, in sync with `paperclipai/paperclip:master`.
- Upstream default is `master`, not `main`. Fork's `master` mirrors
  upstream; `develop` carries FlexNetOS changes.
- Brand-sensitive (recent commit was brand-guideline alignment). Limit
  FlexNetOS surface to org-only — definitely no README header rewrites,
  no banner asset changes.
- Has `skills/` dir. Document FlexNetOS-side skill conventions in
  `.github/FLEXNETOS-ENV.md` rather than modifying their `skills/`
  layout.
- Issue numbering visible in upstream commits (`PAPA-439`). Upstream
  uses Jira-style ticket prefixes; FlexNetOS commits on `develop` should
  NOT carry those — confusion risk.
- `releases/` at root may contain large artifacts. Check size before
  deciding `partial_clone` setting.

## 6. Adoption plan

Case: **third-party — needs fork**.

1. **Irreversible: requires user explicit go-ahead + this dossier section 9
   resolved.**
   ```bash
   gh repo fork paperclipai/paperclip --org FlexNetOS --clone=false
   ```
2. Rewire local clone's remotes:
   ```bash
   cd repos/paperclip
   git remote rename origin upstream
   git remote add origin https://github.com/FlexNetOS/paperclip.git
   git push origin master                        # seed the fork's master
   git checkout -b develop && git push -u origin develop
   ```
3. Replace plain clone with submodule:
   ```bash
   # From umbrella root
   rm -rf repos/paperclip
   mkdir -p repos/forked
   git submodule add --depth=1 -b develop \
       https://github.com/FlexNetOS/paperclip.git \
       repos/forked/paperclip
   cd repos/forked/paperclip
   git remote add upstream https://github.com/paperclipai/paperclip.git
   ```
4. MANIFEST entry:
   ```yaml
   - path: repos/forked/paperclip
     url: https://github.com/FlexNetOS/paperclip
     upstream: https://github.com/paperclipai/paperclip
     branch: develop
     toolchain: [node, docker]
     groups: [forked, agents, ui]
     notes: |
       AI agent management app (MIT). Upstream uses `master`; fork's
       `master` mirrors upstream, `develop` carries FlexNetOS changes.
       Brand-sensitive upstream — keep modifications scoped to org-only
       surfaces.
   ```
5. Phase B (org-only rename) on `develop`:
   - `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`
   - Branch protection on `master`: linear history, no direct pushes
   - Branch protection on `develop`: PR + 1 review
   - `.github/FUNDING.yml`: FlexNetOS funding
   - `.github/FLEXNETOS-ENV.md`: env-scaffold pointer
   - `.github/workflows/ci.yml`: caller for umbrella reusables
   - **DO NOT** touch upstream README, banner, logo, product copy.

## 7. Sync risk

**Medium.** Active upstream, brand-conscious:
- Brand-driven README/banner changes are frequent → guaranteed friction
  if FlexNetOS edits README. Resolution: don't edit README on `develop`.
- `skills/` likely to grow → if FlexNetOS adds skills there, conflicts
  with upstream additions sharing namespace. Resolution: FlexNetOS skills
  under `skills/flexnetos/` subdirectory or top-level
  `.flexnetos-skills/`.
- `releases/` may have binary churn → exclude from partial-clone if
  needed.

## 8. Verification

```bash
cd /home/drdave/workspace/my-github
make verify.manifest
make submodules.sync-upstream NAME=paperclip   # "no upstream changes"
git -C repos/forked/paperclip diff upstream/master..develop -- \
    package.json Dockerfile README.md          # must be empty
git -C repos/forked/paperclip diff upstream/master..develop -- \
    'doc/assets/*' assets/                     # must be empty (brand)
```

## 9. Open decisions for user

- [ ] **Go/no-go on `gh repo fork paperclipai/paperclip --org FlexNetOS`.**
- [ ] Adoption priority vs fabro and the 4 PENDING-FORK agents — all
      overlap in role; sequencing matters for which becomes daily driver
      vs. reference.
- [ ] `skills/` integration strategy: contribute back upstream, keep
      FlexNetOS skills in a separate subdirectory, or both?
- [ ] Brand sensitivity: confirm no FlexNetOS-side branding changes
      intended for the fork (would invalidate the "org-only" rename
      scope).

## 10. Decision log

(empty — fill on adoption)
