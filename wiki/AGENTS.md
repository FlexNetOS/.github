# Wiki AGENTS

This file is the entry point for any LLM agent operating on this wiki —
Claude Code, OpenAI Codex, Gemini CLI, OpenCode, or whatever comes next.

## What this wiki is

A **Karpathy-style LLM Wiki** living in `wiki/` of the FlexNetOS umbrella
repo. The pattern: persistent markdown knowledge base, LLM-maintained,
human-curated. The original idea document is preserved at
`repos/external/llm_wiki/llm-wiki.md` for reference.

## Before you do anything

Read these files in order, every session:

1. **[`schema.md`](schema.md)** — the conventions you must follow. Page
   format, YAML frontmatter, `[[wikilinks]]`, file naming, the
   ingest/query/lint workflows. Treat this as authoritative.
2. **[`purpose.md`](purpose.md)** — what this wiki is for, what questions
   it should help answer. Use to judge whether a source is in-scope and
   what to emphasize.
3. **[`index.md`](index.md)** — the current catalog. Read first on any
   query to see what already exists, so you don't duplicate pages.

If you're about to make non-trivial structural changes (rename a
category, restructure the index, change the schema), discuss with the
human first.

## Operations you can perform

Three, exactly. They map 1-to-1 with the OMC `wiki` skill's operations
(`wiki_ingest` / `wiki_query` / `wiki_lint`), but here they're file edits
in this directory tree, not skill calls.

### Ingest

Triggered by: `make wiki.ingest SRC=<path>` or the user dropping a file
in `raw/` and asking you to process it.

Two-step chain-of-thought (per `llm_wiki/llm-wiki.md` and our `schema.md`):

1. **Analyze.** Read the source. Identify key entities, concepts,
   arguments. Note connections to existing wiki content. Flag
   contradictions with what's already filed. Recommend a structure.
2. **Generate.** Write a source-summary page under `pages/sources/`.
   Create or update entity pages under `pages/entities/`. Create or
   update concept pages under `pages/concepts/`. Add or strengthen
   `[[wikilink]]` cross-references on neighboring pages. Update
   `index.md` to include any new pages. Append an entry to `log.md`.

Single source may touch 10–15 pages. That's fine.

### Query

Triggered by: `make wiki.query Q="…"` or any open question from the user.

1. Read `index.md` to identify candidate pages.
2. Drill into the candidates. Synthesize an answer.
3. **Cite.** Every claim that comes from a source page should reference
   it as `[[source-page-name]]`.
4. If the answer is substantial enough that re-deriving it would waste
   time later, **file it back** as a new synthesis page under
   `pages/synthesis/` and update `index.md` + `log.md`.

### Lint

Triggered by: `make wiki.lint` or a periodic health check.

Check for:

- **Orphan pages** — files with zero inbound `[[wikilinks]]`.
- **Broken `[[wikilinks]]`** — links to pages that don't exist.
- **Missing entity / concept pages** — repeatedly-mentioned names that
  lack their own page.
- **Stale claims** — pages contradicted by newer source pages, where the
  newer evidence is stronger.
- **Index drift** — pages in `pages/` not listed in `index.md`, or
  entries in `index.md` whose files no longer exist.
- **Frontmatter violations** — see `schema.md` for the required fields.

Output a markdown report. Do not auto-fix. Propose specific changes for
the human to approve.

## Rules of engagement

- **Never modify files under `raw/`.** That layer is immutable.
- **Always update `index.md` and `log.md`** when you change the page
  set. They're how future-you (and future-other-agents) navigate.
- **Every page gets YAML frontmatter** per `schema.md`. No exceptions.
- **Cross-reference liberally** — `[[wikilinks]]` are how the wiki holds
  together. A page that references nothing is suspect.
- **Date entries in `log.md` as absolute YYYY-MM-DD**, not "today" or
  "yesterday" — the log outlives the conversation.
- **When in doubt about whether something is in scope**, read
  `purpose.md`. If still in doubt, ask.
- **Don't invent categories.** `entities/`, `concepts/`, `sources/`,
  `synthesis/` are the four. Add a new top-level category only after
  discussion.

## What you do *not* do

- Run vector embeddings against the wiki. It's keyword/text only by
  design (per `schema.md`). If a search engine is needed, install `qmd`
  and shell out — don't build a parallel index.
- Touch any other directory in this repo (`repos/`, `tools/`,
  `secrets/`, `runner/`, `.github/`) unless the user explicitly asks.
- Spin up a separate "wiki agent" subagent for routine ingest. Just do
  the work.
