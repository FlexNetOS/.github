#!/usr/bin/env bash
#
# install-v5-architecture.sh — execute Section 9 of .omc/plans/ralplan-browser-choice.md (v5)
#
# Six-layer workstation architecture:
#   Layer -2: Pi-hole + dnscrypt-proxy + Cloudflare/Quad9 (NextDNS skipped per user)
#   Layer -1: vproxy (outbound forward proxy, opt-in)
#   Layer  0: Slim (local DNS + HTTPS reverse proxy for *.test)
#   Layer  1: Firefox (daily browser)
#   Layer  2: Bifrost (LLM gateway, Docker, configured with Anthropic + OpenRouter)
#   Layer  3: Obscura (Playwright automation) + Playwright bundled-chromium fallback
#   Sidecar:  trippy (network diagnostics)
#
# Prerequisites (must exist before running):
#   ~/bifrost/.env                  (chmod 600, ANTHROPIC_API_KEY + OPENROUTER_API_KEY)
#   ~/pihole/pihole_password.txt    (chmod 600, single line with admin password)
#   ~/vproxy/.env                   (chmod 600, VPROXY_USER + VPROXY_PASS + VPROXY_BIND)
#
# Usage:
#   bash scripts/install-v5-architecture.sh             # run all phases
#   bash scripts/install-v5-architecture.sh --phase 2   # run only phase 2 (DNS)
#   bash scripts/install-v5-architecture.sh --dry-run   # print actions, don't execute
#
# Safety:
#   - DNS swap only happens after verifying Pi-hole responds; if Pi-hole is silent,
#     the script aborts BEFORE touching /etc/resolv.conf (you keep working DNS).
#   - All long-running installs go to a log file you can tail.
#   - You will be prompted for sudo several times. The script does NOT cache credentials.
#
# Idempotency:
#   - Re-running is safe: package installs use apt-get install -y (no-op if installed),
#     `slim start <name>` is idempotent, `docker compose up -d` reconciles state.
#
# Post-execution:
#   - Rotate Anthropic + OpenRouter API keys at console.anthropic.com and openrouter.ai
#     (they were pasted into the chat transcript and should be considered compromised).

set -euo pipefail

# --------------------------- parameters ---------------------------

DRY_RUN=0
ONLY_PHASE=""
TZ_NAME="${TZ_NAME:-America/Los_Angeles}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --phase) ONLY_PHASE="$2"; shift 2 ;;
    --tz) TZ_NAME="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

LOG_DIR="$HOME/.cache/v5-install-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG_FILE" >&2; }
die()  { log "FAIL: $*"; exit 1; }
do_or_dry() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY: $*"
  else
    eval "$@"
  fi
}
should_run_phase() {
  [[ -z "$ONLY_PHASE" || "$ONLY_PHASE" == "$1" ]]
}

# --------------------------- phase 0: prereqs ---------------------------

log "=== Phase 0: prerequisite checks ==="

for f in "$HOME/bifrost/.env" "$HOME/pihole/pihole_password.txt" "$HOME/vproxy/.env"; do
  [[ -f "$f" ]] || die "missing prerequisite file: $f"
  perm=$(stat -c '%a' "$f")
  [[ "$perm" == "600" ]] || die "$f has perms $perm, expected 600 (chmod 600 $f)"
done

# Validate bifrost .env actually contains the keys without echoing values
grep -q '^ANTHROPIC_API_KEY=sk-ant-'   "$HOME/bifrost/.env" || die "~/bifrost/.env missing ANTHROPIC_API_KEY"
grep -q '^OPENROUTER_API_KEY=sk-or-v1-' "$HOME/bifrost/.env" || die "~/bifrost/.env missing OPENROUTER_API_KEY"

command -v sudo  >/dev/null || die "sudo required"
command -v curl  >/dev/null || die "curl required (sudo apt install curl)"
command -v cargo >/dev/null || die "cargo required (install via rustup: https://rustup.rs)"

log "prereqs OK"

# --------------------------- phase 1: install packages ---------------------------

if should_run_phase 1; then
  log "=== Phase 1: install packages (serialized, ~15-30 min) ==="

  do_or_dry "sudo apt-get update"
  do_or_dry "sudo apt-get install -y firefox-esr dnscrypt-proxy dnsutils jq gnupg ca-certificates lsb-release openssl"

  if ! command -v docker >/dev/null; then
    log "installing docker.io"
    do_or_dry "sudo apt-get install -y docker.io docker-compose-plugin"
    do_or_dry "sudo systemctl enable --now docker"
    do_or_dry "sudo usermod -aG docker $USER"
    log "NOTE: log out and back in for docker group, or run: newgrp docker"
  else
    log "docker already installed: $(docker --version)"
  fi

  if ! command -v vproxy >/dev/null; then
    log "installing vproxy via cargo"
    do_or_dry "cargo install vproxy"
  fi

  if ! command -v trip >/dev/null; then
    log "installing trippy via cargo (binary: trip)"
    do_or_dry "cargo install trippy"
    do_or_dry "sudo setcap cap_net_raw+ep $(command -v trip || echo /no-trip-yet)"
  fi

  if ! command -v slim >/dev/null; then
    log "installing Slim"
    do_or_dry "curl -sL https://slim.sh/install.sh | sh"
  fi

  if ! command -v obscura >/dev/null; then
    log "installing obscura"
    do_or_dry "cd /tmp && curl -fLo obscura.tgz https://github.com/h4ckf0r0day/obscura/releases/latest/download/obscura-x86_64-linux.tar.gz"
    do_or_dry "cd /tmp && tar xzf obscura.tgz"
    do_or_dry "sudo mv /tmp/obscura /usr/local/bin/obscura"
    do_or_dry "rm -f /tmp/obscura.tgz"
  fi

  log "pulling docker images (Pi-hole, Bifrost)"
  do_or_dry "docker pull pihole/pihole:latest"
  do_or_dry "docker pull maximhq/bifrost:latest"

  log "Phase 1 complete"
