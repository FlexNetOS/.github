# RALPLAN-DR: Six-Layer Workstation Architecture (DNS + Proxy + Slim + Browser + LLM Gateway + Automation)

**Status:** pending approval
**Version:** 5 (added network-DNS layer + outbound proxy + diagnostic tooling; v4.1 service architecture intact)
**Mode:** SHORT (decision plan, not implementation plan)
**Owner:** drdave (FlexNetOS)
**Scope:** Solve daily browsing + Claude access + Playwright automation on a Linux-primary workstation, *with explicit network-DNS, outbound-proxy, and diagnostic-tooling layers* so the workstation operates as a coherent privacy-respecting unit, not just a pile of localhost services.

---

## Changelog from v4.1

User feedback: *"Do you have a reverse-proxy, proxy, and DNS in the plan?"* Honest answer: only partially. v4.1 had Slim doing local DNS (`.test`) and reverse-proxy duty for own-services, but had **no upstream DNS filter** (workstation queries went to whatever the OS resolver was) and **no outbound forward proxy** (vproxy was only namedropped in follow-ups). v5 closes both gaps and adds two operational tools the user named.

**Added in v5:**
- **Layer -2 — Network DNS (Pi-hole + dnscrypt-proxy → NextDNS).** Pi-hole on the workstation as the local resolver (sinkhole, dashboard, cache); dnscrypt-proxy as the encryption wrapper; NextDNS as the encrypted upstream with custom filter lists. *Per later user directive, NextDNS was swapped for Cloudflare + Quad9 DNSCrypt upstreams to skip the NextDNS account requirement.*
- **Layer -1 — Outbound forward proxy (vproxy).** Recommended (opt-in per service). HTTP/HTTPS/SOCKS5. Use cases: route Playwright/obscura through a specific egress IP for scraping, inspect/log bifrost's outbound LLM calls, configurable per-service.
- **Diagnostic tooling (sidecar, not a runtime layer):**
  - **trippy** (`github.com/fujiapple852/trippy`) — Rust TUI traceroute+ping+MTR. Use when any layer misbehaves.
  - **RTK (Rust Token Killer)** — already system-wide per global `~/.claude/CLAUDE.md`. Hook-rewrites dev CLIs (`git`, etc.) through `rtk` for 60-90% token savings. Not architected new; just acknowledged.

**Architecture unchanged from v4.1:** Firefox (Layer 1) + Bifrost (Layer 2) + Obscura (Layer 3) with bundled Chromium fallback; Slim (Layer 0) still fronts all `.test` hostnames; Vaultwarden still the credential source.

---

## Changelog from v4

User said "we have way too many ports". v4.1 added Slim as Layer 0:
- `slim start <name> --port <n>` registers `https://<name>.test` → `localhost:<n>`
- Pi-hole admin via `https://pihole.test`, bifrost via `https://bifrost.test`, obscura via `https://obscura.test`
- Slim provides HTTPS termination + local DNS for `.test` (subsumes `/etc/hosts` + manual reverse proxy)

---

## Changelog from v3

User said "main OS is linux so edge is a problem". v3 had recommended Brave (Stable) for daily; v4 was the bigger architecture flip after the user rejected both Brave and Edge and surfaced 7 reference repos. v4 dropped the "pick one browser" frame entirely and adopted a three-layer split (Firefox + bifrost + obscura). v4.1 added Slim. v5 added the network-DNS and outbound-proxy layers.

---

## 1. Principles (6)

