---
name: install-github-app
description: End-to-end guide for creating, credentialing, installing, and smoke-testing the FlexNetOS GitHub App (control-plane automation replacement for PAT-based workflows). Covers manifest flow, Vaultwarden/Bitwarden storage, least-privilege permission selection, org installation, and token smoke verification.
triggers:
  - install github app
  - create github app
  - github app automation
  - flexnetos github app
  - control plane app
  - replace PAT
  - app token
  - installation token
  - github-app manifest
  - phase 4
  - phase 6
  - smoke test app
---

# install-github-app

Guides a FlexNetOS maintainer through Phase 4 of the automation roadmap:
creating the `flexnetos-control-plane-automation` GitHub App, storing credentials
in Vaultwarden/Bitwarden, installing on pilot repos, and verifying the token
exchange — without ever committing secrets.

---

## Prerequisites

- Admin access to the `FlexNetOS` GitHub org.
- Vaultwarden/Bitwarden unlocked locally (`bw unlock` or `pass` store open).
- `python3` available (stdlib only for the smoke test; `cryptography` package
  needed for the non-dry-run exchange — install in a local venv).
- `make` available; repo is on a feature branch (never `main`/`develop` directly).
- The `feat/github-app-automation` branch has been merged or cherry-picked to
  provide: `github-app/manifest.example.json`, `github-app/permissions.md`,
  `scripts/github-app-token-smoke.py`.

---

## Step 1 — Choose the minimum permission set

Open `github-app/permissions.md` and select only the task class(es) active in
the first phase. Default safe starting point for Phase 4:

| Task class | What to enable |
|---|---|
| Read-only audit | `metadata:read`, `contents:read`, `actions:read`, `administration:read` |
| PR automation | add `contents:write`, `pull_requests:write`, `issues:write`, `checks:write` |

Do **not** enable `secrets:write` or `administration:write` until the pilot is
proven. Those can be added in a follow-up installation update.

---

## Step 2 — Prepare the manifest

```bash
cp github-app/manifest.example.json /tmp/flexnetos-app-manifest.json
```

Edit `/tmp/flexnetos-app-manifest.json`:

1. Replace every `https://example.invalid/…` URL with real endpoints, OR set
   `"active": false` in `hook_attributes` if no webhook receiver is deployed yet.
2. Trim `default_permissions` to only the scopes chosen in Step 1.
3. Trim `default_events` to match (remove events for permissions not granted).
4. Keep `"public": false`.

> The repo `.gitignore` blocks `*.json` exports in `github-app/` as defense in
> depth. Never overwrite `manifest.example.json` with real URLs.

---

## Step 3 — Create the app in GitHub

**Option A — Settings UI (simplest for first activation)**

1. Go to `https://github.com/organizations/FlexNetOS/settings/apps/new`.
2. Fill in: App name = `flexnetos-control-plane-automation`, Homepage URL =
   `https://github.com/FlexNetOS/.github`.
3. Set webhook to inactive unless a receiver is deployed.
4. Apply the permissions from Step 1.
5. Set "Where can this GitHub App be installed?" to **Only on this account**.
6. Click **Create GitHub App**.
7. Note the **App ID** (numeric, shown on the app settings page).

**Option B — Manifest flow (for repeatable org provisioning)**

```bash
# The manifest flow uses a one-time redirect to pre-populate fields.
# GitHub does not provide a CLI for this — it must be done via the browser.
# Upload /tmp/flexnetos-app-manifest.json through:
#   https://github.com/organizations/FlexNetOS/settings/apps/new?manifest=<url-encoded-json>
# or paste the JSON into the "Register a GitHub App from a manifest" endpoint.
```

---

## Step 4 — Download and store the private key

1. On the app settings page, scroll to **Private keys** → **Generate a private key**.
2. Browser downloads `flexnetos-control-plane-automation.YYYY-MM-DD.private-key.pem`.
3. Store it immediately in Vaultwarden/Bitwarden:

```bash
# Using pass (current interim secret store):
pass insert github-app/flexnetos-control-plane/private_key_pem < ~/Downloads/flexnetos-*.pem
pass insert github-app/flexnetos-control-plane/app_id          # enter numeric app ID
# installation_id comes after Step 5

# Using Bitwarden CLI:
bw create item  # paste values into custom fields under item "github-app/flexnetos-control-plane"
```

4. Delete the downloaded `.pem` file from `~/Downloads/`.
5. Never place `.pem`, `.key`, `.env`, or real manifest exports anywhere inside
   the git working tree.

---

## Step 5 — Install the app on a pilot repository

1. On the app settings page → **Install App** → **FlexNetOS** org.
2. Choose **Only select repositories** → pick the pilot repo (start with
   `FlexNetOS/.github` itself or a low-risk submodule repo).
3. After install, the URL shows the installation ID:
   `https://github.com/organizations/FlexNetOS/settings/installations/<INSTALLATION_ID>`
4. Store `installation_id` alongside `app_id` in the vault.

---

## Step 6 — Run the token smoke test

```bash
# Dry-run (validates env and signing input, no network call):
export GITHUB_APP_ID="<app_id>"
export GITHUB_APP_INSTALLATION_ID="<installation_id>"
export GITHUB_APP_PRIVATE_KEY_FILE="$(pass show github-app/flexnetos-control-plane/private_key_pem | \
  python3 -c 'import sys,tempfile,os; f=tempfile.NamedTemporaryFile(delete=False,suffix=".pem"); f.write(sys.stdin.buffer.read()); print(f.name)')"

python3 scripts/github-app-token-smoke.py --dry-run

# Live token exchange (requires `cryptography` package):
python3 -m venv /tmp/smoke-venv && /tmp/smoke-venv/bin/pip install cryptography -q
GITHUB_APP_PRIVATE_KEY_FILE="$GITHUB_APP_PRIVATE_KEY_FILE" \
  /tmp/smoke-venv/bin/python scripts/github-app-token-smoke.py

# Or via make (after the Makefile target is wired):
make github-app.smoke DRY_RUN=1
make github-app.smoke
```

