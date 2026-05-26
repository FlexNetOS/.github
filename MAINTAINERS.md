# Maintainers

This repository — and by extension the community-health defaults
inherited by every FlexNetOS repo — is maintained by:

| Role | Handle | Contact |
| --- | --- | --- |
| Primary maintainer | [@FlexNetOS](https://github.com/FlexNetOS) | See [`SECURITY.md`](SECURITY.md) for private channels |

After the user→organization conversion documented in
[`docs/org-setup.md`](docs/org-setup.md), this table will gain the
human maintainer's personal handle as the org owner.

## Responsibilities

- **Reviews and merges** on `main`. PRs require at least one approving
  review; see [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full policy.
- **Releases.** Tagging, changelog curation, and the moving `v1` tag.
  See [`RELEASING.md`](RELEASING.md).
- **Security triage.** Private vulnerability reports come through
  [`SECURITY.md`](SECURITY.md); response SLA is documented there.
- **Operational health.** The maintainer keeps the self-hosted runner
  online, rotates the GPG keys protecting `secrets/`, and watches the
  scheduled workflows (submodule bump, secrets rotate, wiki lint).

## Escalation

For anything time-sensitive that doesn't fit a GitHub channel — use the
contact in [`SECURITY.md`](SECURITY.md). That mailbox is monitored.

## Becoming a maintainer

This is a small, solo-operator umbrella today. There is no formal
contributor ladder yet. If the project grows to need additional
maintainers, this section will be revised with the criteria and the
review process. Until then: high-quality PRs are the path.
