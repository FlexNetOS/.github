/**
 * Persistent task queue for the agentic-os harness.
 *
 * Tasks are stored as a JSON array on disk so they survive session restarts.
 * Atomic writes (tmp file + rename) prevent corruption on crash.
 *
 * Task shape:
 *   {
 *     id: string,           // ULID-like timestamp + random
 *     route: string,        // 'auto' | 'fast' | 'deep' | 'free-only'
 *     prompt: string,       // the task prompt
 *     status: 'pending' | 'running' | 'done' | 'failed',
 *     createdAt: ISO8601,
 *     updatedAt: ISO8601,
 *     attempts: number,
 *     lastError: { code, message } | null,
 *     result: { text, channel, usage } | null,
 *     sticky: string | null,
 *   }
 *
 * @module scripts/agentic-os/lib/task-queue
 */

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DEFAULT_QUEUE_PATH = path.join(process.env.HOME || process.env.USERPROFILE || '/tmp', '.agentic-os', 'queue.json');

function makeId() {
  const ts = Date.now().toString(36);
  const rand = crypto.randomBytes(4).toString('hex');
  return `t_${ts}_${rand}`;
}

function nowIso() {
  return new Date().toISOString();
}

class TaskQueue {
  constructor(queuePath) {
    this.path = queuePath || DEFAULT_QUEUE_PATH;
    this.ensureDir();
  }

  ensureDir() {
    const dir = path.dirname(this.path);
    fs.mkdirSync(dir, { recursive: true });
  }

  load() {
    try {
      if (!fs.existsSync(this.path)) return [];
      const raw = fs.readFileSync(this.path, 'utf8');
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }

  save(tasks) {
    const tmp = `${this.path}.tmp.${process.pid}.${crypto.randomBytes(4).toString('hex')}`;
    fs.writeFileSync(tmp, JSON.stringify(tasks, null, 2), 'utf8');
    fs.renameSync(tmp, this.path);
  }

  enqueue(task) {
    const tasks = this.load();
    const full = {
      id: task.id || makeId(),
      route: task.route || 'auto',
      prompt: task.prompt || '',
      status: 'pending',
      createdAt: nowIso(),
      updatedAt: nowIso(),
      attempts: 0,
      lastError: null,
      result: null,
      sticky: task.sticky || null,
      ...task
    };
    tasks.push(full);
    this.save(tasks);
    return full;
  }

  nextPending() {
    const tasks = this.load();
    return tasks.find(t => t.status === 'pending') || null;
  }

  update(id, patch) {
    const tasks = this.load();
    const idx = tasks.findIndex(t => t.id === id);
    if (idx === -1) return null;
    tasks[idx] = { ...tasks[idx], ...patch, updatedAt: nowIso() };
    this.save(tasks);
    return tasks[idx];
  }

  markRunning(id) {
    return this.update(id, { status: 'running', attempts: (this.get(id)?.attempts || 0) + 1 });
  }

  markDone(id, result) {
    return this.update(id, { status: 'done', result });
  }

  markFailed(id, error) {
    return this.update(id, { status: 'failed', lastError: error });
  }

  get(id) {
    return this.load().find(t => t.id === id) || null;
  }

  list(filter = {}) {
    let tasks = this.load();
    if (filter.status) tasks = tasks.filter(t => t.status === filter.status);
    if (typeof filter.limit === 'number') tasks = tasks.slice(0, filter.limit);
    return tasks;
  }

  prune(olderThanMs) {
    const cutoff = Date.now() - olderThanMs;
    const tasks = this.load();
    const kept = tasks.filter(t => {
      if (t.status !== 'done' && t.status !== 'failed') return true;
      const ts = Date.parse(t.updatedAt);
      return !Number.isFinite(ts) || ts > cutoff;
    });
    if (kept.length !== tasks.length) this.save(kept);
    return tasks.length - kept.length;
  }

  clear() {
    this.save([]);
  }

  stats() {
    const tasks = this.load();
    return {
      total: tasks.length,
      pending: tasks.filter(t => t.status === 'pending').length,
      running: tasks.filter(t => t.status === 'running').length,
      done: tasks.filter(t => t.status === 'done').length,
      failed: tasks.filter(t => t.status === 'failed').length
    };
  }
}

module.exports = { TaskQueue, makeId, DEFAULT_QUEUE_PATH };
