#!/usr/bin/env node
/*
 * claude-settings-doctor.js — REPORT-ONLY linter for Claude Code settings.json.
 *
 * Part of the FlexNetOS additive reconciliation tooling. This script NEVER
 * edits the live settings file; it only scans and reports violations so the
 * canonical-shape trim can be applied later as a gated, manual UA step.
 *
 * Violations detected:
 *   (a) Hardcoded user-home paths in any string value:
 *         ^/home/...   ^/Users/...   ^/root/...   C:\Users\...
 *       These are NEVER allowed, even if listed in an allowlist.
 *   (b) Portable-but-gated home references ($HOME/, ~/, ${HOME}/, %APPDATA%):
 *       allowed ONLY if a matching line exists in the allowlist.
 *   (c) The key env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS being present.
 *
 * Dependency-free (Node stdlib only).
 *
 * Usage:
 *   node scripts/claude-settings-doctor.js [--check] [--diff]
 *       [--config <path>] [--allowlist <path>] [--toml-allowlist <path>]
 *       [--canonical <path>]
 *
 *   --check       (default) Scan and EXIT 1 on any violation, 0 if clean.
 *   --diff        Print an informational diff against the canonical shape.
 *                 Always exits 0.
 *   --config      settings.json to scan (default: .claude/settings.json).
 *   --allowlist   Allowlist file (plaintext bare lines OR TOML `pattern =`).
 *                 (default: .claude/.doctor-allowlist)
 *   --toml-allowlist  Additional allowlist parsed as TOML `pattern =` lines.
 *   --canonical   Canonical reference shape (default: .claude/settings.canonical.json).
 *   -h, --help    Show this help.
 */
'use strict';

const fs = require('fs');
const path = require('path');

