# GitHub App automation template

This template shows how a trusted local maintainer can validate a FlexNetOS
GitHub App installation token without committing any real credentials.

## 1. Create the app from the template

Start with [`github-app/manifest.example.json`](../../github-app/manifest.example.json)
and replace every placeholder URL before creating the real app. For the first
activation, remove permissions that are not needed by the pilot workflow.

## 2. Store credentials in Vaultwarden/Bitwarden

Recommended item: `github-app/flexnetos-control-plane`

Required fields:

- `app_id`
- `installation_id`
- `private_key_pem`
- `webhook_secret` (only after a webhook receiver exists)

Do not store the private key in the repository. The repo `.gitignore` blocks
`.pem`, `.key`, `.env`, and `.env.*` files as defense in depth.

## 3. Run the smoke test from a trusted shell

```bash
export GITHUB_APP_ID="123456"
export GITHUB_APP_INSTALLATION_ID="987654321"
export GITHUB_APP_PRIVATE_KEY_FILE="$HOME/.secrets/flexnetos-control-plane.pem"

# Validate local env and signing only:
make github-app.smoke DRY_RUN=1

# Request one installation token and print only masked metadata:
make github-app.smoke
```

The smoke test fails closed when environment variables are missing, and never
prints the private key, JWT, installation token, or secret values.

## 4. Wire workflows only after least-privilege review

Before a workflow receives an app-derived token:

- choose the task class in [`github-app/permissions.md`](../../github-app/permissions.md);
- declare explicit workflow `permissions:`;
- avoid `pull_request_target` code checkout or execution for untrusted PRs;
- prefer same-repo or maintainer-approved gates for write-token automation;
- keep repository-administration permissions out of routine PR jobs.
