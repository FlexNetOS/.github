/**
 * Tests for the config loader.
 *
 * Run with: node tests/agentic-os/config.test.js
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { loadConfig, deepMerge, applyEnvOverrides, loadFreeModels } = require(path.join(__dirname, '..', '..', 'scripts', 'agentic-os', 'lib', 'config.js'));

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

function tmpDir() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'agentic-cfg-'));
  return { dir, cleanup: () => fs.rmSync(dir, { recursive: true, force: true }) };
}

function write(file, obj) {
  fs.writeFileSync(file, JSON.stringify(obj, null, 2));
}

let passed = 0;
let failed = 0;

console.log('\nConfig loader');

if (
  test('deepMerge overlays nested objects without replacing siblings', () => {
    const base = { a: 1, nested: { b: 2, c: 3 } };
    const overlay = { nested: { c: 30 } };
    const merged = deepMerge(base, overlay);
    assert.deepStrictEqual(merged, { a: 1, nested: { b: 2, c: 30 } });
  })
)
  passed++;
else failed++;

if (
  test('deepMerge replaces arrays whole', () => {
    const merged = deepMerge({ list: [1, 2, 3] }, { list: [4] });
    assert.deepStrictEqual(merged.list, [4]);
  })
)
  passed++;
else failed++;

if (
  test('loadConfig falls back to repoDefault when user file missing', () => {
    const t = tmpDir();
    try {
      const repoDefault = path.join(t.dir, 'default.json');
      write(repoDefault, { localEndpoint: null, routes: { auto: ['local'] } });
      const cfg = loadConfig({ repoDefault, userConfig: path.join(t.dir, 'nope.json') });
      assert.strictEqual(cfg.localEndpoint, null);
      assert.deepStrictEqual(cfg.routes.auto, ['local']);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('loadConfig overlays user config on top of repo default', () => {
    const t = tmpDir();
    try {
      const repoDefault = path.join(t.dir, 'default.json');
      const userConfig = path.join(t.dir, 'user.json');
      write(repoDefault, { localEndpoint: null, budget: { dailyUsd: 5 } });
      write(userConfig, { localEndpoint: 'http://x:1234/v1' });
      const cfg = loadConfig({ repoDefault, userConfig });
      assert.strictEqual(cfg.localEndpoint, 'http://x:1234/v1');
      assert.strictEqual(cfg.budget.dailyUsd, 5);
    } finally {
      t.cleanup();
    }
  })
)
  passed++;
else failed++;

if (
  test('applyEnvOverrides applies AGENTIC_BUDGET_USD', () => {
    process.env.AGENTIC_BUDGET_USD = '0.50';
    const cfg = applyEnvOverrides({ budget: { dailyUsd: 5 } });
    delete process.env.AGENTIC_BUDGET_USD;
    assert.strictEqual(cfg.budget.dailyUsd, 0.5);
  })
)
  passed++;
else failed++;

if (
  test('applyEnvOverrides ignores malformed AGENTIC_BUDGET_USD', () => {
    process.env.AGENTIC_BUDGET_USD = 'NaN';
    const cfg = applyEnvOverrides({ budget: { dailyUsd: 5 } });
    delete process.env.AGENTIC_BUDGET_USD;
    assert.strictEqual(cfg.budget.dailyUsd, 5);
  })
)
  passed++;
else failed++;

if (
  test('applyEnvOverrides applies freellmapi overrides', () => {
    process.env.AGENTIC_FREELLMAPI_URL = 'http://override:9000/v1';
    process.env.AGENTIC_FREELLMAPI_KEY = 'k-test';
    const cfg = applyEnvOverrides({});
    delete process.env.AGENTIC_FREELLMAPI_URL;
    delete process.env.AGENTIC_FREELLMAPI_KEY;
    assert.strictEqual(cfg.freellmapi.endpoint, 'http://override:9000/v1');
    assert.strictEqual(cfg.freellmapi.apiKey, 'k-test');
  })
)
  passed++;
else failed++;

if (
  test('loadFreeModels reads the curated catalog from repo config', () => {
    const catalog = loadFreeModels();
    assert.ok(catalog);
    assert.ok(typeof catalog.version === 'number');
    assert.ok(Array.isArray(catalog.providers));
    assert.ok(catalog.providers.length > 0, 'expected at least one provider');
    const openrouter = catalog.providers.find(p => p.id === 'openrouter');
    assert.ok(openrouter, 'expected openrouter in catalog');
    assert.ok(openrouter.modelIds.length > 0);
  })
)
  passed++;
else failed++;

if (
  test('repo default config parses and has the expected routes', () => {
    const cfg = loadConfig({ userConfig: '/nonexistent' });
    assert.ok(cfg.routes.auto);
    assert.ok(cfg.routes.fast);
    assert.ok(cfg.routes.deep);
    assert.ok(cfg.routes['free-only']);
    assert.ok(cfg.cloud.anthropic);
    assert.ok(cfg.cloud.openai);
    assert.ok(cfg.cloud.gemini);
  })
)
  passed++;
else failed++;

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
