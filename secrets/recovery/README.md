# Recovery vault

If the personal GPG key is lost, this directory is how you get back in.

## Mechanism

The recovery vault uses [age](https://github.com/FiloSottile/age) instead
of GPG. age is simpler (single key file, no agent, no keyring), and the
recovery flow only needs to decrypt the seed material that rebuilds the
runner key — the personal key gets regenerated from scratch.

## Setup (do this once, while the personal GPG key still works)

```bash
# 1. Generate an age keypair
age-keygen -o ~/age-recovery.key
# Public key shown on stderr; paste it into recovery/.age-recipient
cat ~/age-recovery.key | grep '^# public key:' | awk '{print $4}' > secrets/recovery/.age-recipient

# 2. PAPER-BACKUP the private key. The whole point of recovery is that
#    the digital key is also lost. Print and store in a fireproof safe:
cat ~/age-recovery.key
# (Print this output. Yes, on paper.)

# 3. Encrypt the runner GPG key seed and other recovery material:
gpg --export-secret-keys <RUNNER-KEY-FP> | \
  age -r "$(cat secrets/recovery/.age-recipient)" -o secrets/recovery/runner-gpg-seed.age

# 4. Commit. Push.
```

## Recovery flow (if you've lost the personal GPG key)

```bash
# 1. Type the paper-backed age key into ~/age-recovery.key

# 2. Decrypt the runner key seed
age -d -i ~/age-recovery.key secrets/recovery/runner-gpg-seed.age | gpg --import
# (You now have the runner key. Use it to read store/runner/ entries.)

# 3. Re-key the rest of the store: generate a new personal GPG key,
#    add its fingerprint to .gpg-id, then re-init the store:
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
echo "<NEW-PERSONAL-KEY-FP>" > secrets/.gpg-id
PASSWORD_STORE_DIR="$PWD/secrets/store" pass init -p / \
  "$(cat secrets/.gpg-id) $(cat secrets/.gpg-id.runner)"

# 4. Commit the re-encrypted blobs.

# 5. ROTATE every secret in the store anyway — assume the lost key
#    could be compromised.
```

## What's stored here

- `.age-recipient` — your age public key (safe to commit).
- `runner-gpg-seed.age` — age-encrypted GPG seed for the runner key
  (safe to commit; decrypts only with the paper-backed age key).
- Any other emergency material — encrypted to the age recipient.

## What's NOT stored here

- The age **secret** key — that's the paper backup. If you commit it,
  recovery becomes meaningless.
- Personal secrets — regenerate those after recovery.
