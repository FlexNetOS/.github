/**
 * Tests for the cost tracker.
 *
 * Run with: node tests/agentic-os/cost-tracker.test.js
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { CostTracker, estimateUsd, COST_PER_MILLION_TOKENS } = require(path.join(__dirname, '..', '..', 'scripts', 'agentic-os', 'lib', 'cost-tracker.js'));

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

function tmpLog() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'agentic-cost-'));
  const file = path.join(dir, 'cost.jsonl');
  return { file, dir, cleanup: () => fs.rmSync(dir, { recursive: true, force: true }) };
}

let passed = 0;
let failed = 0;

console.log('\nCostTracker');

if (
  test('estimateUsd matches catalog rates for haiku', () => {
    const usd = estimateUsd('claude-haiku-4-5-20251001', 1_000_000, 1_000_000);
    const expected = COST_PER_MILLION_TOKENS['claude-haiku-4-5-20251001'].input + COST_PER_MILLION_TOKENS['claude-haiku-4-5-20251001'].output;
    assert.strictEqual(usd, expected);
  })
)
  passed++;
else failed++;

if (
  test('estimateUsd returns 0 for unknown model', () => {
    assert.strictEqual(estimateUsd('does-not-exist', 1000, 1000), 0);
  })
)
  passed++;
else failed++;

if (
  test('estimateUsd returns 0 for free models marked auto', () => {
    assert.strictEqual(estimateUsd('auto', 100_000, 100_000), 0);
  })
)
  passed++;
else failed++;

if (
  test('append writes a JSONL record', () => {
    const t = tmpLog();
    try {
      const c = new CostTracker(t.file);
      c.append({ taskId: 'x1', channel: 'anthropic-haiku', provider: 'anthropic', model: 'claude-haiku-4-5-20251001', tokensIn: 100, tokensOut: 200 });
      const lines = fs.readFileSync(t.file, 'utf8').trim().split('\n');
      assert.strictEqual(lines.length, 1);
      const rec = JSON.parse(lines[0]);
      assert.strictEqual(rec.taskId, 'x1');
      assert.ok(rec.usd > 0);
      assert.ok(rec.ts);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('append respects explicit usd', () => {
    const t = tmpLog();
    try {
      const c = new CostTracker(t.file);
      c.append({ taskId: 'x', channel: 'local', model: 'auto', tokensIn: 10, tokensOut: 10, usd: 0.05 });
      const rec = JSON.parse(fs.readFileSync(t.file, 'utf8').trim());
      assert.strictEqual(rec.usd, 0.05);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('summary aggregates totals and per-channel', () => {
    const t = tmpLog();
    try {
      const c = new CostTracker(t.file);
      c.append({ channel: 'a', model: 'claude-haiku-4-5-20251001', tokensIn: 1000, tokensOut: 1000 });
      c.append({ channel: 'a', model: 'claude-haiku-4-5-20251001', tokensIn: 500, tokensOut: 500 });
      c.append({ channel: 'b', model: 'gpt-4o-mini', tokensIn: 200, tokensOut: 200 });
      const s = c.summary();
      assert.strictEqual(s.records, 3);
      assert.strictEqual(s.byChannel.a.calls, 2);
      assert.strictEqual(s.byChannel.b.calls, 1);
      assert.ok(s.totalUsd > 0);
      assert.strictEqual(s.totalTokens, 1000 + 1000 + 500 + 500 + 200 + 200);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('readAll skips malformed lines', () => {
    const t = tmpLog();
    try {
      const c = new CostTracker(t.file);
      fs.writeFileSync(t.file, JSON.stringify({ ts: 'x', channel: 'a' }) + '\nnot json\n' + JSON.stringify({ ts: 'y', channel: 'b' }) + '\n');
      const recs = c.readAll();
      assert.strictEqual(recs.length, 2);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('summary filters by `since`', () => {
    const t = tmpLog();
    try {
      const c = new CostTracker(t.file);
      const old = new Date(Date.now() - 48 * 3600_000).toISOString();
      fs.writeFileSync(t.file, JSON.stringify({ ts: old, channel: 'a', usd: 1 }) + '\n');
      c.append({ channel: 'b', model: 'auto', usd: 0.5 });
      const since = new Date(Date.now() - 1 * 3600_000).toISOString();
      const s = c.summary({ since });
      assert.strictEqual(s.records, 1);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
