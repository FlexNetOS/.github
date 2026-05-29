/**
 * Tests for the OpenAI-compatible HTTP client.
 *
 * Uses an injectable httpRequest so we never hit the network.
 *
 * Run with: node tests/agentic-os/freellmapi-client.test.js
 */

const assert = require('assert');
const path = require('path');

const { chatCompletion, probeModels } = require(path.join(__dirname, '..', '..', 'scripts', 'agentic-os', 'lib', 'freellmapi-client.js'));

function test(name, fn) {
  return Promise.resolve()
    .then(fn)
    .then(() => {
      console.log(`  ✓ ${name}`);
      return true;
    })
    .catch(err => {
      console.log(`  ✗ ${name}`);
      console.log(`    Error: ${err.message}`);
      return false;
    });
}

const choice = {
  channel: 'anthropic-haiku',
  provider: 'anthropic',
  model: 'claude-haiku-4-5-20251001',
  baseUrl: 'http://test/v1',
  apiKey: 'sk-test'
};

async function run() {
  let passed = 0;
  let failed = 0;

  console.log('\nfreellmapi-client');

  if (
    await test('chatCompletion returns NO_CHOICE without baseUrl', async () => {
      const r = await chatCompletion({}, [{ role: 'user', content: 'hi' }]);
      assert.strictEqual(r.ok, false);
      assert.strictEqual(r.error.code, 'NO_CHOICE');
    })
  )
    passed++;
  else failed++;

  if (
    await test('chatCompletion returns NO_MESSAGES with empty array', async () => {
      const r = await chatCompletion(choice, []);
      assert.strictEqual(r.ok, false);
      assert.strictEqual(r.error.code, 'NO_MESSAGES');
    })
  )
    passed++;
  else failed++;

  if (
    await test('chatCompletion parses successful response', async () => {
      const fakeHttp = async (url, opts) => {
        assert.strictEqual(opts.headers.authorization, 'Bearer sk-test');
        assert.strictEqual(opts.body.model, 'claude-haiku-4-5-20251001');
        return {
          ok: true,
          status: 200,
          body: {
            choices: [{ message: { role: 'assistant', content: 'hello there' } }],
            usage: { prompt_tokens: 5, completion_tokens: 3, total_tokens: 8 }
          },
          headers: { 'x-routed-via': 'anthropic' }
        };
      };
      const r = await chatCompletion(choice, [{ role: 'user', content: 'hi' }], { httpRequest: fakeHttp });
      assert.strictEqual(r.ok, true);
      assert.strictEqual(r.text, 'hello there');
      assert.strictEqual(r.usage.tokensIn, 5);
      assert.strictEqual(r.usage.tokensOut, 3);
      assert.strictEqual(r.routedVia, 'anthropic');
    })
  )
    passed++;
  else failed++;

  if (
    await test('chatCompletion surfaces non-2xx as error', async () => {
      const fakeHttp = async () => ({ ok: false, status: 429, error: { code: 'HTTP_ERROR' }, headers: {} });
      const r = await chatCompletion(choice, [{ role: 'user', content: 'hi' }], { httpRequest: fakeHttp });
      assert.strictEqual(r.ok, false);
      assert.strictEqual(r.status, 429);
    })
  )
    passed++;
  else failed++;

  if (
    await test('chatCompletion passes maxTokens and temperature', async () => {
      let captured;
      const fakeHttp = async (_url, opts) => {
        captured = opts.body;
        return { ok: true, status: 200, body: { choices: [{ message: { content: '' } }] }, headers: {} };
      };
      await chatCompletion(choice, [{ role: 'user', content: 'x' }], { httpRequest: fakeHttp, maxTokens: 256, temperature: 0.1 });
      assert.strictEqual(captured.max_tokens, 256);
      assert.strictEqual(captured.temperature, 0.1);
    })
  )
    passed++;
  else failed++;

  if (
    await test('probeModels returns count and model ids', async () => {
      const fakeHttp = async url => {
        assert.ok(url.endsWith('/models'));
        return { ok: true, status: 200, body: { data: [{ id: 'm1' }, { id: 'm2' }, { id: 'm3' }] }, headers: {} };
      };
      const r = await probeModels(choice, { httpRequest: fakeHttp });
      assert.strictEqual(r.ok, true);
      assert.strictEqual(r.count, 3);
      assert.deepStrictEqual(r.models, ['m1', 'm2', 'm3']);
    })
  )
    passed++;
  else failed++;

  if (
    await test('probeModels returns NO_CHOICE without baseUrl', async () => {
      const r = await probeModels({});
      assert.strictEqual(r.ok, false);
      assert.strictEqual(r.error.code, 'NO_CHOICE');
    })
  )
    passed++;
  else failed++;

  console.log(`\n${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

run().catch(err => {
  console.error(err);
  process.exit(2);
});
