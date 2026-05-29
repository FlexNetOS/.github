---
description: Run or enqueue a single task through the agentic-os harness
argument-hint: <prompt> [--route auto|fast|deep|free-only] [--sticky id] [--enqueue]
---

# /agentic-task

Send one prompt through the agentic-os router → channel → model pipeline.

**Input**: `$ARGUMENTS`

## Behavior

1. Parse the prompt and optional flags from `$ARGUMENTS`.
2. If `--enqueue` is set, append to the persistent queue without running:
   ```bash
   node scripts/agentic-os/harness.js --enqueue "<prompt>" --route <r>
   ```
3. Otherwise, run one-shot synchronously and print both result and metadata:
   ```bash
   node scripts/agentic-os/harness.js --task "<prompt>" --route <r> [--sticky <id>]
   ```
4. Surface the cost (USD), routed model, and latency to the user — be transparent.

## Route Selection

| Route | When to use |
|---|---|
| `auto` (default) | Standard task, no special constraints |
| `fast` | Need a quick draft, OK with smaller model |
| `deep` | Architecture, security, careful reasoning needed |
| `free-only` | Stay zero-cost — local + freellmapi only |

## Sticky Sessions

Pass `--sticky <session-id>` to pin multi-turn conversations to the same channel for `stickyTtlMs` (default 30 min). Avoids the mid-conversation model-switch hallucination spike.

## Examples

```
/agentic-task Explain how the model-router cooldown works
/agentic-task --route deep Review scripts/agentic-os/harness.js for race conditions
/agentic-task --route free-only --sticky chat-1 Hello, who am I talking to?
/agentic-task --enqueue Nightly: summarize today's commits
```