**Expected output (non-dry-run):**

```text
[OK] App ID      : <numeric>
[OK] Installation: <numeric>
[OK] JWT issued  : iat=<ts> exp=<ts>
[OK] Token exchange: HTTP 201
[OK] Token type  : token
[OK] Token value : *** (masked)
[OK] Expires at  : <ISO timestamp>
[OK] Permissions : {"contents":"write","pull_requests":"write",...}
```

The script fails closed — any missing env var or HTTP error exits non-zero with
a `ERROR:` prefix. It never prints the private key, JWT, or installation token.

---

## Step 7 — Wire the first workflow

Before giving any workflow an app-derived token:

1. Choose the task class from `github-app/permissions.md`.
2. Add explicit `permissions:` to the caller workflow job.
3. Use `actions/create-github-app-token` (or a repo-local equivalent) to
   exchange the app credentials for a scoped installation token at job start.
4. Never use `pull_request_target` to check out or execute untrusted PR code
   under a write token.
5. Keep `administration:write` out of routine CI jobs — restrict to a
   manually-dispatched maintenance workflow.

Example minimal wiring:

```yaml
jobs:
  automate:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # caller declares minimum; app token carries the write scope
    steps:
      - uses: actions/create-github-app-token@v1
        id: app-token
        with:
          app-id: ${{ secrets.FLEXNETOS_APP_ID }}
          private-key: ${{ secrets.FLEXNETOS_APP_PRIVATE_KEY }}
      - name: use token
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: gh api /repos/FlexNetOS/.github --jq '.full_name'
```

Secrets `FLEXNETOS_APP_ID` and `FLEXNETOS_APP_PRIVATE_KEY` must be mirrored from
Vaultwarden/Bitwarden into GitHub Actions secrets before this runs (Phase 6 of
the roadmap — Vaultwarden→GitHub secret sync).

---

## Activation checklist

Copy this into the PR description or `USER.TODO.md` when activating:

- [ ] App created with placeholder URLs replaced or webhook inactive.
- [ ] Private key downloaded once, stored in vault, deleted from `~/Downloads/`.
- [ ] App ID and installation ID stored in vault alongside private key.
- [ ] App installed on pilot repo only (not all-repositories).
- [ ] Dry-run smoke test passes from a trusted admin shell.
- [ ] Live smoke test passes; token metadata shows expected permissions.
- [ ] Vaultwarden→GitHub secret sync mirrors `FLEXNETOS_APP_ID` and
      `FLEXNETOS_APP_PRIVATE_KEY` (Phase 6 gate before first workflow use).
- [ ] First consuming workflow declares explicit `permissions:` and does not
      run on untrusted fork code paths.
- [ ] `administration:write` is NOT in the initial installation's permission set.

---

## Security constraints (non-negotiable)

| Constraint | Rationale |
|---|---|
| App is private to FlexNetOS | Public apps expose the installation surface. |
| Credentials only in Vaultwarden/Bitwarden | PAT/PEM committed once → rotated forever. |
| Repository-scoped install first | All-repos grants write to every current and future repo. |
| No `administration:write` in routine CI | A compromised workflow cannot alter branch protection. |
| Smoke test before any CI wiring | Proves the token exchange before automation depends on it. |
| Separate app credential secrets from general workflow secrets | Blast-radius isolation. |

---

## Pitfalls

- **Forgetting to delete the downloaded `.pem`**: set a shell alias or hook to
  auto-delete after piping to `pass`. The key is only safe once it is in the vault.
- **All-repos installation**: GitHub pre-selects this. Always choose
  "Only select repositories" on first install.
- **Committing `/tmp/flexnetos-app-manifest.json`**: the working manifest
  copy with real URLs lives in `/tmp`, not in the repo. The repo only has
  `manifest.example.json`.
- **Missing `cryptography` package**: the smoke test prints a clear error and
  exits — install in an isolated venv, never system Python.
- **Phase 6 not complete**: workflows that reference `secrets.FLEXNETOS_APP_ID`
  will fail silently if the Vaultwarden→GitHub sync has not run. Complete the
  secret mirror before wiring the first consumer workflow.
- **`pull_request_target` + write token**: this combination allows fork PRs to
  exfiltrate write-scoped tokens. Never combine them.

---

## Related surfaces in this repo

| Path | Purpose |
|---|---|
| `github-app/manifest.example.json` | Maximum permission manifest template |
| `github-app/permissions.md` | Task-class permission matrix and activation checklist |
| `scripts/github-app-token-smoke.py` | Standalone token exchange validator |
| `docs/templates/github-app/token-smoke.md` | Smoke test usage guide |
| `docs/github-automation-roadmap.md` | Full Phase 1–6 automation queue |
| `scripts/github-doctor.py` | Read-only org/runner/workflow/app health check |
| `secrets/github-secrets.tsv.example` | Safe naming convention for GitHub secrets |

---

## Verification evidence (record here after each activation run)

```text
Date        :
App ID      :
Pilot repo  :
Smoke test  : [ ] dry-run pass  [ ] live pass
Token perms : (copy from smoke test output)
Phase 6 gate: [ ] Vaultwarden sync green
Wired by    :
```
