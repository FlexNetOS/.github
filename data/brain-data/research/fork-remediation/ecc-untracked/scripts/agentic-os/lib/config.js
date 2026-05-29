/**
 * Config loader for the agentic-os harness.
 *
 * Resolution order:
 *   1. $ECC_AGENTIC_OS_CONFIG (absolute path)
 *   2. $HOME/.agentic-os/config.json
 *   3. ./config/agentic-os/default.json (repo default)
 *
 * Env variables override config fields:
 *   AGENTIC_LOCAL_ENDPOINT     -> localEndpoint
 *   AGENTIC_FREELLMAPI_URL     -> freellmapi.endpoint
 *   AGENTIC_FREELLMAPI_KEY     -> freellmapi.apiKey
 *   AGENTIC_BUDGET_USD         -> budget.dailyUsd
 *
 * @module scripts/agentic-os/lib/config
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_DEFAULT = path.resolve(__dirname, '..', '..', '..', 'config', 'agentic-os', 'default.json');
const USER_CONFIG = path.join(process.env.HOME || process.env.USERPROFILE || '/tmp', '.agentic-os', 'config.json');

function loadFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    throw new Error(`failed to load config ${filePath}: ${err.message}`);
  }
}

function deepMerge(base, overlay) {
  if (overlay === null || overlay === undefined) return base;
  if (typeof base !== 'object' || typeof overlay !== 'object' || Array.isArray(base) || Array.isArray(overlay)) {
    return overlay;
  }
  const out = { ...base };
  for (const key of Object.keys(overlay)) {
    if (key in base && typeof base[key] === 'object' && !Array.isArray(base[key])) {
      out[key] = deepMerge(base[key], overlay[key]);
    } else {
      out[key] = overlay[key];
    }
  }
  return out;
}

function applyEnvOverrides(config) {
  const out = JSON.parse(JSON.stringify(config));
  if (process.env.AGENTIC_LOCAL_ENDPOINT) out.localEndpoint = process.env.AGENTIC_LOCAL_ENDPOINT;
  if (process.env.AGENTIC_FREELLMAPI_URL) {
    out.freellmapi = out.freellmapi || {};
    out.freellmapi.endpoint = process.env.AGENTIC_FREELLMAPI_URL;
  }
  if (process.env.AGENTIC_FREELLMAPI_KEY) {
    out.freellmapi = out.freellmapi || {};
    out.freellmapi.apiKey = process.env.AGENTIC_FREELLMAPI_KEY;
  }
  if (process.env.AGENTIC_BUDGET_USD) {
    const usd = parseFloat(process.env.AGENTIC_BUDGET_USD);
    if (Number.isFinite(usd)) {
      out.budget = out.budget || {};
      out.budget.dailyUsd = usd;
    }
  }
  return out;
}

function loadConfig({ explicit, repoDefault = REPO_DEFAULT, userConfig = USER_CONFIG } = {}) {
  const repoBase = loadFile(repoDefault) || {};
  const userOverlay = loadFile(userConfig) || {};
  const explicitOverlay = explicit ? loadFile(explicit) || {} : {};

  let merged = deepMerge(repoBase, userOverlay);
  merged = deepMerge(merged, explicitOverlay);
  return applyEnvOverrides(merged);
}

function loadFreeModels(repoRoot) {
  const root = repoRoot || path.resolve(__dirname, '..', '..', '..');
  const fp = path.join(root, 'config', 'agentic-os', 'free-models.json');
  return loadFile(fp) || { version: 0, providers: [] };
}

module.exports = { loadConfig, loadFreeModels, deepMerge, applyEnvOverrides, REPO_DEFAULT, USER_CONFIG };
