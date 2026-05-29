/**
 * Append-only cost log for the agentic-os harness.
 *
 * Each completed task appends one JSON line to cost-log.jsonl with:
 *   { ts, taskId, channel, provider, model, tokensIn, tokensOut, usd, latencyMs }
 *
 * Reads are linear scans — fine for MVP-scale (<1MB). Bigger usage should
 * rotate the log file by day; not in MVP.
 *
 * @module scripts/agentic-os/lib/cost-tracker
 */

'use strict';

const fs = require('fs');
const path = require('path');

const DEFAULT_LOG_PATH = path.join(process.env.HOME || process.env.USERPROFILE || '/tmp', '.agentic-os', 'cost-log.jsonl');

const COST_PER_MILLION_TOKENS = Object.freeze({
  'claude-haiku-4-5-20251001': { input: 0.8, output: 4.0 },
  'claude-sonnet-4-6': { input: 3.0, output: 15.0 },
  'claude-opus-4-7': { input: 15.0, output: 75.0 },
  'gpt-4o-mini': { input: 0.15, output: 0.6 },
  'gpt-4o': { input: 2.5, output: 10.0 },
  'gemini-2.5-flash': { input: 0.075, output: 0.3 },
  'gemini-2.5-pro': { input: 1.25, output: 5.0 },
  auto: { input: 0, output: 0 }
});

function estimateUsd(model, tokensIn, tokensOut) {
  const rate = COST_PER_MILLION_TOKENS[model];
  if (!rate) return 0;
  return (tokensIn * rate.input + tokensOut * rate.output) / 1_000_000;
}

class CostTracker {
  constructor(logPath) {
    this.path = logPath || DEFAULT_LOG_PATH;
    fs.mkdirSync(path.dirname(this.path), { recursive: true });
  }

  append(entry) {
    const record = {
      ts: new Date().toISOString(),
      taskId: entry.taskId || null,
      channel: entry.channel || null,
      provider: entry.provider || null,
      model: entry.model || null,
      tokensIn: entry.tokensIn || 0,
      tokensOut: entry.tokensOut || 0,
      usd: typeof entry.usd === 'number' ? entry.usd : estimateUsd(entry.model, entry.tokensIn || 0, entry.tokensOut || 0),
      latencyMs: entry.latencyMs || 0
    };
    fs.appendFileSync(this.path, JSON.stringify(record) + '\n', 'utf8');
    return record;
  }

  readAll() {
    if (!fs.existsSync(this.path)) return [];
    const text = fs.readFileSync(this.path, 'utf8');
    const records = [];
    for (const line of text.split('\n')) {
      if (!line.trim()) continue;
      try {
        records.push(JSON.parse(line));
      } catch (_) {
        // skip malformed line
      }
    }
    return records;
  }

  summary({ since } = {}) {
    const records = this.readAll();
    const cutoff = since ? Date.parse(since) : 0;
    const filtered = records.filter(r => !cutoff || Date.parse(r.ts) >= cutoff);
    const totalUsd = filtered.reduce((sum, r) => sum + (r.usd || 0), 0);
    const totalTokens = filtered.reduce((sum, r) => sum + (r.tokensIn || 0) + (r.tokensOut || 0), 0);
    const byChannel = {};
    for (const r of filtered) {
      const key = r.channel || 'unknown';
      if (!byChannel[key]) byChannel[key] = { calls: 0, usd: 0, tokens: 0 };
      byChannel[key].calls += 1;
      byChannel[key].usd += r.usd || 0;
      byChannel[key].tokens += (r.tokensIn || 0) + (r.tokensOut || 0);
    }
    return {
      records: filtered.length,
      totalUsd,
      totalTokens,
      byChannel
    };
  }

  clear() {
    if (fs.existsSync(this.path)) fs.unlinkSync(this.path);
  }
}

module.exports = { CostTracker, estimateUsd, COST_PER_MILLION_TOKENS, DEFAULT_LOG_PATH };
