#!/usr/bin/env bash
#
# Bootstrap the agentic-os harness:
#   1. Clone FlexNetOS/freellmapi into ~/.agentic-os/freellmapi
#   2. npm install
#   3. Generate ENCRYPTION_KEY in .env
#   4. Copy default config to ~/.agentic-os/config.json (if missing)
#   5. Print provider key instructions
#
# Idempotent: safe to re-run. Pulls latest freellmapi if already cloned.
# User-space only — no sudo, no system services, no network changes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENTIC_DIR="${HOME}/.agentic-os"
FREELLMAPI_DIR="${AGENTIC_DIR}/freellmapi"
FREELLMAPI_REPO="https://github.com/FlexNetOS/freellmapi.git"
CONFIG_SRC="${REPO_ROOT}/config/agentic-os/default.json"
CONFIG_DST="${AGENTIC_DIR}/config.json"

echo "==> Bootstrapping agentic-os in ${AGENTIC_DIR}"
mkdir -p "${AGENTIC_DIR}"

# --- Tooling checks --------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need node
need npm
need git

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "${NODE_MAJOR}" -lt 20 ]; then
  echo "Node.js ${NODE_MAJOR}.x detected — freellmapi needs Node 20+." >&2
  echo "Use \`mise use node@20\` or \`nvm install 20\`." >&2
  exit 1
fi

# --- freellmapi clone ------------------------------------------------------
if [ ! -d "${FREELLMAPI_DIR}/.git" ]; then
  echo "==> Cloning freellmapi to ${FREELLMAPI_DIR}"
  git clone --depth 1 "${FREELLMAPI_REPO}" "${FREELLMAPI_DIR}"
else
  echo "==> freellmapi already cloned; pulling latest"
  (cd "${FREELLMAPI_DIR}" && git pull --ff-only) || echo "(pull skipped — local changes or detached HEAD)"
fi

# --- npm install -----------------------------------------------------------
echo "==> Installing freellmapi dependencies (this may take a minute)"
(cd "${FREELLMAPI_DIR}" && npm install --no-audit --no-fund)

# --- .env with encryption key ---------------------------------------------
ENV_FILE="${FREELLMAPI_DIR}/.env"
if [ ! -f "${ENV_FILE}" ]; then
  echo "==> Generating freellmapi .env with fresh ENCRYPTION_KEY"
  cp "${FREELLMAPI_DIR}/.env.example" "${ENV_FILE}" 2>/dev/null || true
  KEY="$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
  # Append or replace ENCRYPTION_KEY
  if grep -q '^ENCRYPTION_KEY=' "${ENV_FILE}" 2>/dev/null; then
    sed -i.bak "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=${KEY}|" "${ENV_FILE}"
    rm -f "${ENV_FILE}.bak"
  else
    echo "ENCRYPTION_KEY=${KEY}" >> "${ENV_FILE}"
  fi
else
  echo "==> ${ENV_FILE} already exists; leaving ENCRYPTION_KEY untouched"
fi

# --- Default harness config -----------------------------------------------
if [ ! -f "${CONFIG_DST}" ]; then
  echo "==> Installing default config at ${CONFIG_DST}"
  cp "${CONFIG_SRC}" "${CONFIG_DST}"
else
  echo "==> ${CONFIG_DST} already exists; leaving in place"
fi

# --- Provider key reminder ------------------------------------------------
cat <<'NEXT'

==================================================================
Bootstrap complete.

NEXT STEPS:

1. Start freellmapi (one-shot build, then run):
     cd ~/.agentic-os/freellmapi
     npm run build
     node server/dist/index.js
   (or `npm run dev` for hot-reload + dashboard on :5173)

2. Open the dashboard at http://localhost:5173 (dev) or :3001 (prod),
   add your provider keys (Google, Groq, Cerebras, etc.), reorder the
   fallback chain, and copy the unified API key from the Keys page.

3. Paste the key into ~/.agentic-os/config.json under
   freellmapi.apiKey, e.g.:
     "freellmapi": { "endpoint": "http://localhost:3001/v1",
                     "apiKey": "freellmapi-XXXXX" }

4. For optional cloud routing, export provider env vars:
     export ANTHROPIC_API_KEY=...
     export OPENAI_API_KEY=...
     export GEMINI_API_KEY=...

5. Smoke test:
     node scripts/agentic-os/harness.js --task "say hi" --route auto

6. Start the daemon (foreground):
     bash scripts/agentic-os/start.sh

   Or install as a user systemd service:
     ln -sf "$(pwd)/scripts/agentic-os/systemd/ecc-agentic-os.service" \
            ~/.config/systemd/user/ecc-agentic-os.service
     systemctl --user daemon-reload
     systemctl --user enable --now ecc-agentic-os.service

==================================================================
NEXT
