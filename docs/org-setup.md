# Org-setup playbook

One-time conversion of `FlexNetOS` from a **GitHub user account** to a
**GitHub organization**, then standing up the org-level controls that
were not available while it was a user.

This playbook is the canonical sequence. The high-level plan that
produced it lives at `~/.claude/plans/merry-coalescing-firefly.md`
(Scope 4 + Scope 3); this file is the executable version.

> **Read before starting.** GitHub's "Transform user account →
> Organization" flow requires designating a *different, pre-existing*
> GitHub user account to become the org's new owner. The new owner's
> primary email must not conflict with any email currently on the
> account being converted. This playbook threads that needle.

The script [`../scripts/org-bootstrap.sh`](../scripts/org-bootstrap.sh)
automates the Phase 4 controls. The rest is GitHub UI work.

---

## Pre-flight checklist

Before starting:

- [ ] `gh auth status` shows you're authed as `FlexNetOS`.
- [ ] `git status` in this repo is clean — no uncommitted work that
  would be lost if branches shuffle.
- [ ] You can log in as `FlexNetOS` in your regular browser **and**
  open a second browser session (incognito / Firefox Container) for
  the new personal account. You will need both at once.
- [ ] You have access to the inbox at `revenaugh.david@gmail.com`.
- [ ] A password manager (and a paper backup) is ready to receive 2FA
  recovery codes for the new account.

---

## Phase 0 — Backup the FlexNetOS user account

Before any destructive change, snapshot everything that is user-scoped
and would be lost if mis-handled.

```bash
mkdir -p ~/_work/flexnetos-conversion-backup && cd $_

# Starred repos — orgs cannot star; export now or lose visibility
gh api /user/starred --paginate > stars.json

# Owned repos — sanity check
gh repo list FlexNetOS --limit 1000 \
  --json name,visibility,isFork,updatedAt > repos.json

# SSH keys registered under the FlexNetOS user
gh api /user/keys > ssh-keys.json

# GPG keys registered under the FlexNetOS user
gh api /user/gpg_keys > gpg-keys.json

# Verified emails on FlexNetOS
gh api /user/emails > emails.json

# GitHub Apps installed across FlexNetOS-owned repos
gh api /user/installations --paginate > app-installations.json
```

Keep this directory until well after Phase 5 verifies green.

---

## Phase 1 — Free the canonical email + create the personal account

GitHub allows each email to be the primary on only **one** account.
You cannot create a new personal account with `revenaugh.david@gmail.com`
while it is still attached to FlexNetOS. Steps:

### 1.1 Add a `+tag` alias to FlexNetOS as a new primary email

GitHub Settings → Emails (logged in as FlexNetOS):

1. **Add email** → `revenaugh.david+flexnetos@gmail.com`. Gmail delivers
   `+tag` mail to the same inbox; GitHub treats it as a distinct
   address.
2. Click the verification link in Gmail.
3. **Set the `+flexnetos` address as primary.**
4. **Remove** `revenaugh.david@gmail.com` from the FlexNetOS user.

The bare email is now free.

### 1.2 Create the new personal account

`https://github.com/signup` — **in a private/incognito window** so the
FlexNetOS session stays signed in elsewhere:

- **Username**: `david-revenaugh` (recommended — verified available
  via `gh api /users/david-revenaugh` returning 404).
  - Alternatives if you prefer: `davidrevenaugh`, `revenaugh`,
    `revenaugh-david`, `davidrdave`. All verified available.
  - `DrDave`, `drdave`, `dr-dave` are **taken** by other GitHub users.
    Use the alias as display name and bio instead.
- **Email**: `revenaugh.david@gmail.com` (now free).
- Strong password, **enable 2FA immediately** (TOTP via authenticator
  app, save recovery codes to password manager + fireproof backup).
- Verify the email link.
- Set display name to "David Revenaugh" and bio to mention "DrDave" if
  desired.

---

## Phase 2 — Convert FlexNetOS user → organization

Logged in as `FlexNetOS` in your regular browser, navigate to
**Settings → Account → "Transform account" → "Transform into an
organization"**, then:

- Plan: **Free**.
- New owner: **`david-revenaugh`** (or whichever personal username you
  picked in Phase 1.2).
- Confirm.

GitHub does the swap atomically. Repo URLs do **not** change. The
`FlexNetOS` handle now resolves to an organization page owned by the
personal account.

### 2.1 Verify on GitHub

- `https://github.com/FlexNetOS` renders the org profile (now sourced
  from [`../profile/README.md`](../profile/README.md)).