1. **Tool to the job, not job to the tool.** Each constraint (daily browsing, Claude access, Playwright automation) gets a purpose-built tool. Stop trying to make one binary serve three roles.
2. **Daily browser is not load-bearing for AI access.** With a local LLM gateway (layer 2), the "Claude must be a browser extension" constraint dissolves. Daily browser choice becomes a personal/privacy preference, not an AI-access dependency.
3. **Playwright works best with a browser designed for Playwright.** Headless Chrome was repurposed for automation; obscura was designed for it. Use the purpose-built tool.
4. **Version pinning at the right layer.** Daily browser auto-updates for security. Automation browser (obscura) ships versioned releases — bump deliberately. LLM gateway (bifrost) is Docker-pinned by tag.
5. **No single account, no single vendor.** Vaultwarden for credentials; bifrost for LLM access (Anthropic + many fallbacks); Firefox sync optional. No lock-in to Microsoft, Google, or Brave Software.
6. **Recoverable per layer.** Swapping any one layer (Firefox→LibreWolf, bifrost→freellmapi, obscura→playwright's bundled chromium) is a config change, not a re-architecture. Layers communicate via stable interfaces (OpenAI API, CDP).

---

## 2. Decision Drivers (top 4)

1. **Linux-first-class quality** at every layer. Daily browser must treat Linux as primary (Firefox: yes; Chromium-family: yes; Edge: no per user constraint).
2. **Playwright/CDP compatibility** for the automation browser. Must be a true Puppeteer/Playwright drop-in (obscura: yes via CDP and Puppeteer/Playwright API; Playwright's bundled chromium: yes).
3. **LLM access independent of browser** — must work in any tool that can speak HTTP. Local gateway (bifrost) gives an OpenAI-compatible `localhost:8080` endpoint usable by Claude Desktop, IDE plugins, CLI scripts, browser tabs hitting localhost, MCP clients, etc.
4. **Each layer pins or auto-updates appropriately.** Daily browser: auto-update for security. Automation browser: pinned per release. Gateway: pinned per Docker tag.

---

## 3. Layer-by-layer alternatives

### Layer 1 — Daily browser

| Candidate | Linux-first-class? | Claude access via? | Verdict |
|---|---|---|---|
| **Firefox (recommended)** | Yes (Mozilla treats Linux as primary build target) | Layer 2 (bifrost) or Claude.ai web tab | **PICK** |
| LibreWolf | Yes (Firefox fork, privacy-hardened) | Same as Firefox | Acceptable alternative |
| Brave | Yes | CWS extension OR layer 2 | Rejected by user |
| Microsoft Edge | No (Linux second-class) | CWS extension OR layer 2 | Rejected by user |
| Google Chrome | Yes | CWS extension OR layer 2 | Auto-update friction, Google-bound |
| Ungoogled-Chromium | Yes (community builds) | Layer 2 only | Heavier setup |

Firefox wins layer 1 because: (a) Linux is a first-class Mozilla target, (b) it's a true alternative rendering engine (Gecko, not Chromium), (c) the original "no Claude extension on Firefox" objection dissolves when Claude access is via layer 2.

### Layer 2 — Claude (and other LLM) access

| Candidate | What it gives you | Verdict |
|---|---|---|
| **Bifrost (recommended)** | OpenAI-compatible `localhost:8080`, 1000+ models including Anthropic, load balancing, semantic cache, Docker-deployable | **PICK** |
| FreeLLMAPI | OpenAI-compatible aggregator for ~14 free-tier providers | Optional sidecar |
| LiteLLM | OpenAI-compatible proxy, Python-based | Slower than bifrost |
| Direct Anthropic SDK | Just call `anthropic.Anthropic(...)` from each tool | Loses unified-interface benefit |
| Claude browser extension | Sidebar in Chromium browsers | What we're moving away from |
| Claude.ai web | Browser tab | Acceptable fallback for casual use |

Bifrost wins because: (a) OpenAI-compatible API means any client library works, (b) includes Anthropic so you get Claude, (c) Docker deploy = trivial install, (d) MCP gateway support fits the user's MCP-heavy workflow.

### Layer 3 — Playwright automation browser

| Candidate | Built for Playwright? | Version model | Verdict |
|---|---|---|---|
| **Obscura (recommended)** | Yes (Puppeteer + Playwright APIs, CDP-compatible) | GitHub releases — no auto-update | **PICK** |
| Playwright bundled Chromium | Yes | Pinned per Playwright version | Acceptable fallback |
| Chrome for Testing | Yes | Pinned per CfT version | More wiring cost |
| Google Chrome Stable | No (daily browser repurposed) | Silent auto-update | Never pick |
| Brave | No (privacy features fight automation) | Brave Software releases | Loses on Shields friction |

Obscura wins because: (a) designed for Playwright/Puppeteer specifically, (b) 30MB memory vs 200MB+ for headless Chrome, (c) anti-detect built in, (d) versioned releases means you control updates explicitly, (e) Rust + V8 means actual CDP fidelity. Keep bundled chromium as fallback for any CDP edge case obscura doesn't yet implement.

---

## 4. Recommended Architecture

```
                ┌──────────────────────────────────────────────────────┐
                │ Daily workstation (Linux, drdave)                    │
                │                                                      │
                │  ┌────────────────────────────────────────────────┐  │
                │  │ Layer 1: Daily browser                         │  │
                │  │   Firefox (Stable)                             │  │
                │  │   - Bitwarden ext → Vaultwarden                │  │
                │  │   - Optionally Claude.ai as a pinned tab       │  │
                │  └────────────────────────────────────────────────┘  │
                │                                                      │
                │  ┌────────────────────────────────────────────────┐  │
                │  │ Layer 0: Slim (local DNS + HTTPS gateway)      │  │
                │  │   - bifrost.test     → localhost:8080          │  │
                │  │   - freellmapi.test  → localhost:8081 (opt)    │  │
                │  │   - obscura.test     → localhost:9222          │  │
                │  │   - pihole.test      → localhost:8053          │  │
                │  │   - vproxy.test      → localhost:9999          │  │
                │  │   - <project>.test   → localhost:<dev-port>    │  │
                │  └────────────────────────────────────────────────┘  │
                │                                                      │
                │  ┌────────────────────────────────────────────────┐  │
                │  │ Layer -1: vproxy (outbound forward proxy,      │  │
                │  │   opt-in per service)                          │  │
                │  │   - HTTP/HTTPS/SOCKS5 on 127.0.0.1:9999        │  │
                │  │   - Basic auth from ~/vproxy/.env              │  │
                │  └────────────────────────────────────────────────┘  │
                │                                                      │
                │  ┌────────────────────────────────────────────────┐  │
                │  │ Layer -2: Network DNS                          │  │
                │  │   Pi-hole (Docker, :53, dashboard via Slim)    │  │
                │  │      ↓ forwards to                             │  │
                │  │   dnscrypt-proxy (loopback :5353)              │  │
                │  │      ↓ encrypted DoH                           │  │
                │  │   Cloudflare + Quad9 DNSCrypt (NextDNS skipped)│  │
                │  └────────────────────────────────────────────────┘  │
                │                                                      │
                │  Backends (fronted by Slim):                         │
                │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
                │  │ Bifrost     │  │ FreeLLMAPI  │  │ Obscura     │   │
                │  │ LLM gateway │  │ (sidecar,   │  │ CDP server  │   │
                │  │ Docker,     │  │  optional)  │  │ Rust,       │   │
                │  │ :8080       │  │ Docker,8081 │  │ :9222       │   │
                │  └─────────────┘  └─────────────┘  └─────────────┘   │
                │                                                      │
                │  Diagnostic sidecar: trippy (network path debug)     │
                │  System-wide: RTK (Rust Token Killer, transparent)   │
                └──────────────────────────────────────────────────────┘
```

### How this defuses the original three pain points

- **"Playwright doesn't work well with Chrome"** → not using Chrome for automation at all. Obscura is purpose-built for Playwright/Puppeteer.
- **"Firefox doesn't have the Claude extension"** → don't need the Claude extension. Bifrost gives you Claude via OpenAI-compatible API.
- **"Brave is a new trend" / "Edge is Linux-second-class"** → moot. Browser brand is decoupled from both LLM access and automation. Firefox wins on Linux + privacy + alt-engine grounds.

---

## 5. Configuration sketches

### Layer 1 — Firefox (extension install only; see section 9)

### Layer 0 — Slim

```bash
curl -sL https://slim.sh/install.sh | sh
slim start pihole     --port 8053
slim start bifrost    --port 8080
slim start freellmapi --port 8081   # if running the sidecar
slim start obscura    --port 9222
slim start vproxy     --port 9999
slim list                            # canonical "what's running" view
```

### Layer -2 — Network DNS

**dnscrypt-proxy** at `127.0.0.1:5353` with Cloudflare + Quad9 (NextDNS skipped per user):

```toml
# /etc/dnscrypt-proxy/dnscrypt-proxy.toml
listen_addresses = ['127.0.0.1:5353']
server_names = ['cloudflare', 'quad9-dnscrypt-ip4-filter-pri']
require_dnssec = true
ipv6_servers = false
cache = true
cache_size = 1024
```

**Pi-hole** in Docker, listening on `127.0.0.1:53`, forwarding to dnscrypt-proxy:

```yaml
# ~/pihole/docker-compose.yml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    ports:
      - "127.0.0.1:53:53/tcp"
      - "127.0.0.1:53:53/udp"
      - "127.0.0.1:8053:80/tcp"
    environment:
      TZ: "America/Los_Angeles"
      WEBPASSWORD: "${PIHOLE_PASS}"
      PIHOLE_DNS_: "127.0.0.1#5353"
      DNSMASQ_LISTENING: "local"
      DNSSEC: "true"
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
```

**Point the workstation at Pi-hole:**

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf <<'EOF'
[Resolve]
DNSStubListener=no
EOF
sudo systemctl restart systemd-resolved
sudo rm -f /etc/resolv.conf
echo 'nameserver 127.0.0.1' | sudo tee /etc/resolv.conf
echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf.fallback   # recovery
```

### Layer -1 — vproxy

```bash
cargo install vproxy
source ~/vproxy/.env
vproxy start --bind "$VPROXY_BIND" --auth "$VPROXY_USER:$VPROXY_PASS" --type http
```

Per-service opt-in (Playwright example):

```python
ctx = p.chromium.launch_persistent_context(
    user_data_dir=str(Path.home() / ".cache/playwright-profile"),
    headless=True,
    proxy={"server": "http://127.0.0.1:9999", "username": "user", "password": "pass"},
)
```

### Layer 2 — Bifrost

```yaml
# ~/bifrost/docker-compose.yml
services:
  bifrost:
    image: maximhq/bifrost:latest
    container_name: bifrost
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./data:/app/data
    env_file:
      - .env       # contains ANTHROPIC_API_KEY + OPENROUTER_API_KEY
```

```bash
# Smoke via Slim hostname:
curl -sS https://bifrost.test/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"anthropic/claude-3-7-sonnet-latest",
       "messages":[{"role":"user","content":"reply: bifrost"}]}' \
  | jq -r '.choices[0].message.content'
```

### Layer 3 — Obscura + Playwright (CDP via Slim)

```bash
# Start obscura:
obscura serve --port 9222 &
```

```python
# Python — connect Playwright to obscura via Slim hostname
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp("https://obscura.test")
    ctx = browser.contexts[0] if browser.contexts else browser.new_context()
    page = ctx.new_page()
    page.goto("https://example.com")
    print(page.title())  # "Example Domain"
    browser.close()
```

Fallback when obscura hits a CDP gap on a test:

```python
ctx = p.chromium.launch_persistent_context(
    user_data_dir=str(Path.home() / ".cache/playwright-profile"),
    headless=True,
)
```

### Diagnostic — trippy

```bash
cargo install trippy                          # binary is `trip`, not `trippy`
sudo setcap cap_net_raw+ep $(which trip)      # avoid needing sudo each run

trip api.anthropic.com -m 5 -c 3              # validate bifrost outbound path
trip 1.1.1.1            -m 5 -c 3             # validate DNS upstream path
trip --tui example.com                        # MTR-style TUI
```

---

## 6. Honest tradeoffs

- **Eight tools to maintain (Pi-hole + dnscrypt-proxy + Cloudflare/Quad9 + vproxy + Slim + Firefox + Bifrost + Obscura), plus diagnostic sidecar (trippy) and system-wide RTK.** Each one changes on its own cadence and a problem in one doesn't compromise the others.
- **Slim adds a dependency in front of own-services.** If Slim is broken, `bifrost.test` / `obscura.test` / `pihole.test` stop resolving. Recovery: hit raw ports (`localhost:8080`, etc.) until restart. Public DNS unaffected.
- **Pi-hole adds a dependency in front of all public DNS.** If Pi-hole is broken, the workstation can't resolve `api.anthropic.com`, `claude.ai`, anything. **Recovery: `sudo chattr -i /etc/resolv.conf && sudo cp /etc/resolv.conf.fallback /etc/resolv.conf`.** Document this in your runbook.
- **dnscrypt-proxy + upstream coupling.** Pi-hole's upstream is `127.0.0.1:5353` (dnscrypt-proxy); dnscrypt-proxy's upstream is Cloudflare/Quad9. If both fail, no encrypted DNS. Add fallback `server_names` in `dnscrypt-proxy.toml`.
- **vproxy is intentionally opt-in.** Routing everything through vproxy adds latency and obscures which service actually needs egress shaping. Default: direct egress.
- **Firefox lacks the Claude *extension* specifically.** You get Claude two other ways: (a) `https://bifrost.test/v1` via bifrost for programmatic use, (b) `claude.ai` web tab for casual chat.
- **Some apps cache DNS aggressively.** Firefox: `about:config` → `network.trr.mode = 5` (defer to system DNS = Pi-hole). Docker containers honor host's `/etc/resolv.conf` but may need `--dns=172.17.0.1`.
- **Disk cost.** Firefox ~250MB, Pi-hole image ~150MB, Bifrost image ~100MB, Obscura ~70MB, Playwright bundled chromium ~450MB, ms-playwright cache shared via `PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright`. Total baseline ~1GB.
- **You give up "single binary serves everything."** That ideal is what caused the original Chrome pain.

### When a different choice would be better

- **If obscura has CDP gaps that break your test suite at scale:** keep Playwright's bundled chromium as the default automation target, demote obscura to "use for new scraping work where the determinism wins matter."
- **If you don't want to run Docker for bifrost:** install the bifrost Go binary directly via `npx -y @maximhq/bifrost`, or fall back to direct Anthropic SDK calls in each tool.
- **If you want zero third-party AI provider relationships:** bifrost supports vLLM, Ollama, LM Studio. Run a local LLM and route through bifrost.

---

## 7. Invalidation rationale (why the v1–v3 picks lost)

- **Microsoft Edge (daily):** Linux second-class. Rejected by user in v3 feedback.
- **Brave (daily):** rejected by user in v4 feedback. Even with v3's Linux-first-class + privacy posture, Brave preserves the Chrome Web Store extension dependency that v4 dissolves.
- **Google Chrome (daily or automation):** auto-update friction + Google account binding. Layer 2 (bifrost) eliminates the only argument for keeping Chrome (the Claude extension).
- **Playwright's bundled Chromium as the *default* automation target:** demoted to fallback. Obscura is purpose-built for the same job with better memory and explicit version control.
- **Chrome for Testing:** equivalent to bundled chromium, more wiring cost.
- **LiteLLM (vs bifrost):** bifrost is faster per benchmarks; bifrost has a built-in web UI.
- **Direct Anthropic SDK in every tool (vs bifrost):** loses unified-interface and fallback-provider benefits.
- **Claude browser extension (vs bifrost):** couples Claude access to browser choice — exactly the dependency v4 removes.
- **NextDNS (vs Cloudflare/Quad9):** dropped per user direction to skip the NextDNS account requirement.

---

## 8. ADR

- **Decision:** Six-layer workstation architecture.
  - **Layer -2 (Network DNS)**: Pi-hole on `127.0.0.1:53` → dnscrypt-proxy on `127.0.0.1:5353` → Cloudflare + Quad9 DNSCrypt. Pi-hole dashboard at `https://pihole.test` via Slim.
  - **Layer -1 (Outbound proxy, opt-in per service)**: vproxy on `127.0.0.1:9999`, basic-auth HTTP/HTTPS/SOCKS5. Optional Slim hostname `vproxy.test`.
  - **Layer 0 (Local DNS + reverse proxy for own services)**: Slim — `.test` hostnames + auto HTTPS for every backend.
  - **Layer 1 (Daily browser)**: Firefox Stable. Bitwarden→Vaultwarden. claude.ai pinned tab.
  - **Layer 2 (LLM gateway)**: Bifrost (Docker, `localhost:8080`, Slim: `https://bifrost.test`) with Anthropic + OpenRouter providers. Optional FreeLLMAPI sidecar at `https://freellmapi.test`.
  - **Layer 3 (Playwright automation)**: Obscura (`localhost:9222`, Slim: `https://obscura.test`). Playwright bundled Chromium installed as CDP-gap fallback. `PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright`.
  - **Diagnostic sidecar**: trippy. System-wide RTK already in place per global CLAUDE.md.
- **Drivers:**
  1. Linux is the user's primary OS — every layer must treat Linux as first-class.
  2. Playwright/CDP compatibility — bundled chromium proven fallback for obscura's CDP gaps.
  3. LLM access decoupled from browser choice — bifrost makes "the Claude extension" a non-requirement.
  4. Per-layer version pinning matches per-layer needs (daily auto-update; automation pinned; gateway pinned).
- **Alternatives considered:** Microsoft Edge (rejected for Linux), Brave (rejected by user), Chrome Stable (auto-update + Google binding), Chrome for Testing (more wiring), LiteLLM (slower), direct Anthropic SDK (loses unified interface), Claude browser extension (couples Claude to browser), NextDNS (skipped per user). See sections 3 and 7.
- **Why chosen:** Solves the user's three constraints by giving each its own purpose-built tool. Linux honored at every layer. Vaultwarden remains the credential source. No vendor lock-in to Microsoft, Google, or Brave Software. The "Playwright doesn't work with Chrome" pain eliminated by not using Chrome; the "Firefox lacks the Claude extension" pain eliminated by not depending on browser extensions for LLM access; "Brave/Edge browser-vs-browser debate" rendered moot.
- **Consequences:**
  - Eight tools installed. Total baseline ~1GB. Bigger ops surface than v4.1 in exchange for explicit DNS + outbound-proxy layers.
  - Anthropic + OpenRouter API keys required for Claude via bifrost. Keys stored in `~/bifrost/.env` (chmod 600), referenced by docker compose via env_file.
  - Pi-hole + dnscrypt-proxy add network-level filter + encrypted DNS for everything (Firefox, bifrost outbound, obscura outbound).
  - Docker daemon must be running for bifrost AND Pi-hole. If it stops, both LLM access and DNS are offline (recover DNS via `resolv.conf.fallback` swap).
  - Obscura is newer — expect occasional CDP-gap fallbacks to bundled chromium.
- **Follow-ups (do NOT execute now; planning artifacts only):**
  1. Document the full v5 bootstrap in the repo's onboarding doc. Include the Slim hostname registry and `/etc/resolv.conf` + dnscrypt + upstream config.
  2. Add `export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright` to `~/.profile`.
  3. Add `~/bifrost/`, `~/pihole/`, and `~/vproxy/` to a small `infra/workstation/` repo with docker-compose.yml + `.env.example`. Secrets (`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, Pi-hole admin password, vproxy auth) sourced from Vaultwarden via env files that are git-ignored.
  4. Pin all versions in onboarding doc: Pi-hole tag, dnscrypt-proxy version, vproxy Cargo version, Slim version, Bifrost tag, Obscura release, Firefox channel, trippy version.
  5. Create `/etc/resolv.conf.fallback` (`nameserver 1.1.1.1`) and the one-liner script (`sudo cp /etc/resolv.conf.fallback /etc/resolv.conf`) for "Pi-hole is down" recovery.
  6. Optional: add FreeLLMAPI sidecar on `localhost:8081` (Slim: `https://freellmapi.test`) once bifrost baseline is stable.
  7. Optional: integrate `devolutions-gateway` only if you need to expose this dev workstation to remote-access sessions.
  8. Convert ad-hoc dev server starts to `slim start <name> --port <n>` so Slim's hostname registry is the single source of truth for local services.
  9. Add a workstation-wide `slim list` snapshot to the runbook: `slim list > docs/workstation-services.md` after any service add/remove.
  10. Add a trippy quick-reference to the runbook: `trip api.anthropic.com`, `trip 1.1.1.1`, `trip --tui <target>` for live debugging.
  11. **Extension-in-automation case:** if Playwright ever needs to drive a browser with the Claude extension loaded, use Playwright's bundled chromium (not obscura — extensions are a Chrome-specific surface) with a dedicated `user_data_dir` at `~/.cache/playwright-extension-profile`. Install the extension manually once; reuse the profile across runs.

---

## 9. Acceptance checklist (runnable, pass/fail)

**Order matters:** network DNS first (everything downstream depends on it), then Slim, then services. Each step has a verifiable PASS condition. **Execution covered by `scripts/install-v5-architecture.sh`.**

```
=== LAYER -2: NETWORK DNS ===

[ ] 1. Install dnscrypt-proxy:
       sudo apt update && sudo apt install -y dnscrypt-proxy
       PASS: dnscrypt-proxy --version returns a version string.

[ ] 2. Configure dnscrypt-proxy with Cloudflare + Quad9 (NextDNS skipped per user):
       Edit /etc/dnscrypt-proxy/dnscrypt-proxy.toml:
         listen_addresses = ['127.0.0.1:5353']
         server_names = ['cloudflare', 'quad9-dnscrypt-ip4-filter-pri']
       sudo systemctl restart dnscrypt-proxy
       PASS: dig @127.0.0.1 -p 5353 example.com +short returns an A record.

[ ] 3. Set up Pi-hole (Docker):
       mkdir -p ~/pihole && cd ~/pihole
       # Write docker-compose.yml from section 5
       docker compose up -d
       PASS: docker ps | grep pihole shows running.

[ ] 4. Verify Pi-hole forwards through dnscrypt-proxy:
       dig @127.0.0.1 example.com +short
       PASS: returns an A record (Pi-hole → dnscrypt-proxy → Cloudflare/Quad9).

[ ] 5. Point workstation at Pi-hole:
       sudo mkdir -p /etc/systemd/resolved.conf.d
       echo -e "[Resolve]\nDNSStubListener=no" | sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf
       sudo systemctl restart systemd-resolved
       sudo rm -f /etc/resolv.conf
       echo 'nameserver 127.0.0.1' | sudo tee /etc/resolv.conf
       PASS: getent hosts example.com returns an IP.

[ ] 6. Create fallback resolv.conf:
       echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf.fallback
       PASS: /etc/resolv.conf.fallback exists.

=== LAYER 0: SLIM ===

[ ] 7. Install Slim:
       curl -sL https://slim.sh/install.sh | sh
       PASS: slim --version returns a version string.

[ ] 8. Register Pi-hole hostname:
       slim start pihole --port 8053
       PASS: slim list shows "pihole.test → localhost:8053".

[ ] 9. Verify Pi-hole admin via Slim:
       xdg-open https://pihole.test/admin
       PASS: Pi-hole admin loads with cert trusted; asks for password from ~/pihole/pihole_password.txt.

=== LAYER -1: VPROXY ===

[ ] 10. Install vproxy:
       cargo install vproxy
       PASS: vproxy --version returns a version string.

[ ] 11. Start vproxy daemon:
       source ~/vproxy/.env
       vproxy start --bind "$VPROXY_BIND" --auth "$VPROXY_USER:$VPROXY_PASS" --type http
       PASS: vproxy ps shows the daemon running.

[ ] 12. Smoke-test vproxy:
       curl -sS -x http://$VPROXY_USER:$VPROXY_PASS@127.0.0.1:9999 https://api.ipify.org
       PASS: returns your public IP.

[ ] 13. (Optional) Register vproxy with Slim:
       slim start vproxy --port 9999

=== LAYER 1: FIREFOX ===

[ ] 14. Install Firefox:
       sudo apt install -y firefox-esr
       PASS: firefox --version returns >= 115 ESR or current stable.

[ ] 15. Launch Firefox; install Bitwarden extension; point at Vaultwarden; confirm unlock.

[ ] 16. Set Firefox DNS handling:
       about:config → network.trr.mode = 5 (defers to system DNS = Pi-hole)

[ ] 17. Pin claude.ai as always-open tab.

=== LAYER 2: BIFROST ===

[ ] 18. Set up bifrost (Docker):
       mkdir -p ~/bifrost && cd ~/bifrost
       # Write docker-compose.yml from section 5; .env already exists with API keys
       docker compose up -d
       PASS: docker ps | grep bifrost shows running on 127.0.0.1:8080.

[ ] 19. Register bifrost in Slim:
       slim start bifrost --port 8080
       PASS: slim list shows "bifrost.test → localhost:8080".

[ ] 20. Verify bifrost UI; confirm Anthropic + OpenRouter providers healthy:
       xdg-open https://bifrost.test
       PASS: UI loads; both providers show "healthy".

[ ] 21. Smoke-test bifrost via Slim:
       curl -sS https://bifrost.test/v1/chat/completions \
         -H "Content-Type: application/json" \
         -d '{"model":"anthropic/claude-3-7-sonnet-latest",
              "messages":[{"role":"user","content":"reply: bifrost"}]}' \
         | jq -r '.choices[0].message.content'
       PASS: response contains "bifrost".

=== LAYER 3: OBSCURA + PLAYWRIGHT ===

[ ] 22. Install obscura (Linux x86_64):
       cd /tmp
       curl -LO https://github.com/h4ckf0r0day/obscura/releases/latest/download/obscura-x86_64-linux.tar.gz
       tar xzf obscura-x86_64-linux.tar.gz
       sudo mv obscura /usr/local/bin/obscura
       PASS: obscura --version returns a version string.

[ ] 23. Smoke obscura standalone:
       obscura fetch https://example.com --eval "document.title"
       PASS: output contains "Example Domain".

[ ] 24. Start obscura as CDP server:
       obscura serve --port 9222 &
       PASS: curl -sS http://localhost:9222/json/version returns JSON.

[ ] 25. Register obscura in Slim:
       slim start obscura --port 9222

[ ] 26. Verify obscura via Slim:
       curl -sS https://obscura.test/json/version | jq -r .Browser
       PASS: returns a non-empty Browser string.

[ ] 27. Set up Playwright bundled-chromium fallback:
       echo 'export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright' >> ~/.profile
       source ~/.profile
       cd repos/<some-project>
       npm install -D playwright && npx playwright install chromium
       PASS: ls $PLAYWRIGHT_BROWSERS_PATH shows a chromium-* directory.

[ ] 28. Smoke Playwright → obscura via Slim:
       Save the connect_over_cdp example from section 5; run it.
       PASS: prints "Example Domain".

[ ] 29. Smoke bundled-chromium fallback:
       Save the launch_persistent_context example; run it.
       PASS: prints "Example Domain".

=== DIAGNOSTIC SIDECAR ===

[ ] 30. Install trippy:
       cargo install trippy
       sudo setcap cap_net_raw+ep $(which trip)
       PASS: trip --version returns a version string.

[ ] 31. Sanity-check trippy:
       trip api.anthropic.com -m 5 -c 3
       trip 1.1.1.1 -m 5 -c 3
       PASS: both traces complete with non-empty hops.

=== END-TO-END VERIFICATION ===

[ ] 32. Full path verification:
       firefox &
       docker ps | grep -E 'pihole|bifrost'
       vproxy ps
       slim list
       curl -sS https://pihole.test/admin > /dev/null && echo "pihole.test up"
       curl -sS https://obscura.test/json/version > /dev/null && echo "obscura.test up"
       curl -sS https://bifrost.test/v1/chat/completions ... > /dev/null && echo "bifrost.test up"
       python scripts/pw-obscura-smoke.py
       trip api.anthropic.com -m 3 -c 1 > /dev/null && echo "trippy ok"
       PASS: all checks succeed.

[ ] 33. Document recovery runbook entries:
       - Pi-hole down → sudo chattr -i /etc/resolv.conf && sudo cp /etc/resolv.conf.fallback /etc/resolv.conf
       - Slim down → use raw localhost:<port> URLs until restart
       - Bifrost down → fall back to Claude.ai web tab in Firefox
       - Obscura CDP gap on a test → switch that test to bundled chromium

[ ] 34. Done. Six-layer Slim-fronted Linux workstation is live.
```

---

## Confirmation gate

This is a decision plan. No installs, no settings.json changes, no MCP config changes were performed by writing this document.

Execution is automated via `scripts/install-v5-architecture.sh` (sibling file in this repo). Prerequisites for the script:
- `~/bifrost/.env` (chmod 600) — `ANTHROPIC_API_KEY` + `OPENROUTER_API_KEY`
- `~/pihole/pihole_password.txt` (chmod 600) — admin password
- `~/vproxy/.env` (chmod 600) — `VPROXY_USER`, `VPROXY_PASS`, `VPROXY_BIND`

Run:
```
bash scripts/install-v5-architecture.sh --dry-run   # preview
bash scripts/install-v5-architecture.sh             # full run (~30-45 min)
bash scripts/install-v5-architecture.sh --phase 2   # single phase re-run
```
