---
name: new-reusable-workflow
description: Scaffold a new reusable (workflow_call) GitHub Actions workflow for the FlexNetOS umbrella following the repo's conventions — documented inputs, least-privilege permissions, and report-only-first → STRICT promotion. Use when creating any .github/workflows/reusable-*.yml or a new shared CI template.
---

# new-reusable-workflow — scaffold a shared CI template

This repo ships language-agnostic `workflow_call` templates that every
downstream FlexNetOS repo consumes (`.github/workflows/reusable-*.yml`). New
ones must match the existing shape so callers stay a three-line block, not a
hundred-line copy-paste.

## Steps

1. **Name it** `reusable-<verb>.yml` (e.g. `reusable-typecheck.yml`). Copy the
   bundled `reusable-template.yml` in this skill directory as the starting point.
2. **Declare `on: workflow_call`** with explicit, documented `inputs:` (every
   input gets a `description` and `type`; mark `required:` honestly) and
   `secrets:` if needed (prefer `secrets: inherit` at the caller).
3. **Least-privilege `permissions:`** — start from `contents: read` and add only
   what the job needs (`id-token: write` for OIDC, `security-events: write` for
   code scanning, etc.). Never leave the default broad token.
4. **Pin third-party actions to a full commit SHA** (not a moving tag) for
   supply-chain safety; first-party `actions/*` may use a major tag.
5. **Report-only first.** New CI invariants land with `continue-on-error: true`
   on pull requests so they annotate without blocking. After one full green
   cycle on `main`, promote to STRICT (remove `continue-on-error` / gate the
   merge). See CONTRIBUTING "CI invariant promotion pattern".
6. **Lint locally:** `tools/bin/actionlint .github/workflows/reusable-<verb>.yml`
   (or `make verify.actionlint`). The actionlint PostToolUse hook also runs on edit.
7. **Document the caller snippet** in the workflow header comment and, if it is
   broadly useful, in `README.md`'s "How to use the reusable workflows".

## Caller shape (downstream repos)

```yaml
jobs:
  <verb>:
    uses: FlexNetOS/.github/.github/workflows/reusable-<verb>.yml@v1
    with:
      language: bun
    secrets: inherit
```

Pin to the moving major tag `@v1` once the scaffold carries a real body and a
release is cut (see `RELEASING.md`).

## Done criteria

- `actionlint` clean; `permissions:` least-privilege; third-party actions
  SHA-pinned; PR-path is report-only until one green `main` cycle; caller
  snippet documented.
