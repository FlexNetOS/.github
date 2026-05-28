#!/usr/bin/env node
/*
 * open-questions-lint.js — schema validator for .omc/plans/open-questions.md.
 *
 * Part of the FlexNetOS additive reconciliation tooling. Dependency-free.
 * Every open-question entry must carry three labelled fields:
 *     **Question:**
 *     **Candidates:**
 *     **Blocker for resolution:**
 * An "entry" is a block introduced by a `### ` heading OR a `- [ ]`/`- [x]`
 * checklist item; the block runs until the next entry-introducer (or EOF).
 *
 * Exit 1 (with the offending entry's start line + the missing field name) on the
 * first violation; exit 0 and print `open-questions: OK (N entries)` when clean.
 *
 * Usage:
 *   node scripts/open-questions-lint.js [path]
 *       (default path: .omc/plans/open-questions.md)
 *   node scripts/open-questions-lint.js -h | --help
 */
'use strict';

const fs = require('fs');

const REQUIRED = ['**Question:**', '**Candidates:**', '**Blocker for resolution:**'];
const DEFAULT_PATH = '.omc/plans/open-questions.md';

function usage() {
  process.stdout.write(
    'Usage: node scripts/open-questions-lint.js [path]\n' +
    `  Validates open-questions schema (default ${DEFAULT_PATH}).\n` +
    '  Each entry (### heading or - [ ]/- [x] item) must contain:\n' +
    REQUIRED.map((r) => `    ${r}`).join('\n') + '\n' +
    '  Exit 1 with line+missing-field on violation; exit 0 when clean.\n'
  );
}

function isEntryStart(line) {
  return /^###\s+/.test(line) || /^\s*-\s+\[[ xX]\]\s+/.test(line);
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.includes('-h') || argv.includes('--help')) { usage(); process.exit(0); }
  const file = argv[0] || DEFAULT_PATH;

  if (!fs.existsSync(file)) {
    process.stderr.write(`ERROR: file not found: ${file}\n`);
    process.exit(2);
  }

  const lines = fs.readFileSync(file, 'utf8').split('\n');

  // Collect entries: { startLine (1-based), bodyLines: [] }.
  const entries = [];
  let cur = null;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (isEntryStart(line)) {
      if (cur) entries.push(cur);
      cur = { startLine: i + 1, body: [line] };
    } else if (cur) {
      cur.body.push(line);
    }
  }
  if (cur) entries.push(cur);

  if (entries.length === 0) {
    process.stderr.write(`ERROR: no entries found in ${file} (expected ### headings or - [ ] items)\n`);
    process.exit(1);
  }

  for (const e of entries) {
    const text = e.body.join('\n');
    for (const field of REQUIRED) {
      if (!text.includes(field)) {
        process.stderr.write(`${file}:${e.startLine}: entry missing required field ${field}\n`);
        process.exit(1);
      }
    }
  }

  process.stdout.write(`open-questions: OK (${entries.length} entries)\n`);
  process.exit(0);
}

main();
