# Mission: codebase-health

**Slug:** codebase-health
**Created:** 2026-05-28
**Repo:** /home/drdave/workspace/my-github (FlexNetOS/.github umbrella)

## Objective

Continuously verify and improve the health of the FlexNetOS/.github umbrella codebase. The evaluator is `make verify` — a passing run (exit 0) with all checks clean is the health signal.

## Evaluator

```bash
cd /home/drdave/workspace/my-github
make verify 2>&1
echo "EXIT:$?"
```

Evaluator output: structured JSON with `pass: true/false`, `score` (0-100), and `findings` array.

**Pass criteria:** `make verify` exits 0 AND markdown check reports 0 errors.

## Improvement Axes (per iteration)

1. **Documentation completeness** — AGENTS.md coverage across key dirs
2. **Markdown quality** — no lint errors in new/changed docs
3. **MANIFEST accuracy** — all repos correctly catalogued
4. **CI workflow correctness** — actionlint clean

## Scope

- Root directory files (AGENTS.md, CLAUDE.md, CONTRIBUTING.md)
- `.claude/` — settings, skills, hooks
- `.github/` — workflows, templates
- `scripts/` — verification scripts
- `tools/` — pinned tool wrappers
- `data/brain-data/research/` — research dossiers
- `repos/MANIFEST.yaml` — submodule registry

## Out of Scope

- Submodule contents (each has its own repo/CLAUDE.md)
- Secrets vault (`secrets/`)
- `.omc/` autoresearch artifacts themselves
