#!/usr/bin/env node
/**
 * Agentic-OS Harness — main daemon and one-shot CLI.
 *
 * Modes:
 *   harness.js --task "..." [--route auto] [--sticky id]   one-shot task
 *   harness.js --serve [--interval 5000]                   daemon loop
 *   harness.js --status                                    print health
 *   harness.js --enqueue "..."                             add task without running
 *
 * Talks to freellmapi (or any OpenAI-compatible endpoint) via the lib/
 * helpers. Routes through ModelRouter. Logs cost. Records reflections.
 *
 * Exit code 0 on success, 1 on failure.
 */

'use strict';

const path = require('path');
const fs = require('fs');

const { loadConfig } = require('./lib/config');
const { ModelRouter, RouterError } = require('./lib/model-router');
const { chatCompletion, probeModels } = require('./lib/freellmapi-client');
const { TaskQueue, makeId } = require('./lib/task-queue');
const { CostTracker } = require('./lib/cost-tracker');
const { StateStore } = require('./lib/state');

function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        args[key] = true;
      } else {
        args[key] = next;
        i++;
      }
    } else {
      args._.push(arg);
    }
  }
  return args;
}

function log(level, msg, extra) {
  const ts = new Date().toISOString();
  const line = extra ? `${ts} [${level}] ${msg} ${JSON.stringify(extra)}` : `${ts} [${level}] ${msg}`;
  if (level === 'error') process.stderr.write(line + '\n');
  else process.stdout.write(line + '\n');
}

async function runOneTask(task, ctx) {
  const { router, costTracker, store } = ctx;
  const started = Date.now();
  const messages = task.messages || [
    { role: 'system', content: 'You are a helpful task executor inside the agentic-os harness. Be concise.' },
    { role: 'user', content: task.prompt }
  ];

  const maxAttempts = ctx.config.maxAttempts || 3;
  let lastError = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    let choice;
    try {
      choice = router.pick({ id: task.id, route: task.route || 'auto', sticky: task.sticky });
    } catch (err) {
      lastError = { code: err.code || 'PICK_FAILED', message: err.message };
      break;
    }

    log('info', `attempt ${attempt}/${maxAttempts}`, { taskId: task.id, channel: choice.channel, model: choice.model });

    const reqStart = Date.now();
    const result = await chatCompletion(choice, messages, {
      maxTokens: ctx.config.maxTokens || 1024,
      temperature: ctx.config.temperature || 0.7,
      timeoutMs: ctx.config.timeoutMs || 60_000
    });
    const latencyMs = Date.now() - reqStart;

    if (!result.ok) {
      lastError = result.error;
      router.recordFailure(choice, { status: result.status, reason: result.error?.message });
      log('warn', 'channel failed', { channel: choice.channel, status: result.status, code: result.error?.code });
      continue;
    }

    const usage = result.usage || { tokensIn: 0, tokensOut: 0 };
    const costEntry = costTracker.append({
      taskId: task.id,
      channel: choice.channel,
      provider: choice.provider,
      model: choice.model,
      tokensIn: usage.tokensIn,
      tokensOut: usage.tokensOut,
      latencyMs
    });
    router.recordSuccess(choice, { usd: costEntry.usd, tokensIn: usage.tokensIn, tokensOut: usage.tokensOut });
    store.append('reflections.jsonl', JSON.stringify({ ts: costEntry.ts, taskId: task.id, channel: choice.channel, latencyMs, ok: true }));

    return {
      ok: true,
      text: result.text,
      channel: choice.channel,
      provider: choice.provider,
      model: choice.model,
      usage,
      usd: costEntry.usd,
      latencyMs,
      attempts: attempt,
      routedVia: result.routedVia
    };
  }

  return { ok: false, error: lastError, attempts: maxAttempts, totalMs: Date.now() - started };
}