- `https://github.com/david-revenaugh` renders the new personal profile.
- The personal account appears under FlexNetOS → People as an **Owner**.

### 2.2 Make membership public (optional but recommended)

People → row for `david-revenaugh` → **Set public**. This surfaces the
relationship on both profiles.

---

## Phase 3 — Re-attach identity on the personal account

### 3.1 SSH keys

Settings → SSH and GPG keys on the **personal** account. Add the same
public keys from `~/_work/flexnetos-conversion-backup/ssh-keys.json`.
The org doesn't hold per-user SSH keys; the personal account does.

### 3.2 GPG keys

Same Settings page → GPG keys. Add the same public keys from
`gpg-keys.json`. The GPG key's identity email is
`revenaugh.david@gmail.com`, which is now verified on the personal
account — so historical FlexNetOS commits signed with that key still
verify on GitHub.

### 3.3 Re-auth `gh` CLI on this dev box

```bash
gh auth status                                  # see current logins
gh auth login --hostname github.com --git-protocol https --web
# Sign in as david-revenaugh in the browser flow
gh auth switch --user david-revenaugh           # default to personal
```

If you want `gh` to also remember the org context for FlexNetOS-scoped
operations, leave the FlexNetOS login in place (`gh auth status` will
list both).

### 3.4 Re-import stars (optional)

From the personal account:

```bash
gh auth switch --user david-revenaugh
jq -r '.[].full_name' ~/_work/flexnetos-conversion-backup/stars.json \
  | while read repo; do gh api -X PUT "/user/starred/$repo"; done
```

### 3.5 Update local git identity

`~/.gitconfig` `[user]` block should match the personal handle for new
commits authored on this box:

```ini
[user]
  name = David Revenaugh
  email = revenaugh.david@gmail.com
  signingkey = <gpg-fingerprint>
[commit]
  gpgsign = true
```

---

## Phase 4 — Org-level configuration

Most of these can be applied by running
[`../scripts/org-bootstrap.sh`](../scripts/org-bootstrap.sh) — it is
idempotent and prints exactly what it changed. Manual UI alternatives
below for the steps the script cannot drive.

### 4.1 Require 2FA for all members

Org Settings → Authentication security → **Require two-factor
authentication for everyone in the … organization**.

(This kicks out members who don't have 2FA enabled. Today the only
member is the personal account — verify it has 2FA before flipping
this.)

### 4.2 Branch protection via org rulesets

Rulesets are the modern, inheritable replacement for per-repo branch
protection. One org-level ruleset covers `main` across every FlexNetOS
repo:

- Target: All repositories owned by `FlexNetOS`, branches matching
  `main` (and `master` if any legacy repos still use it).
- Rules:
  - Require pull request, **1** approval, dismiss stale approvals on
    new pushes.
  - Require linear history.
  - Block force pushes.
  - Block deletions.
  - Require status checks (add the names of the reusable lint/test/
    security workflows once they have real bodies in their callers).

`org-bootstrap.sh` applies a baseline ruleset; tighten via the UI once
the required-checks list stabilizes.

### 4.3 Enable Discussions

Org Settings → Features → **Discussions** (org-level) → enable.

Then per-repo where appropriate (this repo, `ruvector`, `weftos`):
Settings → Features → **Discussions**.

[`../SUPPORT.md`](../SUPPORT.md) points readers at Discussions for Q&A.

### 4.4 Runner groups

Settings → Actions → Runner groups → **New group: `local`**. Restrict
to the allowlist documented in
[`../runner/policies/runner-group.md`](../runner/policies/runner-group.md).

Then re-register the existing runner at org scope (it is currently
registered to `FlexNetOS/weftos` only). On the runner host:

```bash
cd /home/drdave/_work/repos/actions-runner
# De-register from weftos using the removal token from
# github.com/FlexNetOS/weftos → Settings → Actions → Runners → ⋯ → Remove
./config.sh remove --token <REMOVAL-TOKEN>

# Then re-register at org scope using a token from
# github.com/organizations/FlexNetOS/settings/actions/runners → New
cd /home/drdave/_work/repos/my-github
runner/register.sh --org --token <ORG-REGISTRATION-TOKEN> \
  --name local-gh-rnr-lnx --labels self-hosted,linux,x64,local
```

Verify with `make runner.status` from this repo's root.

### 4.5 Org secrets and variables

Settings → Secrets and variables → Actions. Move any per-repo secrets
that are actually org-wide (shared registry tokens, release-please app
tokens) up to **organization-level secrets**, scoped to the appropriate
runner group or repo allowlist.

