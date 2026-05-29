# Research: slim

**Status:** Phase 3 complete — build and tests verified.
**Upstream:** `nilbuild/slim` (formerly `kamranahmedse/slim` — renamed 2026-05)
**Action gated by this dossier:** §10 Open Decisions must be resolved before any fork.

---

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/nilbuild/slim` |
| Our fork (to be created) | TBD — do NOT run `gh repo fork` until §10 resolved |
| License | **PolyForm Shield 1.0.0** — NON-OSI, non-compete clause (see §4) |
| Default branch | `main` |
| Latest upstream commit | `9c07a08` — "Update install script" (2026-05-09) |
| Go module path | `github.com/kamranahmedse/slim` (go.mod not yet updated after rename) |
| Go version required | `go 1.25.0+` |
| Binary name | `slim` |
| Hardcoded version | `0.0.1` (goreleaser overrides via `-X cmd.Version` ldflags on releases) |
| Local clone (work) | `.attic/research-work/slim` (gitignored) |
| Pack | `data/brain-data/research/slim/repomix-pack.xml` |

---

## 2. Purpose (cross-verified)

**README says:** "Simple command to get clean HTTPS local domains for your projects" — maps
custom `.test` / `.loc` local domains to dev server ports with HTTPS and WebSocket/HMR passthrough.

**Code says** (`cmd/root.go` `rootCmd.Long`):
> "slim maps custom local domains to dev server ports with HTTPS and WebSocket passthrough for HMR."

**Code-match verdict:** Perfect match — README and code agree exactly.

**Feature split:**

| Feature | Auth required | Cloud required |
|---|---|---|
| `slim start` / `stop` / `list` / `up` / `down` | No | No — fully local |
| `/etc/hosts` management | sudo (first run) | No |
| CA cert generation + trust | sudo (first run) | No |
| Port forwarding :80→:10080 / :443→:10443 | sudo | No |
| `slim share` — public tunnel via slim.show | Yes — `slim login` | Yes — `wss://app.slim.sh/tunnel` |
| `slim domain` — custom domain management | Yes | Yes — `https://app.slim.sh` |

The **local proxy mode is fully self-contained** — no account, no network, no Docker. The cloud
tunnel (`slim share`) and custom domain management require an account at `app.slim.sh`.

---

## 3. Stack inventory

**Build system:** `make build` → `go build -ldflags "-s -w -X github.com/kamranahmedse/slim/cmd.Version=$(VERSION)" -o slim .`
`make install` → moves binary to `/usr/local/bin/`
`make test` → `go test ./...`

**Dev server:** None — slim IS the dev tool.

**Runtime requirements:** Go 1.25.0+ (verified: Go 1.25.10 available via mise)

**Key direct dependencies** (from `go.mod`):

| Package | Purpose |
|---|---|
| `github.com/spf13/cobra` | CLI framework |
| `charm.land/lipgloss/v2` | Terminal table/style rendering |
| `github.com/charmbracelet/huh/spinner` | TUI spinner for step progress |
| `github.com/coder/websocket` | WebSocket client for public tunnels |
| `github.com/sevlyar/go-daemon` | Unix process daemonization |
| `golang.org/x/net` | HTTP/2, proxy support |
| `gopkg.in/yaml.v3` | Config file (`~/.slim/config.yaml`) |

**No database.** No Docker. No native deps / node-gyp / CGo / FFI.

**Ports used:**
- `:10080` — HTTP ingress (proxy listens here)
- `:10443` — HTTPS ingress (proxy listens here)
- `:80` / `:443` — forwarded to the above via system port-forwarding rules (iptables on Linux, pf on macOS)
- Daemon IPC: `~/.slim/slim.sock` (Unix socket)

**Config dir:** `~/.slim/` — `config.yaml`, `access.log`, `auth.json`, `slim.sock`, `slim.pid`, `pf.token`, `tunnel-token`

**Env vars:**

| Var | Required | Default | Purpose |
|---|---|---|---|
| `SLIM_TUNNEL_SERVER_API` | OPTIONAL | `https://app.slim.sh` | API base for auth + domain management |
| `SLIM_TUNNEL_SERVER` | OPTIONAL | `wss://app.slim.sh/tunnel` | WebSocket tunnel relay |

**Auth flow:** OAuth via `app.slim.sh` — browser-based login, polls for completion, stores JWT in `~/.slim/auth.json`. Required only for `slim share` / `slim domain`.

**Docs site:** `docs/` contains a separate Astro website (not needed to build or run slim itself).

---

## 4. License caveat

**License file:** `LICENSE` — PolyForm Shield License 1.0.0

Copyright (c) 2026 Kamran Ahmed

**SPDX:** Not OSI-approved. Classified as "Source Available" / business-source.

**Key restriction (verbatim):**
> "You may not use the Software to provide a product or service that **competes with the Software**
> or any product or service offered by the Licensor that includes the Software."

**Implications:**
- Personal / internal use for local dev tooling: **likely fine** — no competing product.
- Building a competing tunnel/proxy SaaS: **blocked** by license.
- Forking and modifying for personal homelab use: **likely fine**, but forking publicly while
  implying it's a competitor would risk violation.
- The license explicitly **does not restrict** use, copy, modify, distribute for non-competing purposes.

**Recommendation:** Keep any fork private or clearly non-competing. Do not build a SaaS tunnel
product based on this code. Legal review required before any commercial use.

**No CLA** found in `CONTRIBUTING.md` (file absent from repo).

---

