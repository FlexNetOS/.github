# CI invariant promotion tracker — manifest-drift.yml

Tracks which jobs in `manifest-drift.yml` are still `REPORT_ONLY`
(`continue-on-error: true`) and why. When a job runs green on `main` for
one full cycle, remove `continue-on-error: true` and update this file.

Last updated: 2026-05-28 (SESSION-2026-05-28-006)
Reference run: [26598828751](https://github.com/FlexNetOS/.github/actions/runs/26598828751)
Branch at promotion: `feat/reconciliation-slice-tooling`

---

## Promoted to STRICT ✓

| Job | Promoted | Run |
|-----|----------|-----|
| `claude-dir-check` (No PascalCase Claude/ directories) | 2026-05-28 | 26598828751 |
| `open-questions-lint` (open-questions.md schema) | 2026-05-28 | 26598828751 |
| `claude-settings-doctor` (.claude/settings.json hygiene) | 2026-05-29 | G8 trim completed (SESSION-2026-05-29-007) |

---

## Still REPORT_ONLY

| Job | Reason | Unblock condition |
|-----|--------|-------------------|
| `check-user-todo-step5` | Intentionally informational — designed to surface progress, never block a PR. | No promotion planned. Remove `continue-on-error` only if consensus changes the job from "inform" to "gate". |
| `submodules-materialize-noop` | Placeholder — the MANIFEST→.gitmodules lockfile (`materialize`) pattern is deferred (G4/G5 in `.omc/plans/open-questions.md`). | Replace the noop with a real check once `scripts/materialize-gitmodules.sh` lands, then promote after one green cycle. |

---

## Promotion checklist (per job)

1. Job must run without failure on at least one PR cycle.
2. Remove `continue-on-error: true` from the job in `manifest-drift.yml`.
3. Move the job row to "Promoted to STRICT" above and record the date + run ID.
4. Open a PR for the change; the job name in the PR description should include "promote to STRICT".
