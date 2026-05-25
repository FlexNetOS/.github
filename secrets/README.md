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

## Bitwarden Secrets Manager mirror (optional)

`scripts/secrets-mirror-to-bws.sh` walks the `pass` store and creates
corresponding secrets in BWS. Useful when a workflow runs on a
GitHub-hosted (no GPG) runner. That workflow then uses the official
[Bitwarden Action](https://github.com/marketplace/actions/bitwarden-secrets)
instead of the `pass`-based reusable workflow.

Sync is **one-way**: `pass` is the source of truth, BWS is a mirror.
Editing a secret in BWS will be overwritten on the next mirror run.

## Recovery

If the personal GPG key is lost, see [`recovery/README.md`](recovery/README.md).
The recovery vault uses [age](https://github.com/FiloSottile/age) with a
paper-backup of the age secret key, so you can decrypt the runner key
seed and re-establish the store.
