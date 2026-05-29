<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-28 -->

# .github/

## Purpose
GitHub community health files and CI/CD workflows for the FlexNetOS org. Files at this level serve as org-wide defaults inherited by all FlexNetOS repos that don't ship their own.

## Key Files

| File | Description |
|------|-------------|
| `CODEOWNERS` | Code ownership rules for this repo |
| `PULL_REQUEST_TEMPLATE.md` | Default PR description template |
| `actionlint.yaml` | actionlint configuration (ignores advisory rules) |
| `dependabot.yml` | Dependabot version update config |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `workflows/` | GitHub Actions CI/CD workflows (reusable + repo-specific) |
| `ISSUE_TEMPLATE/` | Issue templates inherited by all FlexNetOS repos |

## For AI Agents

### Working In This Directory
- Workflow changes trigger `make verify.actionlint` automatically via pre-commit
- All `workflow_call` reusable workflows must be in `workflows/reusable-*.yml`
- CI invariant: new checks land with `continue-on-error: true` first, then promote to strict after one green cycle on `main`
- Never pin `actions/checkout` to SHA without updating the `actionlint.yaml` allowlist

### Testing Requirements
- `make verify.actionlint` must exit 0 after any workflow change
- Run `tools/bin/actionlint .github/workflows/<file>.yml` for individual file checks

### Common Patterns
- Reusable workflows use `workflow_call` trigger
- Job names follow `kebab-case` convention
- Secrets passed via `secrets: inherit` in callers
