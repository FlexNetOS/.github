# =============================================================================
# FlexNetOS/.github  —  Makefile (one-command verbs)
# =============================================================================
# All real work lives in scripts/. This file is the discoverable, typo-tolerant
# surface humans (and CI) talk to. `make help` lists everything.
# =============================================================================

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help

# ---------- Discoverable targets ----------

.PHONY: help
help: ## List all targets with their one-liner description
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	      /^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
	      $(MAKEFILE_LIST) | sort

# ---------- Bootstrap & verify ----------

.PHONY: bootstrap
bootstrap: ## Idempotent setup: tools check, submodules init, secrets unlock
	@scripts/bootstrap.sh

.PHONY: verify
verify: verify.tool-assets verify.actionlint verify.markdown verify.manifest verify.tools verify.hermetic ## Run every local verification

.PHONY: verify.actionlint
verify.actionlint: ## Lint .github/workflows/*.yml
	@tools/bin/actionlint .github/workflows/*.yml

.PHONY: verify.tool-assets
verify.tool-assets: ## Validate pinned repo-local tool asset manifest
	@python3 scripts/toolchain.py validate

.PHONY: verify.markdown
verify.markdown: ## Lint all markdown except submodules/raw
	@python3 scripts/verify-markdown.py .

.PHONY: verify.manifest
verify.manifest: ## Validate repos/MANIFEST.yaml structure
	@python3 scripts/verify-manifest.py repos/MANIFEST.yaml

.PHONY: verify.tools
verify.tools: ## Validate tools/MANIFEST.yaml structure
	@python3 scripts/verify-manifest.py tools/MANIFEST.yaml

.PHONY: verify.hermetic
verify.hermetic: ## Report non-hermetic workflow/script dependencies (advisory)
	@python3 scripts/hermetic-audit.py .

# ---------- Submodules ----------

.PHONY: submodules.init
submodules.init: ## Initialize and update every submodule (depth-1)
	git submodule update --init --recursive --depth 1

.PHONY: submodules.add
submodules.add: ## Add any MANIFEST entry missing from .gitmodules (idempotent)
	@scripts/submodule-add-all.sh

.PHONY: submodules.bump
submodules.bump: ## Fast-forward submodules to tracking-branch HEAD (filter: GROUP=, NAME=)
	@args=""; \
	if [ -n "$$GROUP" ]; then args="$$args --group $$GROUP"; fi; \
	if [ -n "$$NAME" ];  then args="$$args --name $$NAME"; fi; \
	scripts/submodule-bump.sh $$args

.PHONY: submodules.sync-upstream
submodules.sync-upstream: ## For forked/, fetch upstream and merge (filter: NAME=)
	@if [ -n "$$NAME" ]; then \
	    scripts/submodule-sync-upstream.sh --name $$NAME; \
	else \
	    scripts/submodule-sync-upstream.sh; \
	fi

.PHONY: submodules.status
submodules.status: ## Report dirty / ahead-of-tracking / detached submodules
	@git submodule foreach --quiet 'echo "--- $$name ---"; git -C "$$toplevel/$$path" status --short --branch | head -5'

# ---------- Wiki ----------

.PHONY: wiki.ingest
wiki.ingest: ## Ingest a source into the wiki: SRC=path/to/file
	@if [ -z "$$SRC" ]; then echo "Usage: make wiki.ingest SRC=path/to/source"; exit 2; fi
	@if [ ! -f "$$SRC" ]; then echo "ERROR: $$SRC not found"; exit 1; fi
	@echo "→ Invoke an LLM agent (Claude Code / Codex / Gemini) with this prompt:"
	@echo
	@echo "    Read wiki/AGENTS.md, wiki/schema.md, wiki/purpose.md, wiki/index.md,"
	@echo "    then perform an ingest of: $$SRC"
	@echo "    Two-step CoT: analyze then generate per the schema."
	@echo "    Update index.md and append a [YYYY-MM-DD] entry to log.md."
	@echo
	@echo "(This Makefile target stops at the prompt — actual LLM invocation is the agent's job.)"

.PHONY: wiki.query
wiki.query: ## Query the wiki: Q="your question"
	@if [ -z "$$Q" ]; then echo "Usage: make wiki.query Q=\"your question\""; exit 2; fi
	@echo "→ Invoke an LLM agent with this prompt:"
	@echo
	@echo "    Read wiki/AGENTS.md, wiki/schema.md, wiki/purpose.md, wiki/index.md."
	@echo "    Query: $$Q"
	@echo "    Synthesize an answer with [[wikilink]] citations on every claim."
	@echo "    If substantial, file as pages/synthesis/<slug>.md and update index.md."

.PHONY: wiki.lint
wiki.lint: ## Run the wiki health check (delegates to the LLM agent)
	@echo "→ Invoke an LLM agent with this prompt:"
	@echo
	@echo "    Read wiki/AGENTS.md and wiki/schema.md."
	@echo "    Run a lint pass per the schema's lint workflow."
	@echo "    Write the report to wiki/.lint-report.md (gitignored)."
	@echo "    Append a [YYYY-MM-DD] lint entry to wiki/log.md."

# ---------- Secrets ----------

.PHONY: secrets.unlock
secrets.unlock: ## direnv allow + ensure pass store is current
	@direnv allow .
	@PASSWORD_STORE_DIR="$$PWD/secrets/store" pass git pull --rebase 2>/dev/null || true
	@echo "OK: shell secrets reloaded — try \`echo \$$OPENAI_API_KEY\`"

.PHONY: secrets.rotate
secrets.rotate: ## List secrets older than 90 days
	@PASSWORD_STORE_DIR="$$PWD/secrets/store" scripts/secrets-rotate.sh

.PHONY: secrets.mirror-bws
secrets.mirror-bws: ## Mirror pass store to Bitwarden Secrets Manager (needs BWS_ACCESS_TOKEN + PROJECT_ID env vars)
	@if [ -z "$$BWS_ACCESS_TOKEN" ] || [ -z "$$PROJECT_ID" ]; then \
	    echo "Usage: BWS_ACCESS_TOKEN=… PROJECT_ID=… make secrets.mirror-bws"; exit 2; fi
	@PASSWORD_STORE_DIR="$$PWD/secrets/store" \
	  scripts/secrets-mirror-to-bws.sh --project-id "$$PROJECT_ID"

.PHONY: secrets.sync-github-bw
secrets.sync-github-bw: ## Sync Bitwarden/Vaultwarden vault items to GitHub Actions secrets (MAP=, DRY_RUN=1)
	@args="--map $${MAP:-secrets/github-secrets.tsv}"; \
	if [ "$${DRY_RUN:-0}" = "1" ]; then args="$$args --dry-run"; fi; \
	scripts/secrets-sync-github-from-bitwarden.sh $$args

# ---------- GitHub control plane ----------
.PHONY: github.doctor
github.doctor: ## Read-only audit of runner/workflows/app/submodules/secrets/policy state
	@args=""; \
	if [ "$${OFFLINE:-0}" = "1" ]; then args="$$args --offline"; fi; \
	if [ "$${JSON:-0}" = "1" ]; then args="$$args --json"; fi; \
	if [ "$${STRICT:-0}" = "1" ]; then args="$$args --strict"; fi; \
	python3 scripts/github-doctor.py $$args

.PHONY: github-app.smoke
github-app.smoke: ## Smoke-test GitHub App installation token exchange (DRY_RUN=1 skips API)
	@args=""; \
	if [ "$${DRY_RUN:-0}" = "1" ]; then args="$$args --dry-run"; fi; \
	if [ "$${JSON:-0}" = "1" ]; then args="$$args --json"; fi; \
	python3 scripts/github-app-token-smoke.py $$args

# ---------- Runner ----------
.PHONY: runner.install
runner.install: ## Dry-run install/upgrade self-hosted runner binary (CONFIRM=1 DRY_RUN=0 to apply)
	@args=""; \
	if [ "$${DRY_RUN:-1}" = "0" ]; then args="$$args --execute"; else args="$$args --dry-run"; fi; \
	runner/install.sh $$args

.PHONY: runner.register
runner.register: ## Dry-run register runner: MODE=org|repo NAME=<reponame> (CONFIRM=1 DRY_RUN=0 to apply)
	@if [ -z "$$MODE" ]; then echo "Usage: make runner.register MODE=org  (or MODE=repo NAME=<reponame>)"; exit 2; fi
	@args="--$$MODE"; \
	if [ "$$MODE" = "repo" ] && [ -n "$$NAME" ]; then args="$$args $$NAME"; fi; \
	if [ "$${DRY_RUN:-1}" = "0" ]; then args="$$args --execute"; else args="$$args --dry-run"; fi; \
	runner/register.sh $$args

.PHONY: runner.remove
runner.remove: ## Dry-run remove runner registration/service (CONFIRM=1 DRY_RUN=0 to apply)
	@if [ -z "$$MODE" ]; then echo "Usage: make runner.remove MODE=org  (or MODE=repo NAME=<reponame>)"; exit 2; fi
	@args="--$$MODE"; \
	if [ "$$MODE" = "repo" ] && [ -n "$$NAME" ]; then args="$$args $$NAME"; fi; \
	if [ "$${DRY_RUN:-1}" = "0" ]; then args="$$args --execute"; else args="$$args --dry-run"; fi; \
	runner/remove.sh $$args

.PHONY: runner.doctor
runner.doctor: ## Read-only local runner readiness checks
	@args=""; \
	if [ "$${JSON:-0}" = "1" ]; then args="$$args --json"; fi; \
	if [ "$${STRICT:-0}" = "1" ]; then args="$$args --strict"; fi; \
	scripts/runner-doctor.sh $$args

.PHONY: runner.status
runner.status: ## Show systemd status of the runner service(s)
	@systemctl list-units --all 'actions.runner.*' --no-pager 2>/dev/null || true
	@systemctl list-units --all 'runner-spawn@*' --no-pager 2>/dev/null || true

# ---------- CI local ----------

.PHONY: ci.local
ci.local: ## Run a workflow locally with act: WORKFLOW=ci.yml
	@command -v act >/dev/null 2>&1 || { echo "act not installed — see github.com/nektos/act"; exit 1; }
	@if [ -z "$$WORKFLOW" ]; then echo "Usage: make ci.local WORKFLOW=ci.yml"; exit 2; fi
	act -W .github/workflows/$$WORKFLOW

# ---------- Cleanup ----------

.PHONY: clean
clean: ## Remove caches and ignored cruft (DOES NOT touch submodules or .gitignored secrets dirs)
	@find . -type d -name '__pycache__' -prune -exec rm -rf {} +
	@find . -type d -name '.pytest_cache' -prune -exec rm -rf {} +
	@find . -type d -name '.ruff_cache' -prune -exec rm -rf {} +
	@rm -rf .markdownlint-cli2.cache/
