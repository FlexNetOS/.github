# User TODO — actions only you can do

These are the steps that require the human, not the agent. They unlock the
rest of the umbrella's automation. Items are ordered so each one's
prerequisites are above it.

The plan that produced this list lives at
`~/.claude/plans/help-me-create-a-lucky-flurry.md`.
The committed scaffold is at HEAD = `feat: scaffold FlexNetOS .github mega-umbrella`.

---

## 1. Push the initial scaffold

**Why:** The branch has 5 local commits ahead of `origin/main`; none of the
inheritance / CI behavior activates until they land on GitHub.

```bash
cd /home/drdave/_work/repos/my-github
git push origin main
```

If push is rejected because the remote was created with a different default
branch:

```bash
git fetch origin
git push -u origin main:main
```

**Verify after push:** the repo's *Insights → Community Standards* page on
GitHub shows green checks for SECURITY, CONTRIBUTING, CODE_OF_CONDUCT,
SUPPORT, License, Issue templates, PR template.

---

## 2. Set branch protection on `main`

**Why:** `CONTRIBUTING.md` already documents the rule (PR + 1 approval,
linear history, no force-push). Branch protection is the *enforcement*.

GitHub UI: **Settings → Branches → Branch protection rules → Add rule**

- Branch name pattern: `main`
- Require a pull request before merging — Yes
  - Require approvals: **1**
  - Dismiss stale approvals when new commits are pushed: **Yes**
- Require linear history: **Yes**
- Allow force pushes: **No**
- Allow deletions: **No**
- Require status checks to pass before merging: (enable after CI runs
  green at least once — pick `lint`, `manifest-validate`, `actionlint`,
  `markdownlint`, `security`)

---

## 3. Convert `FlexNetOS` user account → GitHub Organization

**Why:** This is the only natively-supported way to have one self-hosted
runner serve many repos, use org-level secrets/variables, and use runner
groups with allowlists. Free. Preserves all repo URLs and stars.

**Important:** GitHub deprecated the direct "Transform account into
organization" option on January 12, 2026. The new process requires
renaming your personal account first, then creating an organization with
the original username, and finally moving repositories.

### Step 1 — Rename the personal account

1. Go to https://github.com/settings/admin (while logged in as `FlexNetOS`)
2. Under **Change username**, pick a new name (e.g., `drdave-flexnetos`)
3. Confirm the rename. This frees up `FlexNetOS` as an organization name.

> **Note:** Your existing `gh` CLI auth and repo URLs will follow the
> rename. The `.github` repo temporarily lives at the new username until
> you move it in Step 3.

### Step 2 — Create the `FlexNetOS` organization

1. Go to https://github.com/account/organizations/new?plan=free
2. Organization name: `FlexNetOS`
3. Choose the **Free** plan.
4. Complete setup.

### Step 3 — Move repositories to the organization

1. Go to https://github.com/settings/organizations
2. Under **Move to an organization**, click **Move work to an organization**
3. Select all repositories you want to transfer (at minimum, include `.github`)
4. Target organization: `FlexNetOS`
5. Confirm the move.

### Step 4 — Update local tooling

```bash
# Re-authenticate gh CLI if token is stale after the rename
gh auth status
# If needed:
# gh auth login

# Update the origin remote if it still points at the old username
cd /home/drdave/_work/repos/my-github
git remote set-url origin https://github.com/FlexNetOS/.github.git
git remote -v  # verify
```

**Verify after:**

- `gh api orgs/FlexNetOS` returns `200 OK` (not `404`)
- Repository URLs `https://github.com/FlexNetOS/<repo>` still resolve
- You can see the `FlexNetOS` org in the GitHub UI with your repos inside it

---

## 4. Generate GPG keys for the `pass` secrets vault

**Why:** Until real key fingerprints replace the `PLACEHOLDER-NO-KEY-CONFIGURED`
markers in `secrets/.gpg-id` and `secrets/.gpg-id.runner`, the secrets
vault won't decrypt anything.

### Personal key (dev box)

```bash
gpg --full-generate-key
# Choose: RSA and RSA (default), 4096 bits, no expiration (or 2y if you prefer),
# real name: David Revenaugh, email: revenaugh.david@gmail.com,
# passphrase: strong, stored in a password manager.

gpg --list-secret-keys --keyid-format LONG
# Note the long key fingerprint — the 40-char string under `sec`.

echo "<40-CHAR-FINGERPRINT>" > /home/drdave/_work/repos/my-github/secrets/.gpg-id
```

