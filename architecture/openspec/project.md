# Project — FlexNetOS .github umbrella (OpenSpec context)

This is the umbrella-level OpenSpec instance for `FlexNetOS/.github`. It governs
**cross-cutting / org-level** capabilities. Subsystem-specific specs live in the
relevant submodule's own `architecture/openspec/` (e.g. the local `lifeos/openspec/`).

## What this repo is

The org's special `.github` mega-repo: community-health fallback, mount point for
~24 submodules under `repos/{owned,forked,external}/`, the Karpathy LLM-wiki, a
`pass`+GPG secrets vault, self-hosted runner config, and reusable CI templates.
Nothing is "built" here — it is operational config, scripts, and docs.

## Conventions OpenSpec artifacts must respect

- Conventional Commits; one feature branch per session; `main` is protected.
- `make verify` is the local pre-PR gate; CI mirrors it.
- All tracked `architecture/**/*.md` is markdown-linted — every code fence must be
  language-tagged and closed.
- Changes are additive by default: do not relocate existing `docs/` files or modify
  `lifeos/openspec/`.

## Artifact routing

| Stage | Skill | Home |
|---|---|---|
| PRD | `ecc:plan-prd` / `ecc:prp-prd` | `architecture/prd/` |
| ADR | `ecc:architecture-decision-records` | `architecture/adr/` |
| Spec | `ccg:spec-*` (this engine) | `architecture/openspec/` |
| Plan | `writing-plans` / `oh-my-claudecode:plan` | `architecture/plan/` |

## Running OpenSpec

Run `openspec` / `opsx` from the `architecture/` directory so the CLI resolves
this `openspec/` tree:

```bash
cd architecture
npx @fission-ai/openspec list
```
