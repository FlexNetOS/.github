/**
 * Generic state read/write for the agentic-os harness.
 *
 * Keeps data/agentic-os/*.json files atomic. Used for harness PID file,
 * sticky session map persistence, daily run summaries, and reflections.
 *
 * @module scripts/agentic-os/lib/state
 */

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DEFAULT_STATE_DIR = path.join(process.env.HOME || process.env.USERPROFILE || '/tmp', '.agentic-os');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function atomicWrite(filePath, content) {
  ensureDir(path.dirname(filePath));
  const tmp = `${filePath}.tmp.${process.pid}.${crypto.randomBytes(4).toString('hex')}`;
  fs.writeFileSync(tmp, content, 'utf8');
  fs.renameSync(tmp, filePath);
}

function readJson(filePath, fallback = null) {
  try {
    if (!fs.existsSync(filePath)) return fallback;
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (_) {
    return fallback;
  }
}

function writeJson(filePath, data) {
  atomicWrite(filePath, JSON.stringify(data, null, 2));
}

function appendLine(filePath, line) {
  ensureDir(path.dirname(filePath));
  fs.appendFileSync(filePath, line.endsWith('\n') ? line : line + '\n', 'utf8');
}

class StateStore {
  constructor(stateDir) {
    this.dir = stateDir || DEFAULT_STATE_DIR;
    ensureDir(this.dir);
  }

  pathFor(name) {
    return path.join(this.dir, name);
  }

  read(name, fallback = null) {
    return readJson(this.pathFor(name), fallback);
  }

  write(name, data) {
    writeJson(this.pathFor(name), data);
  }

  append(name, line) {
    appendLine(this.pathFor(name), line);
  }

  exists(name) {
    return fs.existsSync(this.pathFor(name));
  }

  remove(name) {
    const fp = this.pathFor(name);
    if (fs.existsSync(fp)) fs.unlinkSync(fp);
  }
}

module.exports = { StateStore, DEFAULT_STATE_DIR, readJson, writeJson, atomicWrite, appendLine };
