# `wiki/` — The FlexNetOS LLM Wiki

A persistent, self-maintained markdown knowledge base built on the
[Karpathy LLM-Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
Plain markdown, committed in git, edited by LLM agents under human curation.

## The core idea

> The wiki is a persistent, compounding artifact. The cross-references are
> already there. The contradictions have already been flagged. The
> synthesis already reflects everything you've read. The wiki keeps
> getting richer with every source you add and every question you ask.
>
> — paraphrased from Karpathy's `llm-wiki.md`

You are in charge of sourcing, exploration, and asking the right
questions. The LLM does the grunt work — summarizing, cross-referencing,
filing, and bookkeeping.

## Three layers

| Layer | Owned by | What it is |
| --- | --- | --- |
| **[`raw/`](raw/)** | Human | Immutable source documents (PDFs, web clips, transcripts, notes). The LLM reads from this layer but never modifies it. |
| **[`pages/`](pages/)** | LLM | The wiki proper — entity / concept / source / synthesis pages. The LLM owns this layer entirely. Created on ingest, updated on every subsequent ingest that touches the same topic. |
| **schema + purpose** | Co-evolved | [`schema.md`](schema.md) defines *how* the wiki is structured; [`purpose.md`](purpose.md) defines *why* it exists. Both update over time as you learn what works. |

## Three operations

| Operation | Command | What happens |
| --- | --- | --- |
| **Ingest** | `make wiki.ingest SRC=raw/path/to/source` | LLM reads the source, integrates it into existing pages, creates new pages for new entities/concepts, updates `index.md`, appends to `log.md`. |
| **Query** | `make wiki.query Q="…"` | LLM reads `index.md`, drills into relevant pages, synthesizes an answer with citations. Good answers get filed back as new synthesis pages. |
| **Lint** | `make wiki.lint` | LLM health-checks the wiki: orphan pages, stale claims, broken cross-refs, missing entity pages, data gaps. |

## Special files

- **[`schema.md`](schema.md)** — read by the LLM on every operation. Defines
  page conventions, frontmatter, `[[wikilinks]]`, file naming, workflows.
- **[`purpose.md`](purpose.md)** — read by the LLM on every operation.
  States goals, key questions, evolving thesis. Defines what's in scope.
- **[`AGENTS.md`](AGENTS.md)** — the entry-point doc for any LLM agent.
  Tells Claude/Codex/Gemini that this is a Karpathy-style wiki and points
  at `schema.md` + `purpose.md`.
- **[`index.md`](index.md)** — LLM-maintained content catalog. The LLM
  reads this *first* on any query — it's the navigation hub.
- **[`log.md`](log.md)** — append-only chronicle of every ingest, query,
  and lint pass. Format: `## [YYYY-MM-DD] <op> | <subject>`.

## Why committed markdown (and not the Tauri app or `.omc/wiki/`)

- **Committed markdown** — shared across the FlexNetOS world via this
  umbrella repo, version-controlled, diffable in PRs, queryable with
  `grep` / `qmd` / any text tool. No app to maintain. Obsidian-compatible
  out of the box.
- **Not [`nashsu/llm_wiki`](https://github.com/nashsu/llm_wiki)** — that's
  a Tauri desktop app implementing the same pattern with more bells. It's
  kept as `repos/external/llm_wiki/` for inspiration but is not our
  runtime. The markdown wiki here is portable and tool-agnostic.
- **Not `.omc/wiki/`** — the OMC `wiki` skill stores keyword-searchable
  pages under `.omc/wiki/`, but `.omc/` is git-ignored and per-project.
  This wiki is cross-project, persistent, and shared.

## Obsidian as a viewing front-end (optional)

Open this folder as an Obsidian vault for graph view, backlinks, and
canvas — Obsidian writes its config under `.obsidian/` which is
gitignored. Markdown stays portable.

## Getting started

```bash
# Read the entry docs in this order:
cat wiki/AGENTS.md      # for the LLM (and for you)
cat wiki/schema.md      # the conventions
cat wiki/purpose.md     # the why
cat wiki/index.md       # the current catalog

# Drop a source in:
cp ~/Downloads/some-paper.pdf wiki/raw/

# Ingest it:
make wiki.ingest SRC=wiki/raw/some-paper.pdf

# Ask the wiki a question:
make wiki.query Q="how does X relate to Y"
```
