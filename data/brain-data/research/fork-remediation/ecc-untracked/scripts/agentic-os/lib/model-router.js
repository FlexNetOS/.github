/**
 * Model Router for the agentic-os harness.
 *
 * Picks an upstream channel (local / freellmapi / cloud-provider+model) for
 * each task. Tracks per-channel health with cooldowns, enforces a daily USD
 * budget by downgrading to free channels when exceeded, and honors sticky
 * sessions so multi-turn tasks stay on one model.
 *
 * The router is HTTP-agnostic — it returns a `choice` describing the channel
 * to call. The harness performs the actual HTTP request.
 *
 * @module scripts/agentic-os/lib/model-router
 */

'use strict';

class RouterError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'RouterError';
    this.code = code || 'ROUTER_ERROR';
  }
}

const CHANNEL_CATALOG = Object.freeze({
  local: {
    provider: 'local',
    model: 'auto',
    isLocal: true,
    isFree: true,
    requiresLocalEndpoint: true
  },
  'freellmapi-free': {
    provider: 'freellmapi',
    model: 'auto',
    isLocal: false,
    isFree: true,
    requiresFreellmapi: true
  },
  'anthropic-haiku': {
    provider: 'anthropic',
    model: 'claude-haiku-4-5-20251001',
    isFree: false
  },
  'anthropic-sonnet': {
    provider: 'anthropic',
    model: 'claude-sonnet-4-6',
    isFree: false
  },
  'anthropic-opus': {
    provider: 'anthropic',
    model: 'claude-opus-4-7',
    isFree: false
  },
  'openai-mini': {
    provider: 'openai',
    model: 'gpt-4o-mini',
    isFree: false
  },
  'openai-gpt4o': {
    provider: 'openai',
    model: 'gpt-4o',
    isFree: false
  },
  'gemini-flash': {
    provider: 'gemini',
    model: 'gemini-2.5-flash',
    isFree: false
  },
  'gemini-pro': {
    provider: 'gemini',
    model: 'gemini-2.5-pro',
    isFree: false
  }
});

const DEFAULT_COOLDOWN_MS = 60_000;
const DEFAULT_STICKY_TTL_MS = 30 * 60 * 1000;

function providerDefaultBaseUrl(provider) {
  switch (provider) {
    case 'anthropic':
      return 'https://api.anthropic.com';
    case 'openai':
      return 'https://api.openai.com/v1';
    case 'gemini':
      return 'https://generativelanguage.googleapis.com/v1beta';
    default:
      return null;
  }
}

class ModelRouter {
  constructor(config, deps = {}) {
    if (!config) throw new RouterError('config is required', 'NO_CONFIG');
    this.config = config;
    this.now = deps.now || (() => Date.now());
    this.cooldownMs = config.cooldownMs || DEFAULT_COOLDOWN_MS;
    this.stickyTtlMs = config.stickyTtlMs || DEFAULT_STICKY_TTL_MS;

    this.state = new Map();
    this.stickyMap = new Map();
    this.budget = {
      dailyUsd: 0,
      day: this.dayKey(this.now())
    };
  }

  dayKey(ts) {
    return new Date(ts).toISOString().slice(0, 10);
  }

  resetBudgetIfNewDay() {
    const today = this.dayKey(this.now());
    if (today !== this.budget.day) {
      this.budget = { dailyUsd: 0, day: today };
    }
  }

  channelDef(name) {
    return CHANNEL_CATALOG[name];
  }

  isChannelEnabled(name) {
    const def = this.channelDef(name);
    if (!def) return false;
    if (def.requiresLocalEndpoint && !this.config.localEndpoint) return false;
    if (def.requiresFreellmapi) {
      const endpoint = this.config.freellmapi && this.config.freellmapi.endpoint;
      if (!endpoint) return false;
    }
    if (['anthropic', 'openai', 'gemini'].includes(def.provider)) {
      const providerCfg = this.config.cloud && this.config.cloud[def.provider];
      if (!providerCfg || providerCfg.enabled === false) return false;
      if (providerCfg.apiKeyEnv && !process.env[providerCfg.apiKeyEnv]) return false;
    }
    return true;
  }

  channelStatus(name) {
    const entry = this.state.get(name);
    if (!entry) return 'healthy';
    if (entry.cooldownUntil && entry.cooldownUntil > this.now()) return 'cooldown';
    return 'healthy';
  }