## 5. FlexNetOS-side intent

Use slim as a **local development proxy tool** on the homelab/workspace machine:
- Map project dev servers (`myapp.test`, `api.test`, etc.) to localhost ports with valid HTTPS
- Eliminate the need for self-managing mkcert + nginx vhost entries per project
- Optional: use `slim share` for quick ad-hoc external access during demos (requires slim.sh account)

This is purely internal personal tooling — no competitive product is being built. PolyForm Shield
non-compete is not triggered by this use case.

Clone destination specified by user: `network/slim` (within the umbrella).

---

## 6. Pre-adoption audit

- [x] **Active upstream** — last commit 2026-05-09, CI workflows present, issues open
- [ ] **License clear** — PolyForm Shield 1.0.0: non-compete clause requires confirmation that use is
      non-competing (see §4). Mark checked once §10 license decision is recorded.
- [x] **Build reproduces locally** — `go build` exit 0; `go test ./...` all PASS (see §9)
- [x] **No nested submodules with restrictive licenses** — pure Go module, no submodules
- [ ] **Sync cadence agreed** — TBD in §10

---

## 7. Adoption plan

**Recommended approach:** Private work-dir clone only (`.attic/research-work/slim`) — do not add
to `repos/MANIFEST.yaml` as a submodule until the license decision in §10 is made.

If forking is approved:
1. `gh repo fork nilbuild/slim --org FlexNetOS --clone=false`
2. Fork's `main` tracks upstream; all changes on `develop`
3. Add to `repos/MANIFEST.yaml` under `repos/external/` (not `forked/` — license restricts public forks
   that could be perceived as competitive)
4. `make submodules.add` to register
5. Consider keeping the fork private if uncertain about competitive perception

**If not forking:** Install the upstream binary via `curl -sL https://slim.sh/install.sh | sh`
and skip submodule registration entirely.

---

## 8. Sync risk

| Factor | Assessment |
|---|---|
| Release cadence | No semver tags visible; version hardcoded 0.0.1, releases via goreleaser — check GitHub releases |
| Last commit | 2026-05-09 — recently active |
| Upstream stability | Active but pre-1.0, API may change |
| License drift | PolyForm Shield may be tightened — watch for LICENSE changes on upstream |
| Module path mismatch | `go.mod` still uses `kamranahmedse/slim`, not `nilbuild/slim` — any fork must be aware |

**Sync recommendation:** Pull upstream security patches as needed; no automated sync required for
a dev tool used as a binary.

---

## 9. Verification

Commands run on 2026-05-29:

```bash
# Go runtime
mise install go@1.25.10           # exit 0
mise exec go@1.25.10 -- go version
# → go version go1.25.10 linux/amd64

# Build
cd .attic/research-work/slim
mise exec go@1.25.10 -- go build -ldflags "-s -w" -o slim_test_bin .
# → exit 0 (downloads all deps on first run, then builds)

# Smoke test
./slim_test_bin version
# → slim 0.0.1

# Test suite
mise exec go@1.25.10 -- go test ./...
# → all packages PASS, exit 0
# cmd, cert, config, daemon, doctor, httperr, log, project, proxy, setup, system, term, tunnel, protocol

# Cleanup
rm slim_test_bin
```

**Verdict: PASS** — builds cleanly from source, all tests green.

No `.env` file needed for local proxy mode. Cloud tunnel features require `slim login` at runtime.

---

## 10. Open decisions (gate before fork)

- [ ] **License go/no-go:** Confirm use is non-competing (personal homelab tooling only). Record
      decision here. Downstream: if personal use only, proceed; if any commercial angle, legal review first.
- [ ] **Fork vs binary install:** Given PolyForm Shield, decide: (a) fork privately to FlexNetOS
      org for potential patches, or (b) just install the upstream release binary and skip forking.
      Binary install is simpler and has zero license friction.
- [ ] **Submodule path:** User specified `network/slim` as the clone destination — confirm this is
      the intended MANIFEST path if forking; otherwise this is just a work-dir reference tool.
- [ ] **Go runtime activation:** `mise use go@1.25.10` to add Go to the global mise config
      (currently installed but not activated). Decide: global activation or project-local only?
- [ ] **slim.sh account:** `slim share` and `slim domain` require a free account at `app.slim.sh`.
      Free tier supports basic tunnels; Pro adds custom subdomains/domains/password. Env var
      `SLIM_TUNNEL_SERVER_API` can override to a self-hosted server if desired in future.
- [ ] **Sync cadence:** For binary install — how often to update? For fork — track upstream `main`
      on demand or on a schedule?

---

## 11. Decision log

(empty — fill on adoption)

---

## 12. Discrepancies — README vs code

| README / QUICKSTART claim | Code reality | Severity |
|---|---|---|
| `git clone https://github.com/kamranahmedse/slim.git` | Repo renamed to `nilbuild/slim`; old URL still works via GitHub redirect but is stale | warn |
| `FUNDING.yml: github: [kamranahmedse]` | Old GitHub username; nilbuild is the current owner | info |
| `go.mod` module path `github.com/kamranahmedse/slim` | Not updated after rename — any fork must handle this import path | warn |
| Version badge shows `0.0.1`-equivalent | `var Version = "0.0.1"` in code; goreleaser overrides in releases — running from source gives `slim 0.0.1` always | info |
| README build instructions use `make build` then `make install` | Matches Makefile exactly — no discrepancy | — |
| `go 1.25+` requirement | `go.mod` says `go 1.25.0` — matches | — |
