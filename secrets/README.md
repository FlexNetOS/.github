# `secrets/` — vault and auto-injection

A `pass`-managed GPG store committed to git, with auto-injection into
both local shells (via `direnv`) and the self-hosted runner's CI jobs
(via a reusable workflow). Optional Bitwarden Secrets Manager mirror for
cases where a workflow runs on GitHub-hosted infrastructure.

## Threat model in one paragraph

The store at `store/` contains GPG-encrypted blobs. Anyone with read
access to the repo sees the encrypted bytes but not the cleartext. Only
holders of an `.gpg-id`-listed GPG key can decrypt. Two keys are
authorized: the **personal** key on the dev box, and a **runner** key on
the self-hosted runner. Each key sees a different slice of the store —
the runner key cannot decrypt anything outside `store/runner/`. Loss of
the personal key → use the age-based recovery vault under
`recovery/`. Compromise of the runner key → revoke from `.gpg-id.runner`,
rotate every secret in `store/runner/`, re-encrypt.

## Layout

```text
secrets/
├── README.md                this file
├── .gpg-id                  fingerprints of keys authorized for `store/` root + non-runner subtrees
├── .gpg-id.runner           fingerprint of the runner key (only authorized for store/runner/)
├── store/                   `pass`-managed encrypted tree (each leaf = .gpg blob)
│   ├── github/              GitHub PATs, deploy keys (NOT GHA secrets — those live in GHA)
│   ├── hf/                  Hugging Face tokens
│   ├── openai/              OpenAI API keys
│   ├── anthropic/           Anthropic API keys
│   ├── personal/            personal secrets, kept off the runner
│   └── runner/              CI-needed secrets — only key authorized: runner
├── envs/                    per-environment .env templates with `pass:<entry>` placeholders
│   ├── dev.env.tmpl
│   ├── ci.env.tmpl
│   └── prod.env.tmpl
└── recovery/                age-based emergency recovery — see recovery/README.md
    └── README.md
```

## First-time setup on a dev box

```bash
# 1. Install dependencies (Debian/Ubuntu)
sudo apt-get install -y gpg pass direnv age

# 2. Generate a personal GPG key (interactive) — or import an existing one
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG     # note the long key id

# 3. Initialize the pass store to use this repo's store/
export PASSWORD_STORE_DIR="$PWD/secrets/store"
pass init <YOUR-KEY-FINGERPRINT>

# 4. Add your fingerprint to .gpg-id (overwriting the placeholder).
#    For multi-key setups, list one fingerprint per line.

# 5. Hook direnv into your shell (one-time, in ~/.bashrc or ~/.zshrc):
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# 6. Allow the repo's .envrc (idempotent; safe to re-run after edits)
cd /path/to/my-github
direnv allow

# 7. Add a secret
pass insert openai/personal
# (paste secret, hit enter, Ctrl-D)

# 8. Verify auto-injection works
echo "$OPENAI_API_KEY"        # should print your secret
```

## First-time setup on the self-hosted runner

```bash
# 1. Generate a SEPARATE key for the runner — never reuse the personal key
sudo -u <runner-user> gpg --full-generate-key
sudo -u <runner-user> gpg --list-secret-keys --keyid-format LONG

# 2. Export the runner's public key, copy it to the dev box, import there,
#    and reencrypt the runner-scoped tree under that key:
sudo -u <runner-user> gpg --armor --export <RUNNER-KEY-FP> > runner.pub
# (transfer runner.pub to the dev box, then:)
gpg --import runner.pub
gpg --edit-key <RUNNER-KEY-FP>     # set trust to ultimate or signed

# 3. On the dev box: add the runner fingerprint to .gpg-id.runner
echo "<RUNNER-KEY-FP>" > secrets/.gpg-id.runner

# 4. Re-encrypt the runner subtree so the runner key can decrypt it:
PASSWORD_STORE_DIR="$PWD/secrets/store" pass init -p runner \
    "$(cat secrets/.gpg-id) $(cat secrets/.gpg-id.runner)"

# 5. Commit and push; runner pulls the updated store.
```

## Rotation policy

- Every secret has a **90-day** rotation cadence by default.
- `scripts/secrets-rotate.sh` lists entries whose underlying `.gpg`
  blob is older than 90 days, opens an issue, and reminds.
