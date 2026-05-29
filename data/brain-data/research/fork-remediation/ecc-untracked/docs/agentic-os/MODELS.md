# Agentic-OS — Free Model Catalog

Curated list of free-tier models available through `freellmapi-free` (the FlexNetOS/freellmapi proxy).

Source of truth: `config/agentic-os/free-models.json` (versioned, lastReviewed dated).

## Why this list exists

freellmapi aggregates ~14 providers behind a single OpenAI-compatible endpoint and auto-fails-over when one provider rate-limits. The list below is informational — you do **not** pick a specific model from this list when calling the harness; you call the route, the router picks `freellmapi-free`, and freellmapi internally picks the next-best free provider.

Use this catalog when:
- You want to confirm a specific free provider is reachable
- You need to plan around per-provider quota limits
- You're debugging which provider answered (`x-routed-via` header in the response)

## Providers and models

### Google AI Studio
- `gemini-2.5-flash`
- `gemini-2.5-flash-lite`
- `gemini-2.5-pro-preview`
- Context: 1,048,576 tokens. Daily token budget: ~1M.

### Groq
- `llama-3.3-70b-versatile`
- `llama-4-scout-17b`
- `qwen-3-32b`
- `gpt-oss-20b`
- Context: 131,072 tokens. Daily request budget: ~14,400.

### Cerebras
- `qwen-3-235b-instruct`
- Context: 32,768. Daily token budget: ~1M.

### SambaNova Cloud
- `DeepSeek-V3.1`
- `Meta-Llama-4-Maverick`
- `Llama-3.3-70B-Instruct`
- `gemma-3-27b-it`
- Context: 16,384. Daily request budget: 50.

### Mistral La Plateforme
- `mistral-large-3`
- `mistral-medium-3.5`
- `codestral-2412`
- `devstral-small`
- Context: 128,000. Monthly request budget: 1,000,000.

### OpenRouter Free Tier
- `google/gemini-2.0-flash-exp:free`
- `meta-llama/llama-3.3-70b-instruct:free`
- `nvidia/llama-3.1-nemotron-70b-instruct:free`
- `qwen/qwen-2.5-coder-32b-instruct:free`
- `deepseek/deepseek-chat:free`
- `google/gemma-2-9b-it:free`
- `mistralai/mistral-7b-instruct:free`
- `openchat/openchat-7b:free`
- Context: 128,000. Daily request budget: 50.
- **Note:** quota shared across all `:free` models per OpenRouter account.

### GitHub Models
- `gpt-4.1`, `gpt-4o`, `phi-4`, `Llama-3.3-70B-Instruct`
- Context: 128,000. Daily request budget: 150.
- **Auth:** GitHub PAT with `models:read` scope.

### Cohere (trial)
- `command-r-plus-08-2024`, `command-r-08-2024`
- Context: 128,000. Monthly request budget: 1,000.

### Cloudflare Workers AI
- `@cf/moonshot/kimi-k2`, `@cf/openchat/openchat-3.5-0106`, `@cf/qwen/qwen-2.5-coder-32b`
- Context: 32,768. Daily neuron budget: 10,000.

### Z.ai (Zhipu)
- `glm-4.5-flash`, `glm-4.7-air`
- Context: 128,000. Daily request budget: 100.

## Routing hints

Suggestions baked into `config/agentic-os/free-models.json` under `routingHints`:

| Use case | Preferred free models |
|---|---|
| Code generation | openrouter qwen-2.5-coder, mistral/codestral, cloudflare/qwen-coder |
| Long context | google/gemini-2.5-flash, groq/llama-3.3-70b-versatile |
| Reasoning | cerebras/qwen-3-235b, sambanova/DeepSeek-V3.1 |
| Fast and cheap | groq/llama-4-scout, cloudflare/openchat |

These are read by future router extensions; the MVP just hands the request to `freellmapi-free` and lets the proxy decide.

## Total free capacity

freellmapi's README claims ~1.3 billion tokens per month across the stack. Real usable budget depends on which keys you've added; the proxy's per-key rate tracker enforces RPM/RPD/TPM/TPD caps automatically.

## Refreshing this catalog

When freellmapi adds a new provider or a quota changes:

1. Edit `config/agentic-os/free-models.json` (bump `version`, update `lastReviewed`).
2. Edit this `MODELS.md` to match.
3. Run `node tests/agentic-os/config.test.js` to confirm the catalog still parses.
