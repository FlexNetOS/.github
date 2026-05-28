# GitHub automation roadmap

This is the Ralph loop queue for turning `FlexNetOS/.github` into the full GitHub control plane. The rule is small, safe, stacked PRs: each pass adds one verified automation layer, then hands off the next target.

## Current stack

| PR | Branch | Purpose | Base |
| --- | --- | --- | --- |
| #12 | `infra/network-slim-control-plane` | Network/Slim control-plane architecture | `main` |
| #13 | `feat/vaultwarden-github-secrets` | Vaultwarden/Bitwarden to GitHub secret sync | `infra/network-slim-control-plane` |
| next | `feat/github-control-plane-doctor` | One-command read-only GitHub control-plane doctor and roadmap | `feat/vaultwarden-github-secrets` |

## Definition of done

The GitHub process is fully automated when a maintainer can run a local doctor, see every missing GitHub control-plane surface, and activate each layer from documented dry-run-first scripts without committing secrets or mutating the host by surprise.

- [ ] One-command local doctor for runner, workflows, GitHub App, submodules, secrets, policy, releases, and live GitHub status.
- [ ] Local/self-hosted runner install/register/remove/status path with dry-run-first safety.
- [ ] Reusable workflow templates and caller examples for lint, test, build, security, secrets, submodules, and release.
- [ ] GitHub App manifest template, permission matrix, private-key storage guidance, and installation-token smoke test.
- [ ] Subrepo/submodule graph validation against `repos/MANIFEST.yaml`, `.gitmodules`, and live GitHub remotes.
- [ ] Vaultwarden/Bitwarden secret sync and rotation docs with no committed secret values or real local mapping file.
- [ ] Branch/ruleset/CODEOWNERS/community-health audit path.
- [ ] Dependabot, release, and security automation checks documented and locally verifiable.
- [ ] Manual activation points are explicit for any step needing GitHub admin permissions, runner registration tokens, private keys, or host service changes.
- [ ] Active work is represented as focused PRs with CI/check status monitored.

## Ralph phases

### Phase 1 — Baseline and doctor

Status: in progress.

Deliverables:

- [x] `docs/github-automation-roadmap.md` queue.
- [x] `scripts/github-doctor.py` read-only offline/live/JSON/strict doctor.
- [x] `make github.doctor` entry point.
- [ ] `make github.doctor STRICT=1` or equivalent gating in CI once expected surfaces are present.

Acceptance:

- The doctor runs without secrets.
- Live GitHub checks are optional and degrade to warnings when `gh` is unavailable.
- Missing surfaces are reported as action items, not silently ignored.

### Phase 2 — Local runner lifecycle

Status: hardened in the local runner lifecycle PR.

Existing surfaces:

- `runner/install.sh`
- `runner/register.sh`
- `runner/ephemeral-spawn.sh`
- `runner/systemd/runner-spawn@.service`
- `runner/systemd/runner-spawn@.timer`
- `docs/self-hosted-runner.md`

Next deliverables:

- [x] Add `runner/.env.example` with labels, runner directory, scope, service mode, and dry-run defaults.
- [x] Add `scripts/runner-doctor.sh` or fold deeper runner checks into `scripts/github-doctor.py`.
- [x] Add `runner.remove` / `runner.doctor` Make targets.
- [x] Confirm install/register scripts refuse destructive or host-mutating actions unless explicit flags are set.

Acceptance:

- Registration tokens are fetched live and never stored in git.
- Default mode is dry-run/read-only.
- Untrusted fork PRs cannot land on local runners by default.

### Phase 3 — Reusable workflows

Status: present, with stacked-branch CI and an upgrade-only auto-review/auto-merge gate added.

Existing surfaces include reusable lint, test, build, security, release, secrets, and submodule workflows under `.github/workflows/`, plus the metadata-only `auto-review-merge.yml` upgrade gate.

Next deliverables:

- [ ] Add caller examples for normal repos, submodule repos, and secrets-aware repos.
- [ ] Add a workflow permission matrix documenting required `permissions:` and secrets per reusable workflow.
- [ ] Add local `act --list` guidance or a repo-local wrapper that never requires secrets by default.
- [x] Run CI on stacked PR branches (`branches: ['**']`) so every PR layer reports checks.
- [x] Add same-repo upgrade-only auto-review/auto-merge gating that never checks out PR code.

Acceptance:

- Every reusable workflow has explicit permissions.
- Caller examples use GitHub-hosted runners unless they intentionally request the local label set.
- Secrets are named consistently with `secrets/github-secrets.tsv.example`.

### Phase 4 — GitHub App automation

Status: not yet materialized.

Next deliverables:

- [ ] Add `github-app/manifest.example.json`.
- [ ] Add `github-app/permissions.md` least-privilege matrix.
- [ ] Add `scripts/github-app-token-smoke.py` that reads env vars, signs a JWT, requests an installation token, masks output, and fails closed without secrets.
- [ ] Document Vaultwarden storage for the app private key and webhook secret.

Acceptance:

- No real private key, app ID, installation ID, client secret, or webhook secret is committed.
- App permissions are separated by task class: read-only audit, PR automation, workflow dispatch, repository administration.

### Phase 5 — Subrepo/submodule graph

Status: partially present.

Existing surfaces:

- `repos/MANIFEST.yaml`
- `.gitmodules`
- submodule helper scripts
- manifest verifier

Next deliverables:

- [ ] Add a live remote audit that compares manifest URLs to GitHub API results.
- [ ] Add a `.gitmodules` drift check.
- [ ] Add docs for adding/removing/updating owned, forked, and external subrepos.

Acceptance:

- Nested source trees are either registered submodules or ignored until canonicalized.
- `make verify` catches manifest shape and submodule drift.

### Phase 6 — Secrets and policy sync

Status: partially present via PR #13.

Existing surfaces:

- `scripts/secrets-sync-github-from-bitwarden.sh`
- `secrets/github-secrets.tsv.example`
- `secrets/README.md`
- `.gitignore` rule for the real local mapping file

Next deliverables:

- [ ] Add dry-run CI smoke test with stubbed `bw` and `gh`.
- [ ] Add branch protection/ruleset/CODEOWNERS audit script.
- [ ] Document secret rotation from Vaultwarden through GitHub repo/env/org secrets.

Acceptance:

- Real mapping file remains private.
- Scripts never print cleartext secret values.
- Policy/ruleset changes are audited before enforcement.

### Phase 7 — Full control-plane loop

Status: planned.

Next deliverables:

- [ ] Promote `make github.doctor` into the top-level operator command.
- [ ] Add a generated or documented report section for each control-plane area.
- [ ] Add recovery playbooks for failed runner registration, failed workflow dispatch, failed GitHub App token exchange, submodule drift, and stale secrets.

Acceptance:

- A maintainer can identify the next safe action from one local command.
- Non-dry-run actions require explicit flags and state exactly what they will change.