// Hardcoded absolute user-home paths. The spec anchors these at start-of-value
// (^/home/...), but the doctor's job is to surface the trim list, and the
// primary trim targets are hook commands like "node /home/<user>/.claude/...".
// So we match the marker ANYWHERE in the value (word-boundary-ish: preceded by
// start, whitespace, quote, '=' or ':') and capture the path token. This still
// catches the start-of-value case the spec names. These are NEVER allowlistable.
const HARDCODED_PATTERNS = [
  { name: '/home/ absolute path', re: /(^|[\s"'(=:])\/home\/\S+/ },
  { name: '/Users/ absolute path', re: /(^|[\s"'(=:])\/Users\/\S+/ },
  { name: '/root/ absolute path', re: /(^|[\s"'(=:])\/root\/\S+/ },
  { name: 'C:\\Users\\ absolute path', re: /(^|[\s"'(=:])C:\\Users\\\S+/i },
];

// Portable home references — allowed only if present in the allowlist.
const GATED_PATTERNS = [
  { name: '$HOME/ reference', re: /\$HOME\// },
  { name: '${HOME}/ reference', re: /\$\{HOME\}\// },
  { name: '~/ reference', re: /(^|[\s"'(=:])~\// },
  { name: '%APPDATA% reference', re: /%APPDATA%/i },
];

const FORBIDDEN_KEYS = ['env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'];

function usage() {
  const src = fs.readFileSync(__filename, 'utf8');
  const block = src.split('\n').filter((l) => l.startsWith(' *') || l.startsWith('/*'));
  process.stdout.write(block.join('\n').replace(/^\/\*\s*/, '').replace(/\s*\*\//, '') + '\n');
}

function parseArgs(argv) {
  const args = {
    mode: 'check',
    config: '.claude/settings.json',
    allowlist: '.claude/.doctor-allowlist',
    tomlAllowlist: null,
    canonical: '.claude/settings.canonical.json',
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--check': args.mode = 'check'; break;
      case '--diff': args.mode = 'diff'; break;
      case '--config': args.config = argv[++i]; break;
      case '--allowlist': args.allowlist = argv[++i]; break;
      case '--toml-allowlist': args.tomlAllowlist = argv[++i]; break;
      case '--canonical': args.canonical = argv[++i]; break;
      case '-h':
      case '--help': usage(); process.exit(0); break;
      default:
        process.stderr.write(`Unknown arg: ${a}\n`);
        usage();
        process.exit(2);
    }
  }
  return args;
}

// Parse an allowlist file. Plaintext: bare non-comment lines. TOML: `pattern = "..."`.
function loadAllowlist(file) {
  const patterns = [];
  if (!file || !fs.existsSync(file)) return patterns;
  const text = fs.readFileSync(file, 'utf8');
  for (let line of text.split('\n')) {
    const trimmed = line.trim();
    if (trimmed === '' || trimmed.startsWith('#')) continue;
    // TOML `pattern = "value"` (also tolerate single quotes / no quotes).
    const m = trimmed.match(/^pattern\s*=\s*(.+)$/);
    if (m) {
      let v = m[1].trim();
      // strip surrounding quotes
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1);
      }
      // drop trailing inline comment for unquoted forms
      v = v.replace(/\s+#.*$/, '').trim();
      if (v) patterns.push(v);
      continue;
    }
    // Skip other TOML structural lines (tables, rationale = ..., etc.)
    if (/^[A-Za-z_][A-Za-z0-9_]*\s*=/.test(trimmed)) continue;
    if (trimmed.startsWith('[')) continue;
    // Plaintext bare line.
    patterns.push(trimmed);
  }
  return patterns;
}

function isAllowlisted(value, allow) {
  return allow.some((p) => value.includes(p));
}

// Walk every string value, yielding { keyPath, value }.
function walkStrings(node, keyPath, out) {
  if (typeof node === 'string') {
    out.push({ keyPath, value: node });
  } else if (Array.isArray(node)) {
    node.forEach((v, i) => walkStrings(v, `${keyPath}[${i}]`, out));
  } else if (node && typeof node === 'object') {
    for (const k of Object.keys(node)) {
      walkStrings(node[k], keyPath ? `${keyPath}.${k}` : k, out);
    }
  }
}

function keyExists(obj, dottedPath) {
  const parts = dottedPath.split('.');
  let cur = obj;
  for (const p of parts) {
    if (cur && typeof cur === 'object' && Object.prototype.hasOwnProperty.call(cur, p)) {
      cur = cur[p];
    } else {
      return false;
    }
  }
  return true;
}

function check(args) {
  if (!fs.existsSync(args.config)) {
    process.stderr.write(`ERROR: config not found: ${args.config}\n`);
    return 2;
  }
  let settings;
  try {
    settings = JSON.parse(fs.readFileSync(args.config, 'utf8'));
  } catch (e) {
    process.stderr.write(`ERROR: ${args.config} is not valid JSON: ${e.message}\n`);
    return 2;
  }

  const allow = [
    ...loadAllowlist(args.allowlist),
    ...loadAllowlist(args.tomlAllowlist),
  ];

  const strings = [];
  walkStrings(settings, '', strings);

  const violations = [];

  for (const { keyPath, value } of strings) {
    // (a) Hardcoded absolute user paths — never allowed.
    let hardcoded = false;
    for (const pat of HARDCODED_PATTERNS) {
      if (pat.re.test(value)) {
        violations.push(`${keyPath}: hardcoded user-home path (${pat.name}) -> ${value}`);
        hardcoded = true;
        break;
      }
    }
    if (hardcoded) continue;
    // (b) Gated portable refs — allowed only if allowlisted.
    for (const pat of GATED_PATTERNS) {
      if (pat.re.test(value) && !isAllowlisted(value, allow)) {
        violations.push(`${keyPath}: ungated ${pat.name} (not in allowlist) -> ${value}`);
      }
    }
  }

  // (c) Forbidden keys.
  for (const fk of FORBIDDEN_KEYS) {
    if (keyExists(settings, fk)) {
      violations.push(`${fk}: forbidden key present`);
    }
  }

  if (violations.length === 0) {
    process.stdout.write(`claude-settings-doctor: OK (${args.config} clean, ${strings.length} strings scanned)\n`);
    return 0;
  }
  process.stdout.write(`claude-settings-doctor: ${violations.length} violation(s) in ${args.config}\n`);
  for (const v of violations) process.stdout.write(`  - ${v}\n`);
  return 1;
}

function diff(args) {
  if (!fs.existsSync(args.config)) {
    process.stderr.write(`ERROR: config not found: ${args.config}\n`);
    return 0; // diff is informational
  }
  if (!fs.existsSync(args.canonical)) {
    process.stderr.write(`ERROR: canonical not found: ${args.canonical}\n`);
    return 0;
  }
  let live, canon;
  try { live = JSON.parse(fs.readFileSync(args.config, 'utf8')); }
  catch (e) { process.stderr.write(`ERROR: live not JSON: ${e.message}\n`); return 0; }
  try { canon = JSON.parse(fs.readFileSync(args.canonical, 'utf8')); }
  catch (e) { process.stderr.write(`ERROR: canonical not JSON: ${e.message}\n`); return 0; }

  const liveKeys = Object.keys(live).filter((k) => k !== '_README');
  const canonKeys = Object.keys(canon).filter((k) => k !== '_README');

  const extra = liveKeys.filter((k) => !canonKeys.includes(k));
  const missing = canonKeys.filter((k) => !liveKeys.includes(k));

  // Reuse the check logic to count violations informationally.
  const strings = [];
  walkStrings(live, '', strings);
  const allow = [...loadAllowlist(args.allowlist), ...loadAllowlist(args.tomlAllowlist)];
  let vcount = 0;
  for (const { value } of strings) {
    if (HARDCODED_PATTERNS.some((p) => p.re.test(value))) { vcount++; continue; }
    if (GATED_PATTERNS.some((p) => p.re.test(value)) && !isAllowlisted(value, allow)) vcount++;
  }
  for (const fk of FORBIDDEN_KEYS) if (keyExists(live, fk)) vcount++;

  process.stdout.write(`claude-settings-doctor --diff (live=${args.config} vs canonical=${args.canonical})\n\n`);
  process.stdout.write('Top-level keys in live NOT in canonical (trim candidates):\n');
  process.stdout.write(extra.length ? extra.map((k) => `  + ${k}`).join('\n') + '\n' : '  (none)\n');
  process.stdout.write('\nCanonical keys MISSING from live:\n');
  process.stdout.write(missing.length ? missing.map((k) => `  - ${k}`).join('\n') + '\n' : '  (none)\n');
  process.stdout.write(`\nDetected violations (informational): ${vcount}\n`);
  return 0;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.mode === 'diff') process.exit(diff(args));
  process.exit(check(args));
}

main();
