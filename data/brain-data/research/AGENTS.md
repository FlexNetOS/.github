<!-- Parent: ../../../AGENTS.md -->
<!-- Generated: 2026-05-28 -->

# data/brain-data/research/

## Purpose
Research dossiers for every upstream repo considered for adoption into the FlexNetOS umbrella. Each `<name>.md` dossier documents identity, purpose, stack, license, adoption plan, and open decisions. Dossiers must exist **before** any `gh repo fork` is run.

## Key Files

| File | Description |
|------|-------------|
| `repomix.md` | Dossier for repomix (vendored as `tools/repomix/`, not submoduled) |
| `n8n.md` | Dossier for n8n workflow automation (already forked to FlexNetOS/n8n; develop branch pending) |
| `paperclip.md` | Dossier for paperclip (pending adoption) |
| `fabro.md` | Dossier for fabro (pending adoption) |
| `ai-top-utility.md` | Dossier for ai-top GPU utility |
| `my-github-reconciliation.md` | Cross-repo reconciliation map |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `<name>/` | Per-repo repomix pack artifacts (repomix-summary.md + gitignored XML packs) |

## For AI Agents

### Working In This Directory
- NEVER create a dossier with placeholder TODOs — fill all 12 sections before committing
- Dossier sections: 1.Identity, 2.Purpose, 3.Stack, 4.License, 5.FlexNetOS intent, 6.Pre-adoption audit, 7.Adoption plan, 8.Sync risk, 9.Verification, 10.Open decisions, 11.Decision log, 12.Discrepancies
- §12 Discrepancies is MANDATORY — even if "None found"
- Pack XML files go in `<name>/` subdirs and are gitignored (see `<name>/.gitignore`)
- Run `make research.pack URL=<owner/repo>` to generate packs — do NOT run repomix manually

### Testing Requirements
- No TODOs left in any committed dossier
- `make verify.manifest` must still pass after any MANIFEST.yaml changes made alongside dossier work

### Common Patterns
- Dossier filename = lowercase repo name (`n8n.md`, not `N8n.md`)
- §10 Open decisions gate forks: "DO NOT FORK UNTIL..." header until all decisions resolved
- §11 Decision log: table with Date, Decision, Notes columns
