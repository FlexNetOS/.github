# Docs

Operational documentation that applies across FlexNetOS repositories.
Per-project docs live in each project's own `docs/`, not here.

| Doc | What it answers |
| --- | --- |
| [`fork-workflow.md`](fork-workflow.md) | How to carry local patches on a third-party repo while staying current with upstream releases. The fork-and-track pattern, upstream syncing, release-tag sync, and conflict-resolution conventions. |
| [`directory-layout.md`](directory-layout.md) | Where forks, read-only clones, and first-party projects live on disk. The `repos/{owned,forked,external}/` convention and how it maps to [`../repos/MANIFEST.yaml`](../repos/MANIFEST.yaml). |
| [`self-hosted-runner.md`](self-hosted-runner.md) | Self-hosted runner safety, untrusted-PR risk, label discipline, and the ephemeral-runner migration path. Required reading before touching anything in [`../runner/`](../runner/). |
| [`automation.md`](automation.md) | The scheduled workflows (submodule bump, secrets rotate, wiki lint) and how their outputs flow back to the maintainer. |
| [`hermetic-toolchain.md`](hermetic-toolchain.md) | The fresh-OS/zip-extract toolchain doctrine, current Phase 1 conversion, and remaining non-hermetic dependency debt. |
| [`lifeos-system-architecture.md`](lifeos-system-architecture.md) | Locks the LifeOS-as-frontend decision: LifeOS is a separate product repo that consumes shared FlexNetOS toolchains instead of owning system-wide dependencies. |
| [`org-setup.md`](org-setup.md) | One-time playbook for the user→organization conversion: org rulesets, Discussions, runner groups, org secrets, CODEOWNERS audit, private vulnerability reporting. Runs after the maintainer flips `FlexNetOS` from user account to org. |

## When to add a doc here

A doc belongs here when **all** of these are true:

1. It documents a convention or decision that applies across multiple
   FlexNetOS repos, not a single project's internals.
2. It would otherwise be re-derived by every contributor or every agent
   that hits the same question.
3. It's stable enough that the cost of maintaining it is lower than the
   cost of re-deriving it.

If a doc is project-specific, it lives in that project's `docs/`. If a
doc is research / knowledge that compounds across queries, it belongs
in [`../wiki/`](../wiki/), not here.

## See also

- [`../VISION.md`](../VISION.md) — the six roles this repo plays
- [`../README.md`](../README.md) — usage and inheritance mechanics
- [`../wiki/purpose.md`](../wiki/purpose.md) — what the wiki is for
  (the distinction between docs and wiki content)