Keep truly repo-scoped secrets in their repos. The org level is for
things three or more repos all consume.

### 4.6 Private vulnerability reporting

For each public repo (start with this one):

Settings → Security → **Private vulnerability reporting** → Enable.

Makes the SLA in [`../SECURITY.md`](../SECURITY.md) concrete.

---

## Phase 5 — Audit & polish

### 5.1 CODEOWNERS

[`../.github/CODEOWNERS`](../.github/CODEOWNERS) currently references
`@FlexNetOS/*` team handles that did not exist while FlexNetOS was a
user account. Now that teams *can* exist:

```bash
# List current teams (none exist by default after conversion)
gh api /orgs/FlexNetOS/teams

# Create the teams referenced by CODEOWNERS — adjust to match the file
gh api -X POST /orgs/FlexNetOS/teams -f name='core' -f privacy='closed'
gh api -X POST /orgs/FlexNetOS/teams -f name='infra' -f privacy='closed'
# ... etc

# Add personal account to each team as a maintainer
for t in core infra; do
  gh api -X PUT "/orgs/FlexNetOS/teams/$t/memberships/david-revenaugh" \
    -f role='maintainer'
done
```

Then `cat .github/CODEOWNERS` and confirm every `@FlexNetOS/<team>` in
the file maps to a team that now exists. Adjust the file or the teams.

### 5.2 Org profile

`https://github.com/FlexNetOS` should now render
[`../profile/README.md`](../profile/README.md) at the top of the org
landing page. Verify visually.

### 5.3 FUNDING.yml

[`../FUNDING.yml`](../FUNDING.yml) currently has template placeholders.
Decide:

- **Sponsorships → personal account**: The human gets sponsored, not
  the org. Apply to GitHub Sponsors as a user.
- **Sponsorships → org**: Apply to GitHub Sponsors for organizations
  (separate onboarding from user sponsorship).
- **No sponsorships**: Delete `FUNDING.yml`.

Update the file accordingly.

### 5.4 MAINTAINERS.md

[`../MAINTAINERS.md`](../MAINTAINERS.md) has a placeholder row for the
post-conversion personal-account maintainer. Add it:

```markdown
| Owner | [@david-revenaugh](https://github.com/david-revenaugh) | revenaugh.david@gmail.com |
```

### 5.5 profile/README.md

Optionally add a line under "Contact" linking to `@david-revenaugh` as
the human behind the org.

---

## Verification

Run these after every phase that touches the org:

```bash
# Org exists and is an Organization
gh api /users/FlexNetOS --jq .type    # → "Organization"

# Personal account exists and is a User
gh api /users/david-revenaugh --jq .type   # → "User"

# Personal account is a member of FlexNetOS
gh api /orgs/FlexNetOS/members --jq '.[].login' | grep -x david-revenaugh

# Personal account is an owner (admin)
gh api /orgs/FlexNetOS/memberships/david-revenaugh --jq .role
# → "admin"

# Org-level rulesets exist
gh api /orgs/FlexNetOS/rulesets --jq '.[].name'

# Runner is at org scope
gh api /orgs/FlexNetOS/actions/runners --jq '.runners[].name'

# Community-standards score on this repo
gh api /repos/FlexNetOS/.github/community/profile --jq .health_percentage
# → 100
```

A test commit signed with the GPG key, pushed through a PR, should
still display "Verified" on github.com.

---

## Rollback

The user → org conversion is **not reversible** via UI. If something
goes catastrophically wrong:

- Repo URLs do not change. Backups in `~/_work/flexnetos-conversion-backup`
  are sufficient to restore stars and re-register keys on whatever
  account ends up holding the FlexNetOS identity.
- If you need to undo the conversion entirely, GitHub Support can
  sometimes assist but does not advertise this as a self-service
  feature. Plan to not need rollback.

The personal account can be deleted at any time (Settings → Account →
Delete account). The org cannot easily inherit the personal account's
historical activity.

---

## See also

- [`../VISION.md`](../VISION.md) — what the umbrella is and why
- [`../USER.TODO.md`](../USER.TODO.md) — the broader one-time human
  action list (this playbook covers `USER.TODO.md` §3, plus the
  personal-account split that wasn't in the original USER.TODO)
- [`../scripts/org-bootstrap.sh`](../scripts/org-bootstrap.sh) — the
  helper that automates Phase 4
- [`../runner/policies/runner-group.md`](../runner/policies/runner-group.md)
  — the allowlist for the runner group created in §4.4
