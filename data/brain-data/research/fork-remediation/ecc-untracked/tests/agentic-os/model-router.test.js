/**
 * Tests for the agentic-os model router.
 *
 * The router picks an upstream model/provider channel for each task,
 * tracks health (cooldowns on 429/5xx), enforces budget ceilings, and
 * honors sticky sessions so multi-turn flows stay on one model.
 *
 * Run with: node tests/agentic-os/model-router.test.js
 */

const assert = require('assert');
const path = require('path');

const { ModelRouter, RouterError } = require(path.join(__dirname, '..', '..', 'scripts', 'agentic-os', 'lib', 'model-router.js'));

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    return true;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    Error: ${err.message}`);
    if (err.stack) console.log(err.stack.split('\n').slice(1, 4).join('\n'));
    return false;
  }
}

const baseConfig = {
  localEndpoint: null,
  freellmapi: { endpoint: 'http://localhost:3001/v1', apiKey: 'freellmapi-test' },
  cloud: {
    anthropic: { enabled: true, apiKeyEnv: 'TEST_ANTHROPIC_KEY', models: ['claude-haiku-4-5-20251001', 'claude-sonnet-4-6'] },
    openai: { enabled: true, apiKeyEnv: 'TEST_OPENAI_KEY', models: ['gpt-4o-mini'] },
    gemini: { enabled: false, apiKeyEnv: 'TEST_GEMINI_KEY', models: ['gemini-2.5-flash'] }
  },
  routes: {
    auto: ['local', 'freellmapi-free', 'anthropic-haiku', 'openai-mini'],
    'free-only': ['local', 'freellmapi-free'],
    deep: ['anthropic-sonnet', 'openai-mini']
  },
  budget: { dailyUsd: 5.0, perTaskMaxTokens: 4000 },
  stickyTtlMs: 1800000
};

function makeRouter(overrides = {}) {
  const cfg = { ...baseConfig, ...overrides };
  process.env.TEST_ANTHROPIC_KEY = 'sk-ant-test';
  process.env.TEST_OPENAI_KEY = 'sk-test';
  return new ModelRouter(cfg, { now: () => 1_700_000_000_000 });
}

let passed = 0;
let failed = 0;

console.log('\nModelRouter');

if (
  test('exports ModelRouter and RouterError', () => {
    assert.strictEqual(typeof ModelRouter, 'function');
    assert.strictEqual(typeof RouterError, 'function');
  })
)
  passed++;
else failed++;

if (
  test('skips local channel when localEndpoint is null', () => {
    const r = makeRouter();
    const choice = r.pick({ id: 't1', route: 'auto' });
    assert.notStrictEqual(choice.channel, 'local', 'local should be skipped when endpoint missing');
    assert.strictEqual(choice.channel, 'freellmapi-free');
    assert.strictEqual(choice.baseUrl, 'http://localhost:3001/v1');
    assert.strictEqual(choice.apiKey, 'freellmapi-test');
  })
)
  passed++;
else failed++;

if (
  test('uses local channel when localEndpoint configured', () => {
    const r = makeRouter({ localEndpoint: 'http://localhost:11434/v1' });
    const choice = r.pick({ id: 't2', route: 'auto' });
    assert.strictEqual(choice.channel, 'local');
    assert.strictEqual(choice.baseUrl, 'http://localhost:11434/v1');
    assert.strictEqual(choice.isLocal, true);
  })
)
  passed++;
else failed++;

if (
  test('falls back to next channel after recording failure', () => {
    const r = makeRouter();
    const first = r.pick({ id: 't3', route: 'auto' });
    assert.strictEqual(first.channel, 'freellmapi-free');
    r.recordFailure(first, { status: 429, reason: 'rate limited' });
    const second = r.pick({ id: 't3-retry', route: 'auto' });
    assert.notStrictEqual(second.channel, 'freellmapi-free', 'failed channel should be skipped');
    assert.strictEqual(second.channel, 'anthropic-haiku');
  })
)
  passed++;
else failed++;

if (
  test('sticky session pins task to first chosen channel', () => {
    const r = makeRouter();
    const first = r.pick({ id: 'session-a', route: 'auto', sticky: 'session-a' });
    const again = r.pick({ id: 'session-a', route: 'auto', sticky: 'session-a' });
    assert.strictEqual(first.channel, again.channel, 'sticky session should reuse channel');
    assert.strictEqual(first.model, again.model);
  })
)
  passed++;
else failed++;

if (
  test('free-only route never selects paid cloud channels', () => {
    const r = makeRouter({ localEndpoint: null });
    const choice = r.pick({ id: 't4', route: 'free-only' });
    assert.strictEqual(choice.channel, 'freellmapi-free');
    r.recordFailure(choice, { status: 500 });
    let thrown;
    try {
      r.pick({ id: 't4-retry', route: 'free-only' });
    } catch (err) {
      thrown = err;
    }
    assert.ok(thrown instanceof RouterError, 'expected RouterError when free-only exhausted');
    assert.match(thrown.message, /no healthy channels/i);
  })
)
  passed++;
else failed++;

if (
  test('budget exceeded forces free-tier fallback', () => {
    const r = makeRouter({ budget: { dailyUsd: 0.01, perTaskMaxTokens: 4000 } });
    r.recordSuccess({ channel: 'anthropic-haiku', provider: 'anthropic', model: 'claude-haiku-4-5-20251001' }, { tokensIn: 100, tokensOut: 100, usd: 0.02 });
    const choice = r.pick({ id: 't5', route: 'auto', allowPaid: true });
    assert.ok(['local', 'freellmapi-free'].includes(choice.channel), `budget exceeded must downgrade to free, got ${choice.channel}`);
  })
)
  passed++;
else failed++;

if (
  test('disabled cloud providers are not selectable', () => {
    const r = makeRouter();
    // gemini is disabled in baseConfig — should never appear even in deep route
    for (let i = 0; i < 5; i++) {
      const choice = r.pick({ id: `gemini-${i}`, route: 'deep' });
      assert.notStrictEqual(choice.provider, 'gemini', 'disabled provider must not be selected');
    }
  })
)
  passed++;
else failed++;

if (
  test('reports health summary across channels', () => {
    const r = makeRouter();
    const choice = r.pick({ id: 't6', route: 'auto' });
    r.recordFailure(choice, { status: 429 });
    const health = r.health();
    assert.ok(Array.isArray(health.channels), 'health.channels should be array');
    const failedCh = health.channels.find(c => c.channel === choice.channel);
    assert.ok(failedCh, 'failed channel should appear in health summary');
    assert.strictEqual(failedCh.status, 'cooldown', 'failed channel should be in cooldown');
  })
)
  passed++;
else failed++;

if (
  test('cooldown expires after cooldownMs elapsed', () => {
    let nowMs = 1_700_000_000_000;
    const r = new ModelRouter({ ...baseConfig, cooldownMs: 1000 }, { now: () => nowMs });
    const first = r.pick({ id: 't7', route: 'auto' });
    r.recordFailure(first, { status: 429 });
    nowMs += 2000; // advance past cooldown
    const reused = r.pick({ id: 't7b', route: 'auto' });
    assert.strictEqual(reused.channel, first.channel, 'channel should recover after cooldown');
  })
)
  passed++;
else failed++;

if (
  test('unknown route name throws RouterError', () => {
    const r = makeRouter();
    let thrown;
    try {
      r.pick({ id: 't8', route: 'no-such-route' });
    } catch (err) {
      thrown = err;
    }
    assert.ok(thrown instanceof RouterError);
    assert.match(thrown.message, /unknown route/i);
  })
)
  passed++;
else failed++;

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