fi

# --------------------------- phase 2: DNS layer ---------------------------

if should_run_phase 2; then
  log "=== Phase 2: DNS layer (dnscrypt-proxy -> Cloudflare/Quad9; Pi-hole on :53) ==="

  if [[ -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml && ! -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml.preinstall ]]; then
    do_or_dry "sudo cp /etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml.preinstall"
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    sudo tee /etc/dnscrypt-proxy/dnscrypt-proxy.toml >/dev/null <<'DNSEOF'
# Generated by install-v5-architecture.sh
# Upstream: Cloudflare + Quad9 (DNSCrypt). NextDNS skipped at user request.
listen_addresses = ['127.0.0.1:5353']
server_names = ['cloudflare', 'quad9-dnscrypt-ip4-filter-pri']
require_dnssec = true
require_nofilter = false
ipv6_servers = false
cache = true
cache_size = 1024
log_level = 2

[sources]
[sources.public-resolvers]
url = 'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md'
cache_file = '/var/cache/dnscrypt-proxy/public-resolvers.md'
minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
prefix = ''
DNSEOF
  fi

  do_or_dry "sudo systemctl enable --now dnscrypt-proxy"
  sleep 3

  if [[ $DRY_RUN -eq 0 ]]; then
    if ! dig @127.0.0.1 -p 5353 example.com +short +time=5 +tries=1 >/dev/null 2>&1; then
      die "dnscrypt-proxy on :5353 not responding — check 'sudo systemctl status dnscrypt-proxy'"
    fi
  fi
  log "dnscrypt-proxy OK on 127.0.0.1:5353"

  if ss -tlnp 2>/dev/null | awk '{print $4}' | grep -E '(^|:)53$' >/dev/null; then
    log "freeing port 53 from systemd-resolved stub listener"
    do_or_dry "sudo mkdir -p /etc/systemd/resolved.conf.d"
    if [[ $DRY_RUN -eq 0 ]]; then
      sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf >/dev/null <<'SDEOF'
[Resolve]
DNSStubListener=no
SDEOF
    fi
    do_or_dry "sudo systemctl restart systemd-resolved"
    sleep 2
  fi

  mkdir -p "$HOME/pihole/etc-pihole" "$HOME/pihole/etc-dnsmasq.d"
  PIHOLE_PASS=$(cat "$HOME/pihole/pihole_password.txt")
  if [[ $DRY_RUN -eq 0 ]]; then
    cat > "$HOME/pihole/docker-compose.yml" <<DCEOF
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
      TZ: "${TZ_NAME}"
      WEBPASSWORD: "${PIHOLE_PASS}"
      PIHOLE_DNS_: "127.0.0.1#5353"
      DNSMASQ_LISTENING: "local"
      DNSSEC: "true"
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
DCEOF
  fi

  do_or_dry "cd $HOME/pihole && docker compose up -d"
  sleep 8

  if [[ $DRY_RUN -eq 0 ]]; then
    if ! dig @127.0.0.1 example.com +short +time=5 +tries=1 >/dev/null 2>&1; then
      die "Pi-hole on 127.0.0.1:53 silent — ABORTING DNS swap; /etc/resolv.conf untouched. Check 'docker logs pihole'."
    fi
  fi
  log "Pi-hole responding on 127.0.0.1:53"

  if [[ $DRY_RUN -eq 0 ]]; then
    echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf.fallback >/dev/null
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    sudo rm -f /etc/resolv.conf
    echo 'nameserver 127.0.0.1' | sudo tee /etc/resolv.conf >/dev/null
    sudo chattr +i /etc/resolv.conf 2>/dev/null || true
  fi
  log "DNS swap complete: workstation -> Pi-hole -> dnscrypt-proxy -> Cloudflare/Quad9"
  log "RECOVERY: 'sudo chattr -i /etc/resolv.conf && sudo cp /etc/resolv.conf.fallback /etc/resolv.conf'"
fi

# --------------------------- phase 3: vproxy ---------------------------

