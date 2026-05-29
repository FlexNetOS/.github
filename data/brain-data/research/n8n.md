# Research: n8n

**Status:** Pre-adoption research. **Already forked** to FlexNetOS/n8n; only path normalization and branch setup remain.
**Action gated by this dossier:** Set up `develop` branch on FlexNetOS/n8n, replace `repos/n8n/` plain clone with submodule at `repos/forked/n8n/`, add MANIFEST entry.

**Cross-reference:** Matches [my-github-reconciliation.md](my-github-reconciliation.md) D1 — n8n is the highest-priority "do-not-destroy" case. Expected G3a exit: 0 (SAFE — origin already FlexNetOS/n8n, matches MANIFEST upstream pattern).

## 1. Identity

| Field | Value |
| --- | --- |
| Origin (our fork) | `https://github.com/FlexNetOS/n8n.git` |
| Upstream | `https://github.com/n8n-io/n8n.git` |
| Upstream remote | already wired locally as `upstream` |
| License | Sustainable Use License + Apache 2.0 (n8n fair-code dual license — verify implications) |
| Upstream default branch | `master` |
| Current local branch | `master` |
| Local state | clean; in sync with origin/master |
| Latest commit | `25a836dfb7 feat(editor): Show data redaction scope dropdown to unlicensed users (#30966)` (2026-05-28) |
| Visible branches | `master` + ~3596 remote branches (PR branches mostly) |

## 2. Purpose (per README)

> *"n8n - Secure Workflow Automation for Technical Teams. n8n is a workflow automation platform that gives technical teams the flexibility of code with the speed of no-code. With 400+ integrations, native AI capabilities, and a fair-code license, n8n lets you build powerful automations while maintaining full control over your data and deployments."*

Monorepo packaged as `n8n-monorepo` (version 2.23.0 at time of research).
400+ integrations, native AI nodes, fair-code license.

## 3. Stack inventory

- Node monorepo. Root `package.json`: `"name": "n8n-monorepo"`,
  `"version": "2.23.0"`, `"private": true`.
- Directories: `apps/`, `bin/`, `docker/`, `docs/`, `evals/`, `installer/`,
  `lib/`, `packages/`, `target/`, `test/`. Polyglot signals (`target/`,
  `.cargo/`) — verify Rust components on adoption.
- `.github/` directory in upstream — our caller `ci.yml` must use a
  different filename and not edit upstream's.

## 4. License caveat (READ BEFORE ADOPTING)

n8n is **not pure MIT**. Sustainable Use License restricts some commercial
uses. Forking permitted under license; any FlexNetOS distribution / hosted
offering using n8n must respect SUL terms. Read `LICENSE.md` before
deciding what FlexNetOS does with the fork. Hosted/SaaS-like intent →
loop in counsel. Internal automation only → SUL is permissive enough.

## 5. FlexNetOS-side intent

Fits the umbrella's "workflow automation" role:
- Drive cross-repo automation that doesn't fit GitHub Actions
  (long-running, external API orchestration, scheduled jobs).
- Native AI node integration for the FlexNetOS agent fleet.
- Potential to wire into `mempalace`, `ruvector`, `understand-anything`
  via custom nodes.

## 6. Pre-adoption audit

- Fork already at `FlexNetOS/n8n`. **No `gh repo fork` needed.**
- `upstream` remote wired locally.
- No `develop` branch yet. Must create from `origin/master` before
  adoption.
- Upstream uses `master`, not `main`. `docs/fork-workflow.md` treats
  "main" generically as "upstream default" — set up `master`<->upstream.
- License is fair-code (SUL). Section 4 caveat applies.
- Very active upstream (thousands of branches, frequent commits).
  Sync cadence **weekly at most**, likely monthly, to avoid churn.

## 7. Adoption plan

Case: **already forked — just normalize**.

1. Push current `master` to fork, then create `develop`:
   ```bash
   cd repos/n8n
   git fetch upstream master
   git checkout master && git merge --ff-only upstream/master
   git push origin master                       # mirror upstream
   git checkout -b develop origin/master 2>/dev/null || git checkout develop
   git push -u origin develop
   ```
2. Replace plain clone with submodule:
   ```bash
   # From umbrella root
   rm -rf repos/n8n
   mkdir -p repos/forked
   git submodule add --depth=1 -b develop \
       https://github.com/FlexNetOS/n8n.git \
       repos/forked/n8n
   cd repos/forked/n8n
   git remote add upstream https://github.com/n8n-io/n8n.git
   ```
3. MANIFEST entry (FORKED section):
   ```yaml
   - path: repos/forked/n8n
     url: https://github.com/FlexNetOS/n8n
     upstream: https://github.com/n8n-io/n8n
     branch: develop
     toolchain: [node, docker]
     groups: [forked, automation, workflow]
     notes: |
       Workflow automation platform (fair-code SUL license — see
       LICENSE.md). Upstream uses `master`; fork's `master` mirrors
       upstream, `develop` carries FlexNetOS changes.
   ```
4. Phase B (org-only rename) on `develop`:
   - `.github/CODEOWNERS`: add `* @FlexNetOS/maintainers`
   - Branch protection on `master` (mirror): linear history, block direct
     pushes
   - Branch protection on `develop`: PR + 1 review
   - `.github/FUNDING.yml`: copy from umbrella
   - `.github/FLEXNETOS-ENV.md`: env-scaffold pointer
   - `.github/workflows/ci.yml`: thin caller using umbrella reusables
5. Skip Phase D for upstream's `.env.example` — leave alone.

## 8. Sync risk

**Medium.** Upstream very active:
- `package.json` changes most weeks (versions, deps). We never edit it →
  fast-forward.
- Upstream `.github/workflows/` may change. Our caller has different
  filename (`ci.yml`) → no conflict.
- Big refactors in upstream's `packages/` could create textual conflicts
  on our `develop` if we have commits in same files. Mitigate: keep
  FlexNetOS commits scoped to **new files**.

## 9. Verification

```bash
cd /home/drdave/workspace/my-github
make verify.manifest
make submodules.sync-upstream NAME=n8n          # "no upstream changes"
git -C repos/forked/n8n diff upstream/master..develop -- \
    package.json Dockerfile README.md           # must be empty
```

## 10. Open decisions for user **DO NOT USE FORK UNTIL SOURCE CLONE IS PROPERLY SET UP**

- [ ] License: confirm SUL terms compatible with intended FlexNetOS use
      case before adoption or any hosted deployment.
- [ ] Sync cadence — weekly, monthly, or "as-needed"? Tunes
      `submodule-bump.yml` schedule.
- [ ] Are there local FlexNetOS-side changes in current `repos/n8n/` tree
      that need to land on `develop` before cut-over?

## 11. Decision log

(empty — fill on adoption)