### Runner key (separate — never reuse the personal one)

Generate this **on the runner host** (which is the same machine in your
case, but conceptually it's a separate identity).

```bash
gpg --full-generate-key
# Use a runner-specific identity, e.g. name: "FlexNetOS runner",
# email: noreply+runner@flexnetos.local

gpg --list-secret-keys --keyid-format LONG
# Note the runner fingerprint.

echo "<RUNNER-40-CHAR-FINGERPRINT>" >> /home/drdave/_work/repos/my-github/secrets/.gpg-id.runner
```

### Initialize the pass store under both keys

```bash
cd /home/drdave/_work/repos/my-github
export PASSWORD_STORE_DIR="$PWD/secrets/store"
pass init "$(cat secrets/.gpg-id)"
pass init -p runner "$(cat secrets/.gpg-id) $(cat secrets/.gpg-id.runner)"
# The -p variant re-encrypts only the runner/ subtree under both keys.
```

### Add at least one secret so direnv has something to inject

```bash
pass insert github/personal/cli       # paste your gh token, Ctrl-D
pass insert openai/personal           # paste OpenAI key, Ctrl-D
direnv allow .
echo "$GITHUB_TOKEN"                  # should print your gh token
```

### Set up paper-backed age recovery (do this once, soon)

Follow `secrets/recovery/README.md`. Generate age key, encrypt the runner
GPG seed to it, **print the age private key on paper** and store in a
fireproof safe. This is what gets you back in if the personal GPG key
is ever lost.

---

## 5. D6 — Fork the four dirty third-party repos into FlexNetOS

**Why:** Four sibling repos have local diffs against a third-party
upstream that would be lost on `git pull`. They must become FlexNetOS
forks before they can be submoduled. After fork, you push the local diffs
as commits.

```bash
# After step 3 (FlexNetOS is now an organization)
gh repo fork coleam00/Archon                 --org FlexNetOS --clone=false
gh repo fork affaan-m/everything-claude-code --org FlexNetOS --clone=false
gh repo fork yeachan-heo/oh-my-claudecode    --org FlexNetOS --clone=false
gh repo fork can1357/oh-my-pi                --org FlexNetOS --clone=false
```

### Then push your local dirty work to each fork

```bash
# Repeat for each of the four — example for everything-claude-code (32 dirty files):
cd /home/drdave/_work/repos/everything-claude-code

# Point origin at the new FlexNetOS fork; keep upstream pointing where it was.
git remote rename origin upstream 2>/dev/null || true
git remote add origin https://github.com/FlexNetOS/everything-claude-code.git
git remote -v   # verify

# Commit your local changes
git add -A
git commit -m "feat: FlexNetOS local customizations"   # write a real message

# Push to the fork
git push -u origin main
```

For `Archon` use `-b dev`. Match each repo's tracked branch from
`repos/MANIFEST.yaml`.

---

## 6. Push `personal-config` to a private FlexNetOS repo

**Why:** `personal-config/` is your chezmoi-managed dotfiles. It has no
remote. The MANIFEST has it queued at `repos/owned/personal-config` but
the submodule add will 404 until the remote exists.

```bash
cd /home/drdave/_work/repos/personal-config
gh repo create FlexNetOS/personal-config --private --source=. --remote=origin --push
```

If you want it staying user-owned (separate from FlexNetOS), edit
`repos/MANIFEST.yaml` to remove the `personal-config` entry or change the
URL — push wherever the remote ends up.

---

## 7. Run `make submodules.add` to register every manifest entry

**Why:** This is where the submodule tree actually populates on disk.
Idempotent — safe to re-run after fixing 404s.

```bash
cd /home/drdave/_work/repos/my-github

# Install yq if not already
command -v yq >/dev/null 2>&1 || sudo wget -qO /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  && sudo chmod +x /usr/local/bin/yq

# Dry-run first to see what it would do
make submodules.add  # invokes scripts/submodule-add-all.sh
# (the script prints `RUN:` lines; if anything 404s, fix and re-run)

# Stage and commit the resulting .gitmodules + submodule pointers
git status
git add .gitmodules repos/
git commit -m "feat(submodules): register MANIFEST entries"
git push
```

Expect this to take **5–15 minutes** depending on network; the script
uses `--depth=1` so clones are shallow.

---

## 8. Re-register the self-hosted runner at org scope + install service

**Why:** Currently the runner is registered to `FlexNetOS/weftos` only
and is not installed as a systemd service. Once #3 (org conversion) is
done, point it at the org so it can serve any repo via runner-group
allowlist.

```bash
# 1. De-register from weftos (token from: github.com/FlexNetOS/weftos → Settings → Actions → Runners → … → Remove)
cd /home/drdave/_work/repos/actions-runner
./config.sh remove --token <REMOVAL-TOKEN-FROM-WEFTOS-REPO-SETTINGS>

# 2. Generate an org-level registration token
#    (github.com/organizations/FlexNetOS/settings/actions/runners → New self-hosted runner)
ORG_TOKEN=<paste-here>

# 3. Re-register at org scope
cd /home/drdave/_work/repos/my-github
make runner.register MODE=org   # interactive — paste $ORG_TOKEN when prompted
# OR run runner/register.sh directly:
# runner/register.sh --org --token "$ORG_TOKEN" --name local-gh-rnr-lnx \
#   --labels self-hosted,linux,x64,local

# 4. Install systemd service (register.sh does this automatically unless --no-service)
make runner.status   # verify it's running
```

Then in GitHub UI: **Organization Settings → Actions → Runner groups →
New group `local`**, restrict to the allowlist from
`runner/policies/runner-group.md`.

---

## 9. First end-to-end smoke test

**Why:** Prove the loop works before relying on it.

```bash
cd /home/drdave/_work/repos/my-github

# Verify local toolchain + scaffold one more time
make verify

# Open a trivial PR (e.g. touch a doc) to confirm CI runs and uses the
# self-hosted runner where requested.
git checkout -b chore/smoke-test
echo "" >> README.md
git commit -am "chore: smoke-test CI"
git push -u origin chore/smoke-test
gh pr create --title "chore: smoke-test CI" --body "Smoke testing the reusable workflows"
```

Watch the Actions tab:

- `ci.yml` runs lint + manifest-validate + actionlint + markdownlint + security
- `dependency-review.yml` runs the dep CVE check
- The self-hosted runner shows up in the job logs for any `runs-on: [self-hosted, ...]` step

Once green, merge and delete the branch. The next push to `main` will
trigger `release.yml` → release-please opens an initial release PR.

---

## 10. Cut `v1.0.0` once the smoke test passes

**Why:** Downstream consumers (the FlexNetOS world) should pin to
`uses: FlexNetOS/.github/.github/workflows/reusable-lint.yml@v1`, not
`@main`. That requires a real tag.

The release-please PR opened by step 9 does most of this. Merge it; the
workflow tags `v1.0.0` and creates the GitHub Release automatically.

After tagging, update the README's calling pattern from `@main` to `@v1`
and merge.

---

## Maintenance cadence (after everything above is done)

These run automatically — no human action unless they alert:

| Cadence | Workflow | What you do |
| --- | --- | --- |
| Monday 14:00 UTC | `submodule-bump.yml` | Review the auto-PR, merge if CI green |
| Monday 14:30 UTC | `secrets-rotate.yml` | If issue opened, `pass edit <entry>`, commit, push |
| Nightly 11:00 UTC | `wiki-lint.yml` | If issue opened, ingest the missing source or fix the broken link |
| Every PR | `dependency-review.yml` | Block on `high` severity CVEs; bump or vendor differently |

---

## When you get stuck

- **gh CLI auth issues:** `gh auth status`, then `gh auth login` if needed.
- **GPG agent not running:** `gpg-connect-agent reloadagent /bye`.
- **direnv not auto-loading:** ensure `eval "$(direnv hook bash)"` is in `~/.bashrc`,
  then `direnv allow .` in the repo.
- **Submodule 404:** the entry's `url` in MANIFEST.yaml points at a repo that
  doesn't exist yet. Either fork-then-push (steps 5, 6) or edit the URL.
- **Runner not picking up jobs:** check `sudo systemctl status 'actions.runner.*'`
  and the workflow's `runs-on:` matches every label the runner advertises
  (all four: `self-hosted, linux, x64, local`).
