# Releasing

This repo follows **release-please** for automation and a **moving
major tag** (`v1`, `v2`, …) for downstream consumers.

## What downstream consumers pin to

Reusable workflows live at `.github/workflows/reusable-*.yml`. Callers
in other FlexNetOS repos pin to the moving major tag, which advances on
every non-breaking release:

```yaml
uses: FlexNetOS/.github/.github/workflows/reusable-lint.yml@v1
```

A specific consumer that wants exact-version pinning can use `@v1.4.2`
instead. We do not move the SHA-suffixed tags after publication.

## Cadence

Releases are cut on-demand, not on a schedule. Trigger conditions:

- A breaking change lands → bump major.
- A new feature lands (new reusable workflow, new input, new doc that
  callers should know about) → bump minor.
- A bug fix or doc clarification lands → bump patch.

Conventional commit messages drive the version bump automatically; see
[`CONTRIBUTING.md`](CONTRIBUTING.md) for the prefix list.

## The release-please loop

[`.github/workflows/release.yml`](.github/workflows/release.yml) runs
on every push to `main`. release-please opens or updates a
**"chore(main): release X.Y.Z"** PR that accumulates the next release's
changelog. The maintainer reviews the PR and merges it when ready —
that merge triggers:

1. A tagged release on GitHub (`vX.Y.Z`).
2. Release notes generated from the conventional-commit history.
3. A re-run of `release.yml` that updates the moving `v1` tag (see
   below).

## Moving the major tag

The major tag (`v1`) always points at the latest non-breaking release
within that major line. After every release-please-driven release, the
release workflow advances `v1` to the new commit:

```bash
git tag -fa v1 <release-sha> -m "track v1.x"
git push -f origin v1
```

This is the only force-push permitted in this repo. It is not allowed
on `main` and is not allowed on `vX.Y.Z` tags.

## The first release — v1.0.0

Until the reusable workflows ship real bodies (not scaffolds), there
is no v1. The path to v1:

1. Fill the bodies of `reusable-lint.yml`, `reusable-test.yml`,
   `reusable-build.yml`, `reusable-security.yml`, `reusable-release.yml`.
   (`reusable-secrets.yml` ships when the `pass` vault is initialized;
    see [`USER.TODO.md`](USER.TODO.md) §4.)
2. Run the smoke-test caller in this repo's own `ci.yml` against the
   filled workflows — green CI on `main` for at least one cycle.
3. Merge the release-please PR that proposes `v1.0.0`.
4. The workflow tags `v1.0.0` and `v1`. Downstream repos can now pin to
   `@v1`. Update this repo's README example accordingly.

## What is in scope for a release here

Only the contents of this repo: community-health files, reusable
workflows, docs, scripts, manifests. Downstream FlexNetOS repos cut
their own releases through `reusable-release.yml`.

## Security releases

Out-of-band when needed. Process is in [`SECURITY.md`](SECURITY.md):
private vulnerability report → maintainer triage → patch on `main` →
expedited release. Disclosure timing per the SLA in that document.
