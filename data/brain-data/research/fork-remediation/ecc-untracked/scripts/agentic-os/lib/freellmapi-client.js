/**
 * OpenAI-compatible HTTP client.
 *
 * Used by the harness to talk to ANY OpenAI-compatible endpoint:
 *   - freellmapi proxy (http://localhost:3001/v1)
 *   - local Ollama, llama.cpp, vLLM (http://localhost:11434/v1 etc.)
 *   - direct OpenAI API
 *   - direct Anthropic via the proxy
 *
 * Returns the parsed response or a structured error. Never throws on HTTP
 * failure — instead returns { ok: false, status, error } so the caller can
 * mark the channel for cooldown without crashing the harness.
 *
 * @module scripts/agentic-os/lib/freellmapi-client
 */

'use strict';

const http = require('http');
const https = require('https');
const { URL } = require('url');

const DEFAULT_TIMEOUT_MS = 60_000;

function request(urlString, { method = 'POST', headers = {}, body, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
  return new Promise(resolve => {
    let parsed;
    try {
      parsed = new URL(urlString);
    } catch (err) {
      resolve({ ok: false, status: 0, error: { code: 'BAD_URL', message: err.message } });
      return;
    }

    const lib = parsed.protocol === 'https:' ? https : http;
    const payload = body ? Buffer.from(JSON.stringify(body), 'utf8') : null;
    const reqHeaders = { 'content-type': 'application/json', accept: 'application/json', ...headers };
    if (payload) reqHeaders['content-length'] = payload.length;

    const req = lib.request(
      {
        method,
        protocol: parsed.protocol,
        hostname: parsed.hostname,
        port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
        path: `${parsed.pathname}${parsed.search}`,
        headers: reqHeaders,
        timeout: timeoutMs
      },
      res => {
        const chunks = [];
        res.on('data', chunk => chunks.push(chunk));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          let parsedBody = null;
          try {
            parsedBody = text ? JSON.parse(text) : null;
          } catch (_) {
            parsedBody = text;
          }
          const ok = res.statusCode >= 200 && res.statusCode < 300;
          resolve(
            ok
              ? { ok: true, status: res.statusCode, body: parsedBody, headers: res.headers }
              : { ok: false, status: res.statusCode, error: { code: 'HTTP_ERROR', body: parsedBody }, headers: res.headers }
          );
        });
      }
    );

    req.on('error', err => {
      resolve({ ok: false, status: 0, error: { code: err.code || 'NETWORK_ERROR', message: err.message } });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ ok: false, status: 0, error: { code: 'TIMEOUT', message: `request exceeded ${timeoutMs}ms` } });
    });

    if (payload) req.write(payload);
    req.end();
  });
}

/**
 * Send an OpenAI-compatible chat completion to the channel described in
 * `choice`. Returns { ok, status, body, error, usage }.
 *
 * @param {object} choice         - from ModelRouter.pick()
 * @param {Array}  messages       - OpenAI messages array
 * @param {object} [options]
 * @param {number} [options.maxTokens]
 * @param {number} [options.temperature]
 * @param {number} [options.timeoutMs]
 * @param {function} [options.httpRequest] - override for tests
 */
async function chatCompletion(choice, messages, options = {}) {
  if (!choice || !choice.baseUrl) {
    return { ok: false, status: 0, error: { code: 'NO_CHOICE', message: 'choice.baseUrl missing' } };
  }
  if (!Array.isArray(messages) || messages.length === 0) {
    return { ok: false, status: 0, error: { code: 'NO_MESSAGES', message: 'messages array required' } };
  }

  const url = `${choice.baseUrl.replace(/\/$/, '')}/chat/completions`;

  const headers = {};
  if (choice.apiKey) headers.authorization = `Bearer ${choice.apiKey}`;

  const requestBody = {
    model: choice.model,
    messages
  };
  if (typeof options.maxTokens === 'number') requestBody.max_tokens = options.maxTokens;
  if (typeof options.temperature === 'number') requestBody.temperature = options.temperature;
  if (options.stream === true) requestBody.stream = true;

  const httpRequest = options.httpRequest || request;
  const result = await httpRequest(url, {
    method: 'POST',
    headers,
    body: requestBody,
    timeoutMs: options.timeoutMs
  });

  if (!result.ok) return result;

  const choices = result.body && result.body.choices;
  const message = choices && choices[0] && choices[0].message;
  const usage = result.body && result.body.usage;

  return {
    ok: true,
    status: result.status,
    body: result.body,
    text: (message && message.content) || '',
    usage: usage
      ? {
          tokensIn: usage.prompt_tokens || 0,
          tokensOut: usage.completion_tokens || 0,
          total: usage.total_tokens || 0
        }
      : null,
    routedVia: result.headers && result.headers['x-routed-via']
  };
}

/**
 * Lightweight health probe — GET /models. Returns { ok, status, count }.
 */
async function probeModels(choice, options = {}) {
  if (!choice || !choice.baseUrl) {
    return { ok: false, status: 0, error: { code: 'NO_CHOICE' } };
  }
  const url = `${choice.baseUrl.replace(/\/$/, '')}/models`;
  const headers = {};
  if (choice.apiKey) headers.authorization = `Bearer ${choice.apiKey}`;
  const httpRequest = options.httpRequest || request;
  const result = await httpRequest(url, { method: 'GET', headers, timeoutMs: options.timeoutMs || 10_000 });
  if (!result.ok) return result;
  const list = (result.body && result.body.data) || [];
  return { ok: true, status: result.status, count: list.length, models: list.map(m => m.id) };
}

module.exports = { chatCompletion, probeModels, request };
