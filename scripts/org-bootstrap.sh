#!/usr/bin/env bash
# org-bootstrap.sh — idempotent org-level configuration for FlexNetOS.
#
# Runs the Phase 4 controls from docs/org-setup.md against a converted
# organization. Safe to re-run: every change is checked first and only
# applied if missing.
#
# Usage:
#   ./scripts/org-bootstrap.sh                  # FlexNetOS, dry-run = false
#   ORG=other-org ./scripts/org-bootstrap.sh    # different org
#   DRY_RUN=1 ./scripts/org-bootstrap.sh        # show diffs without applying
#
# Pre-requisites:
#   - gh CLI authed as an org owner (`gh auth status` shows a token with
#     `admin:org` scope).
#   - The org already exists (i.e. Phase 2 of docs/org-setup.md has
#     completed).
#
# Exit codes:
#   0  success (idempotent — all changes were already present, or were
#      applied cleanly)
#   1  pre-flight failed (auth, org missing, missing dependency)
#   2  apply failed mid-run; previous state is partial

set -euo pipefail

ORG="${ORG:-FlexNetOS}"
DRY_RUN="${DRY_RUN:-0}"

# ---------- helpers ----------

c_red='\033[0;31m'; c_yellow='\033[0;33m'; c_green='\033[0;32m'; c_blue='\033[0;34m'; c_off='\033[0m'
log()  { printf "${c_blue}[bootstrap]${c_off} %s\n" "$*"; }
ok()   { printf "${c_green}[ok]${c_off}        %s\n" "$*"; }
warn() { printf "${c_yellow}[warn]${c_off}      %s\n" "$*"; }
err()  { printf "${c_red}[err]${c_off}       %s\n" "$*" >&2; }
plan() { printf "${c_yellow}[would do]${c_off}  %s\n" "$*"; }

apply() {
  # apply "<description>" -- <gh-or-other-command>
  local desc="$1"; shift
  if [[ "$DRY_RUN" == "1" ]]; then
    plan "$desc"
    printf "            > %s\n" "$*"
    return 0
  fi
  log "applying: $desc"
  "$@"
}

# ---------- pre-flight ----------

command -v gh >/dev/null || { err "gh CLI not found"; exit 1; }
command -v jq >/dev/null || { err "jq not found";    exit 1; }

if ! gh auth status >/dev/null 2>&1; then
  err "gh not authenticated. Run: gh auth login --scopes 'admin:org,repo'"
  exit 1
fi

if ! gh api "/orgs/$ORG" >/dev/null 2>&1; then
  err "org '$ORG' not found or not an organization. Has the user→org conversion completed?"
  exit 1
fi

org_type=$(gh api "/users/$ORG" --jq .type)
if [[ "$org_type" != "Organization" ]]; then
  err "'$ORG' exists but is type '$org_type', not 'Organization'. Run Phase 2 of docs/org-setup.md first."
  exit 1
fi

ok "pre-flight: gh authed, org '$ORG' confirmed"

# ---------- 4.2 — Org ruleset for main-branch policy ----------

ruleset_name="main-branch-baseline"
existing_ruleset_id=$(gh api "/orgs/$ORG/rulesets" --jq \
  ".[] | select(.name == \"$ruleset_name\") | .id" 2>/dev/null || true)

if [[ -n "$existing_ruleset_id" ]]; then
  ok "ruleset '$ruleset_name' already present (id=$existing_ruleset_id)"
else
  ruleset_json=$(cat <<'JSON'
{
  "name": "main-branch-baseline",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/master"],
      "exclude": []
    },
    "repository_name": {
      "include": ["~ALL"],
      "exclude": [],
      "protected": true
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
JSON
)
  apply "create org ruleset '$ruleset_name'" \
    gh api -X POST "/orgs/$ORG/rulesets" --input - <<<"$ruleset_json"
fi

# ---------- 4.3 — Discussions on org and on this repo ----------

discussions_repo_enabled=$(gh api "/repos/$ORG/.github" --jq '.has_discussions // false' 2>/dev/null || echo "false")
if [[ "$discussions_repo_enabled" == "true" ]]; then
  ok "Discussions already enabled on $ORG/.github"
else
  apply "enable Discussions on $ORG/.github" \
    gh api -X PATCH "/repos/$ORG/.github" -F has_discussions=true
fi
# Org-level Discussions ("organization discussions") cannot be toggled
# via REST in 2026; the UI control at
# https://github.com/orgs/$ORG/settings/discussions
# is the canonical surface. We just note it.
warn "Org-level Discussions: enable via UI at https://github.com/orgs/$ORG/settings/discussions"

# ---------- 4.6 — Private vulnerability reporting on this repo ----------

pvr=$(gh api "/repos/$ORG/.github" --jq '.security_and_analysis.secret_scanning.status // "unknown"' 2>/dev/null || echo "unknown")
log "secret-scanning status on $ORG/.github: $pvr"
apply "enable private vulnerability reporting on $ORG/.github" \
  gh api -X PUT "/repos/$ORG/.github/private-vulnerability-reporting"

# ---------- 5.1 — Teams referenced by .github/CODEOWNERS ----------

codeowners_file="$(git rev-parse --show-toplevel 2>/dev/null)/.github/CODEOWNERS"
if [[ -r "$codeowners_file" ]]; then
  needed_teams=$(grep -oE "@$ORG/[A-Za-z0-9_-]+" "$codeowners_file" | sed "s|@$ORG/||" | sort -u || true)
  if [[ -z "$needed_teams" ]]; then
    ok "CODEOWNERS references no $ORG/* teams; nothing to create"
  else
    for team in $needed_teams; do
      if gh api "/orgs/$ORG/teams/$team" >/dev/null 2>&1; then
        ok "team '$team' already exists"
      else
        apply "create team '$team'" \
          gh api -X POST "/orgs/$ORG/teams" \
          -f "name=$team" \
          -f "privacy=closed" \
          -f "description=Auto-created by org-bootstrap.sh from CODEOWNERS"
      fi
    done
  fi
else
  warn "CODEOWNERS not found at $codeowners_file; skipping team creation"
fi

# ---------- 4.1 — Require 2FA for org members ----------
#
# This is a destructive operation: enabling it removes members without
# 2FA. We do NOT auto-apply. We surface it.
two_fa_required=$(gh api "/orgs/$ORG" --jq '.two_factor_requirement_enabled // false')
if [[ "$two_fa_required" == "true" ]]; then
  ok "2FA already required org-wide"
else
  warn "2FA is NOT required for org members."
  warn "  Verify every existing member has 2FA enabled, then run manually:"
  warn "    gh api -X PATCH /orgs/$ORG -F billing_email=<your-email> -F two_factor_requirement_enabled=true"
fi

# ---------- Summary ----------

ok "org-bootstrap done for $ORG"
log "Next manual steps (see docs/org-setup.md for full context):"
log "  4.4  Create runner group 'local' and re-register the runner at org scope."
log "  4.5  Move per-repo secrets that are actually org-wide up to /orgs/$ORG/actions/secrets."
log "  5.2  Verify https://github.com/$ORG renders profile/README.md."
log "  5.3  Update FUNDING.yml or remove the placeholders."
log "  5.4  Update MAINTAINERS.md with the personal-account owner row."
