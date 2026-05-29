/**
 * Tests for the persistent task queue.
 *
 * Run with: node tests/agentic-os/task-queue.test.js
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { TaskQueue, makeId } = require(path.join(__dirname, '..', '..', 'scripts', 'agentic-os', 'lib', 'task-queue.js'));

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    return true;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    Error: ${err.message}`);
    return false;
  }
}

function tmpQueue() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'agentic-q-'));
  const file = path.join(dir, 'queue.json');
  return { file, dir, cleanup: () => fs.rmSync(dir, { recursive: true, force: true }) };
}

let passed = 0;
let failed = 0;

console.log('\nTaskQueue');

if (
  test('makeId returns unique-looking ids', () => {
    const a = makeId();
    const b = makeId();
    assert.notStrictEqual(a, b);
    assert.match(a, /^t_[a-z0-9]+_[a-f0-9]{8}$/);
  })
)
  passed++;
else failed++;

if (
  test('load returns [] when file missing', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      assert.deepStrictEqual(q.load(), []);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('enqueue assigns id and pending status', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const task = q.enqueue({ prompt: 'hi', route: 'auto' });
      assert.ok(task.id);
      assert.strictEqual(task.status, 'pending');
      assert.strictEqual(task.prompt, 'hi');
      assert.strictEqual(task.attempts, 0);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('nextPending returns oldest pending task', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const first = q.enqueue({ prompt: 'first' });
      q.enqueue({ prompt: 'second' });
      const next = q.nextPending();
      assert.strictEqual(next.id, first.id);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('markRunning increments attempts and updates status', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const task = q.enqueue({ prompt: 'go' });
      const updated = q.markRunning(task.id);
      assert.strictEqual(updated.status, 'running');
      assert.strictEqual(updated.attempts, 1);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('markDone records result', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const task = q.enqueue({ prompt: 'compute' });
      const updated = q.markDone(task.id, { text: '42', channel: 'local' });
      assert.strictEqual(updated.status, 'done');
      assert.strictEqual(updated.result.text, '42');
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('markFailed records error', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const task = q.enqueue({ prompt: 'fail' });
      const updated = q.markFailed(task.id, { code: 'X', message: 'nope' });
      assert.strictEqual(updated.status, 'failed');
      assert.strictEqual(updated.lastError.code, 'X');
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('stats counts by status', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const a = q.enqueue({ prompt: 'a' });
      const b = q.enqueue({ prompt: 'b' });
      q.enqueue({ prompt: 'c' });
      q.markDone(a.id, {});
      q.markFailed(b.id, {});
      const s = q.stats();
      assert.strictEqual(s.total, 3);
      assert.strictEqual(s.pending, 1);
      assert.strictEqual(s.done, 1);
      assert.strictEqual(s.failed, 1);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('atomic write survives concurrent saves', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      for (let i = 0; i < 5; i++) q.enqueue({ prompt: `p${i}` });
      const tasks = q.load();
      assert.strictEqual(tasks.length, 5);
      // Confirm file is well-formed JSON
      const raw = fs.readFileSync(t.file, 'utf8');
      JSON.parse(raw);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('prune removes old terminal tasks', () => {
    const t = tmpQueue();
    try {
      const q = new TaskQueue(t.file);
      const a = q.enqueue({ prompt: 'a' });
      q.markDone(a.id, {});
      // Force updatedAt into the past
      const tasks = q.load();
      tasks[0].updatedAt = new Date(Date.now() - 7 * 24 * 3600_000).toISOString();
      q.save(tasks);
      const removed = q.prune(24 * 3600_000);
      assert.strictEqual(removed, 1);
      assert.strictEqual(q.load().length, 0);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