  resolveChoice(name, taskId) {
    const def = this.channelDef(name);
    if (!def) throw new RouterError(`unknown channel: ${name}`, 'UNKNOWN_CHANNEL');

    const choice = {
      channel: name,
      provider: def.provider,
      model: def.model,
      isLocal: !!def.isLocal,
      isFree: !!def.isFree,
      taskId
    };

    if (def.isLocal) {
      choice.baseUrl = this.config.localEndpoint;
      choice.apiKey = this.config.localApiKey || 'local';
    } else if (def.provider === 'freellmapi') {
      choice.baseUrl = this.config.freellmapi.endpoint;
      choice.apiKey = this.config.freellmapi.apiKey;
    } else {
      const providerCfg = this.config.cloud[def.provider];
      choice.baseUrl = providerCfg.baseUrl || providerDefaultBaseUrl(def.provider);
      choice.apiKey = providerCfg.apiKeyEnv ? process.env[providerCfg.apiKeyEnv] : null;
    }

    return choice;
  }

  pick(task) {
    if (!task || !task.route) throw new RouterError('task.route is required', 'NO_ROUTE');

    this.resetBudgetIfNewDay();

    if (task.sticky) {
      const sticky = this.stickyMap.get(task.sticky);
      if (sticky && sticky.expiresAt > this.now()) {
        if (this.channelStatus(sticky.channel) === 'healthy' && this.isChannelEnabled(sticky.channel)) {
          return this.resolveChoice(sticky.channel, task.id);
        }
      }
    }

    const routeList = this.config.routes && this.config.routes[task.route];
    if (!Array.isArray(routeList)) {
      throw new RouterError(`unknown route: ${task.route}`, 'UNKNOWN_ROUTE');
    }

    const ceiling = this.config.budget && this.config.budget.dailyUsd;
    const budgetExceeded = typeof ceiling === 'number' && this.budget.dailyUsd >= ceiling;

    const candidates = routeList.filter(name => {
      if (!this.isChannelEnabled(name)) return false;
      if (this.channelStatus(name) !== 'healthy') return false;
      if (budgetExceeded) {
        const def = this.channelDef(name);
        if (!def.isFree) return false;
      }
      return true;
    });

    if (candidates.length === 0) {
      throw new RouterError(`no healthy channels for route '${task.route}'`, 'NO_HEALTHY_CHANNELS');
    }

    const pickedName = candidates[0];
    const choice = this.resolveChoice(pickedName, task.id);

    if (task.sticky) {
      this.stickyMap.set(task.sticky, {
        channel: pickedName,
        model: choice.model,
        expiresAt: this.now() + this.stickyTtlMs
      });
    }

    return choice;
  }

  recordSuccess(choice, usage = {}) {
    const name = choice.channel;
    const prev = this.state.get(name) || { successCount: 0, failureCount: 0 };
    this.state.set(name, {
      ...prev,
      successCount: prev.successCount + 1,
      cooldownUntil: null,
      lastSuccess: this.now()
    });
    if (typeof usage.usd === 'number') {
      this.resetBudgetIfNewDay();
      this.budget.dailyUsd += usage.usd;
    }
  }

  recordFailure(choice, info = {}) {
    const name = choice.channel;
    const prev = this.state.get(name) || { successCount: 0, failureCount: 0 };
    const cooldownMs = info.cooldownMs || this.cooldownMs;
    this.state.set(name, {
      ...prev,
      failureCount: prev.failureCount + 1,
      cooldownUntil: this.now() + cooldownMs,
      lastFailure: { status: info.status, reason: info.reason, at: this.now() }
    });
  }

  health() {
    const channels = [];
    const seen = new Set();
    Object.values(this.config.routes || {}).forEach(list => {
      list.forEach(name => {
        if (seen.has(name)) return;
        seen.add(name);
        const def = this.channelDef(name);
        if (!def) return;
        const entry = this.state.get(name) || {};
        channels.push({
          channel: name,
          provider: def.provider,
          model: def.model,
          enabled: this.isChannelEnabled(name),
          status: this.channelStatus(name),
          successCount: entry.successCount || 0,
          failureCount: entry.failureCount || 0,
          cooldownUntil: entry.cooldownUntil || null
        });
      });
    });
    return {
      channels,
      budget: {
        day: this.budget.day,
        usedUsd: this.budget.dailyUsd,
        ceilingUsd: (this.config.budget && this.config.budget.dailyUsd) || null
      }
    };
  }
}

module.exports = { ModelRouter, RouterError, CHANNEL_CATALOG };