if should_run_phase 3; then
  log "=== Phase 3: vproxy (outbound forward proxy, daemonized) ==="
  set -a
  # shellcheck source=/dev/null
  source "$HOME/vproxy/.env"
  set +a
  if vproxy ps 2>/dev/null | grep -q running; then
    log "vproxy already running"
  else
    do_or_dry "vproxy start --bind '$VPROXY_BIND' --auth '$VPROXY_USER:$VPROXY_PASS' --type http"
    sleep 2
  fi
  log "vproxy listening on $VPROXY_BIND"
fi

# --------------------------- phase 4: Slim hostnames ---------------------------

if should_run_phase 4; then
  log "=== Phase 4: Slim hostnames ==="
  do_or_dry "slim start pihole  --port 8053 || true"
  do_or_dry "slim start vproxy  --port 9999 || true"
fi

# --------------------------- phase 5: bifrost ---------------------------

if should_run_phase 5; then
  log "=== Phase 5: bifrost (LLM gateway, Docker) ==="

  if [[ $DRY_RUN -eq 0 ]]; then
    cat > "$HOME/bifrost/docker-compose.yml" <<'BFEOF'
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
      - .env
BFEOF
  fi

  do_or_dry "cd $HOME/bifrost && docker compose up -d"
  sleep 10
  do_or_dry "slim start bifrost --port 8080 || true"

  log "bifrost up at https://bifrost.test ; configure providers via Web UI if not auto-detected"

  if [[ $DRY_RUN -eq 0 ]]; then
    sleep 5
    response=$(curl -sS --max-time 30 https://bifrost.test/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"model":"anthropic/claude-3-7-sonnet-latest","messages":[{"role":"user","content":"reply: bifrost"}]}' 2>/dev/null || echo '{}')
    if echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null | grep -qi bifrost; then
      log "bifrost smoke test OK (Anthropic responded)"
    else
      log "WARN: bifrost smoke test inconclusive — open https://bifrost.test and verify providers configured"
    fi
  fi
fi

# --------------------------- phase 6: obscura ---------------------------

if should_run_phase 6; then
  log "=== Phase 6: obscura CDP server ==="
  mkdir -p "$HOME/.cache/obscura"
  if pgrep -fa "obscura serve" >/dev/null; then
    log "obscura serve already running"
  else
    do_or_dry "nohup obscura serve --port 9222 > $HOME/.cache/obscura/serve.log 2>&1 &"
    sleep 3
  fi
  if [[ $DRY_RUN -eq 0 ]]; then
    curl -sS --max-time 5 http://localhost:9222/json/version >/dev/null || die "obscura CDP not responding on :9222 — check $HOME/.cache/obscura/serve.log"
  fi
  do_or_dry "slim start obscura --port 9222 || true"
  log "obscura CDP responding; reachable at https://obscura.test"
fi

# --------------------------- phase 7: Playwright env ---------------------------

if should_run_phase 7; then
  log "=== Phase 7: Playwright shared browser cache ==="
  if ! grep -q PLAYWRIGHT_BROWSERS_PATH "$HOME/.profile"; then
    echo 'export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright' >> "$HOME/.profile"
    log "added PLAYWRIGHT_BROWSERS_PATH to ~/.profile (source it or open a new shell)"
  fi
  mkdir -p "$HOME/.cache/ms-playwright"
  log "Playwright browser cache at \$HOME/.cache/ms-playwright"
  log "NOTE: install bundled chromium per-repo with 'npx playwright install chromium' or 'python -m playwright install chromium'"
fi

# --------------------------- end-to-end status ---------------------------

if should_run_phase e2e || [[ -z "$ONLY_PHASE" ]]; then
  log "=== End-to-end status ==="
  echo ""
  echo "--- Docker ---"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null | grep -E 'pihole|bifrost' || echo "(no containers visible — may need newgrp docker)"
  echo ""
  echo "--- vproxy ---"
  vproxy ps 2>/dev/null | head -5 || echo "(vproxy ps unavailable)"
  echo ""
  echo "--- Slim registry ---"
  slim list 2>/dev/null || echo "(slim list unavailable)"
  echo ""
  echo "--- DNS smoke ---"
  dig example.com +short +time=3 +tries=1 | head -3 || echo "(dig failed — Pi-hole may be down; recovery: sudo chattr -i /etc/resolv.conf && sudo cp /etc/resolv.conf.fallback /etc/resolv.conf)"
  echo ""
  echo "============================================================"
  echo "  v5 architecture installation done."
  echo "============================================================"
  echo ""
  echo "  Pi-hole admin:   https://pihole.test/admin"
  echo "                   password = cat ~/pihole/pihole_password.txt"
  echo "  Bifrost UI:      https://bifrost.test"
  echo "  Obscura CDP:     https://obscura.test/json/version"
  echo "  vproxy (opt-in): http://127.0.0.1:9999  (basic auth from ~/vproxy/.env)"
  echo ""
  echo "  Diagnostic:      trip api.anthropic.com -m 5 -c 3"
  echo "  Log file:        $LOG_FILE"
  echo ""
  echo "  >>> SECURITY: rotate your Anthropic + OpenRouter API keys NOW."
  echo "  >>> They were pasted into the chat transcript and should be considered compromised."
  echo "  >>> https://console.anthropic.com  and  https://openrouter.ai/keys"
  echo ""
fi
