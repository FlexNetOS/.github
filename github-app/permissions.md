# FlexNetOS GitHub App permission matrix

This directory documents the safe path for a FlexNetOS GitHub App that can run
control-plane automation without relying on a personal PAT. The app is not
activated by this repository alone: a maintainer must create it in GitHub, store
its private key in Vaultwarden/Bitwarden, install it on the intended repos, and
then expose only the derived installation-token workflow inputs/secrets that a
specific task needs.

## Safe defaults

- Keep the app **private** to FlexNetOS unless there is a deliberate public
  marketplace plan.
- Store the private key and webhook secret only in Vaultwarden/Bitwarden; never
  commit `.pem`, `.key`, `.env`, or real manifest exports.
- Prefer repository-scoped installation over all-repository installation until
  the automation is proven.
- Give each workflow the minimum app-derived token it needs for that task class.
- Use `scripts/github-app-token-smoke.py` for a local read-only token exchange
  check; it masks all token-like output.

## Environment variables for local smoke tests

| Variable | Required | Purpose |
| --- | --- | --- |
| `GITHUB_APP_ID` | yes | Numeric app id from GitHub App settings. |
| `GITHUB_APP_INSTALLATION_ID` | yes | Installation id for the org/repo installation. |
| `GITHUB_APP_PRIVATE_KEY_FILE` | one of file/value | Path to the PEM private key. Preferred locally. |
| `GITHUB_APP_PRIVATE_KEY` | one of file/value | PEM private key value, usually from a secret manager. |
| `GITHUB_API_URL` | no | API root; defaults to `https://api.github.com`. |

The script fails closed when required variables are missing and does not print
JWTs, private keys, installation tokens, or secret values.

## Task-class permissions

| Task class | Repository permissions | Events | Notes |
| --- | --- | --- | --- |
| Read-only audit | `metadata:read`, `contents:read`, `actions:read`, `administration:read` | none | Inventory repos, workflows, branch protection, rulesets, and runner settings. |
| PR automation | `metadata:read`, `contents:write`, `pull_requests:write`, `issues:write`, `checks:write` | `pull_request`, `check_run`, `check_suite` | Open/update PRs, comment status, and write check runs. Avoid executing untrusted PR code under elevated tokens. |
| Workflow dispatch | `metadata:read`, `contents:read`, `actions:write`, `workflows:write` | `workflow_run`, `push` | Dispatch or rerun approved workflows. Keep caller workflows explicit about `permissions:`. |
| Secret mirror | `metadata:read`, `secrets:write` | none | Used only from a trusted admin machine after Vaultwarden/Bitwarden unlock. Never run on fork PRs. |
| Repository administration | `metadata:read`, `administration:write`, `contents:read` | none | Branch protection/ruleset setup. Keep this separate from day-to-day PR automation and require manual approval. |

## Manifest template

`github-app/manifest.example.json` is a placeholder manifest that documents the
maximum control-plane surface this repo expects. Before creating the real app:

1. Replace all `example.invalid` URLs with the real callback/webhook/setup URLs,
   or disable the webhook if no receiver is deployed yet.
2. Remove any permission that is not needed for the first activation phase.
3. Create the app through GitHub's manifest flow or settings UI.
4. Download the private key once, store it in Vaultwarden/Bitwarden, then delete
   local scratch copies.
5. Install the app only on the pilot repository or a narrow allowlist.
6. Run the smoke test from a trusted shell and confirm it reports token metadata
   without printing the token.

## Vaultwarden/Bitwarden storage

Recommended vault item names:

| Vault item | Field | GitHub/local env |
| --- | --- | --- |
| `github-app/flexnetos-control-plane` | `app_id` | `GITHUB_APP_ID` |
| `github-app/flexnetos-control-plane` | `installation_id` | `GITHUB_APP_INSTALLATION_ID` |
| `github-app/flexnetos-control-plane` | `private_key_pem` | `GITHUB_APP_PRIVATE_KEY` or local PEM file |
| `github-app/flexnetos-control-plane` | `webhook_secret` | future webhook receiver secret |

If these are mirrored into GitHub Actions, map them through a safe example file
such as `secrets/github-secrets.tsv.example`; keep the real mapping file ignored
and local.

## Activation checklist

- [ ] App created with placeholder URLs replaced.
- [ ] Private key and webhook secret stored in Vaultwarden/Bitwarden.
- [ ] App installed on a pilot repo only.
- [ ] Local smoke test succeeds from a trusted admin shell.
- [ ] Workflows that use app tokens declare explicit `permissions:` and do not
      run on untrusted fork code paths.
- [ ] Administration permissions are granted only for the short window needed to
      apply audited policy changes.