- After rotation: `pass edit <entry>`, commit the rebundled blob, push.
- The scheduled workflow `secrets-rotate.yml` runs weekly.

## How to add a new secret

Convention: lowercase, slash-separated, descriptive.

```bash
pass insert github/personal/cli      # personal — dev box only
pass insert runner/dockerhub          # runner-scoped — re-encrypted with runner key
pass insert anthropic/api/research    # nested namespaces are fine
```

After adding, edit the appropriate `envs/*.env.tmpl` to expose the
secret with a friendly env-var name.

## What NOT to do

- **Never** `pass insert` into `runner/*` without verifying the runner
  key is in `.gpg-id.runner` — otherwise the runner can't read it.
- **Never** copy a real cleartext secret into `envs/*.tmpl` — those
  are templates only.
- **Never** commit a decrypted `.env`. `.gitignore` blocks `.env*`
  except the `.tmpl` / `.example` patterns.
- **Never** use the same GPG key for the dev box and the runner.
  Separate keys, separate blast radius.

## Bitwarden / Vaultwarden GitHub secret sync

This is the preferred next-generation path for GitHub Actions secrets:

```text
Vaultwarden or Bitwarden vault
        │
        ▼
Bitwarden CLI (`bw`) on trusted admin machine
        │
        ▼
scripts/secrets-sync-github-from-bitwarden.sh
        │
        ▼
GitHub Actions repo / environment / org secrets
```

Why this shape:

- Vaultwarden (`github.com/dani-garcia/vaultwarden`) is a self-hosted,
  Bitwarden-compatible server. It can become the human-friendly vault UI/API.
- The official Bitwarden CLI (`bw`) can point at either Bitwarden Cloud or a
  Vaultwarden server via `bw config server`.
- GitHub receives only encrypted Actions secrets through `gh secret set`; the
  repo stores mapping metadata, never cleartext values.

First create a local mapping file:

```bash
cp secrets/github-secrets.tsv.example secrets/github-secrets.tsv
$EDITOR secrets/github-secrets.tsv
```

Then dry-run the sync:

```bash
# If using Vaultwarden instead of Bitwarden Cloud:
export BW_SERVER="https://vaultwarden.example.test"

# Unlock the Bitwarden/Vaultwarden vault for this shell:
export BW_SESSION="$(bw unlock --raw)"

make secrets.sync-github-bw DRY_RUN=1
```

Apply the sync:

```bash
make secrets.sync-github-bw
```

The mapping supports three GitHub scopes:

| scope | target format | Example |
| --- | --- | --- |
| `repo` | `OWNER/REPO` | `FlexNetOS/lifeos` |
| `env` | `OWNER/REPO:ENVIRONMENT` | `FlexNetOS/lifeos:production` |
| `org` | `ORG` | `FlexNetOS` |

Supported Bitwarden fields are `password`, `username`, `notes`, and
`field:<custom-field-name>`.

Keep `secrets/github-secrets.tsv` local/private. It contains no cleartext secret
values, but it can reveal secret names, repo names, and vault item names. The
example file is safe to commit; the real mapping is ignored by `.gitignore`.

## Bitwarden Secrets Manager mirror (optional)

`secrets-sync-github-from-bitwarden.sh` uses the normal Bitwarden/Vaultwarden
vault plus `bw` CLI to write GitHub Actions secrets.

`secrets-mirror-to-bws.sh` is different: it mirrors the legacy `pass` store into
Bitwarden Secrets Manager (`bws`). Use BWS when a workflow itself needs to fetch
secrets on GitHub-hosted infrastructure via the official Bitwarden Secrets
action. Vaultwarden compatibility should not be assumed for BWS; treat BWS as a
separate Bitwarden Secrets Manager lane.

Sync is **one-way** for both lanes: the vault is source of truth and downstream
stores are mirrors. Editing a secret in GitHub or BWS will be overwritten on the
next sync.

## Recovery

If the personal GPG key is lost, see [`recovery/README.md`](recovery/README.md).
The recovery vault uses [age](https://github.com/FiloSottile/age) with a
paper-backup of the age secret key, so you can decrypt the runner key
seed and re-establish the store.