async function modeOneShot(args, ctx) {
  const task = {
    id: makeId(),
    route: args.route || 'auto',
    prompt: args.task,
    sticky: args.sticky || null
  };

  log('info', 'one-shot task', { taskId: task.id, route: task.route, sticky: task.sticky });
  const result = await runOneTask(task, ctx);
  process.stdout.write('\n=== RESULT ===\n');
  if (result.ok) {
    process.stdout.write(result.text + '\n');
    process.stdout.write('\n=== METADATA ===\n');
    process.stdout.write(
      JSON.stringify(
        {
          channel: result.channel,
          provider: result.provider,
          model: result.model,
          usage: result.usage,
          usd: result.usd.toFixed(6),
          latencyMs: result.latencyMs,
          attempts: result.attempts,
          routedVia: result.routedVia
        },
        null,
        2
      ) + '\n'
    );
    return 0;
  }
  process.stderr.write(JSON.stringify(result, null, 2) + '\n');
  return 1;
}

async function modeEnqueue(args, ctx) {
  const task = ctx.queue.enqueue({
    route: args.route || 'auto',
    prompt: args.enqueue,
    sticky: args.sticky || null
  });
  process.stdout.write(`enqueued ${task.id}\n`);
  return 0;
}

async function modeStatus(args, ctx) {
  const health = ctx.router.health();
  const queueStats = ctx.queue.stats();
  const costSummary = ctx.costTracker.summary({ since: new Date(Date.now() - 24 * 3600_000).toISOString() });
  process.stdout.write(
    JSON.stringify(
      {
        health,
        queue: queueStats,
        last24h: costSummary
      },
      null,
      2
    ) + '\n'
  );
  return 0;
}

async function modeServe(args, ctx) {
  const interval = parseInt(args.interval, 10) || 5000;
  log('info', 'daemon starting', { interval });
  const pidFile = path.join(ctx.store.dir, 'harness.pid');
  fs.writeFileSync(pidFile, String(process.pid));

  let stopped = false;
  const shutdown = () => {
    log('info', 'shutdown signal received');
    stopped = true;
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  while (!stopped) {
    const task = ctx.queue.nextPending();
    if (task) {
      ctx.queue.markRunning(task.id);
      const result = await runOneTask(task, ctx);
      if (result.ok) {
        ctx.queue.markDone(task.id, {
          text: result.text,
          channel: result.channel,
          model: result.model,
          usage: result.usage,
          usd: result.usd
        });
      } else {
        ctx.queue.markFailed(task.id, result.error || { code: 'UNKNOWN' });
      }
    } else {
      await new Promise(resolve => setTimeout(resolve, interval));
    }
  }

  try {
    fs.unlinkSync(pidFile);
  } catch (_) {
    /* ignore */
  }
  log('info', 'daemon stopped');
  return 0;
}

async function modeProbe(args, ctx) {
  const route = args.route || 'auto';
  let choice;
  try {
    choice = ctx.router.pick({ id: 'probe-' + Date.now(), route });
  } catch (err) {
    process.stderr.write(`probe failed: ${err.message}\n`);
    return 1;
  }
  const result = await probeModels(choice);
  process.stdout.write(JSON.stringify({ channel: choice.channel, ...result }, null, 2) + '\n');
  return result.ok ? 0 : 1;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  const config = loadConfig({ explicit: args.config });
  const router = new ModelRouter(config);
  const queue = new TaskQueue(config.queuePath);
  const costTracker = new CostTracker(config.costLogPath);
  const store = new StateStore(config.stateDir);
  const ctx = { config, router, queue, costTracker, store };

  if (args.task) return modeOneShot(args, ctx);
  if (args.enqueue) return modeEnqueue(args, ctx);
  if (args.serve) return modeServe(args, ctx);
  if (args.status) return modeStatus(args, ctx);
  if (args.probe) return modeProbe(args, ctx);

  process.stdout.write(
    [
      'agentic-os harness',
      '',
      'Usage:',
      '  harness.js --task "..." [--route auto|fast|deep|free-only] [--sticky id]',
      '  harness.js --enqueue "..." [--route auto] [--sticky id]',
      '  harness.js --serve [--interval ms]',
      '  harness.js --status',
      '  harness.js --probe [--route auto]',
      '',
      'Config: $ECC_AGENTIC_OS_CONFIG > ~/.agentic-os/config.json > config/agentic-os/default.json',
      ''
    ].join('\n')
  );
  return 0;
}

if (require.main === module) {
  main()
    .then(code => process.exit(code))
    .catch(err => {
      process.stderr.write(`harness fatal: ${err.stack || err.message}\n`);
      process.exit(2);
    });
}

module.exports = { main, runOneTask, parseArgs };
