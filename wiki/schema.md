# Wiki schema

Conventions every LLM agent must follow when operating on this wiki.
Authoritative — when a generated page disagrees with this file, the
file wins and the page gets corrected.

## Directory layout

```text
wiki/
├── AGENTS.md       Entry-point for LLM agents — read first
├── README.md       Human-facing overview
├── schema.md       THIS FILE — conventions
├── purpose.md      Why the wiki exists; in-scope vs out-of-scope
├── index.md        LLM-maintained catalog of all pages
├── log.md          Append-only chronicle of all operations
├── raw/            Immutable source documents (PDFs, clips, transcripts)
├── pages/
│   ├── entities/   People, places, organizations, products, libraries…
│   ├── concepts/   Ideas, techniques, frameworks, patterns
│   ├── sources/    One summary page per ingested raw doc
│   └── synthesis/  Multi-source comparisons, analyses, theses
└── assets/         Images extracted from sources
```

## Page file naming

- All-lowercase, hyphenated, no spaces, no underscores in slugs.
- `pages/entities/karpathy-andrej.md` — last-first for people, so
  alphabetical sort groups by surname.
- `pages/entities/openai.md` — organizations: their canonical short name.
- `pages/concepts/retrieval-augmented-generation.md` — full descriptive
  slug for concepts; no acronyms in the filename (the title can be `RAG`).
- `pages/sources/2024-12-llm-wiki-karpathy-gist.md` — sources: date
  prefix (`YYYY-MM` is fine) + descriptive slug.
- `pages/synthesis/wiki-vs-rag-tradeoffs.md` — synthesis: descriptive
  slug, optionally a date prefix if time-bound.

## YAML frontmatter — required on every page

```yaml
---
title: "Andrej Karpathy"           # display title (can differ from filename)
type: entity                        # one of: entity | concept | source | synthesis
created: 2026-05-24                 # YYYY-MM-DD, first ingest date
updated: 2026-05-24                 # YYYY-MM-DD, last meaningful edit
sources:                            # back-references to raw/ — sources this page derives from
  - 2024-12-llm-wiki-karpathy-gist
tags: [llm, agents, wiki]           # lowercase, hyphenated, list
aliases: ["Karpathy"]               # optional — alternative names a query might use
status: stable                      # one of: stub | draft | stable | stale
---
```

Field rules:

- `created` / `updated` are absolute dates. The LLM never writes
  "today" — it resolves to the actual date.
- `sources` is the trust trail. If a page makes a claim, that claim
  should be traceable back through `[[wikilinks]]` to one or more
  source pages whose own `sources:` field points into `raw/`.
- `status: stale` is set when newer sources contradict the page. The
  next lint pass surfaces stale pages for human review.

## Page body conventions

### Sections (use them, don't reinvent them)

For `type: entity`:

```markdown
# Title (matches frontmatter)

## Overview
1–3 paragraphs. What is this entity, why does it matter to us per purpose.md?

## Key claims
Bullet list of distinct claims, each with a `[[source-page]]` citation.

## Connections
Cross-references to related entities/concepts: `[[other-entity]]`, `[[concept]]`.

## Open questions
Bullet list — what we don't know yet, gaps to fill.

## Sources
Auto-generated list of `[[source-page]]` entries cited above.
```

For `type: concept`: same structure but the Overview leans definitional.

For `type: source`:

```markdown
# Title

> Citation: <author>, <year>, <venue>, <URL or raw/ path>

## Summary
One paragraph — what the source argues.

## Key claims extracted
- Claim 1 — referenced by `[[entity-or-concept-page]]`
- Claim 2 — …

## Connections to existing wiki
- Strengthens `[[…]]`
- Contradicts `[[…]]` (resolved how?)

## Raw
Pointer to the file in `raw/`.
```

For `type: synthesis`: free-form, but always cite `[[…]]` per claim.

### Cross-references — `[[wikilinks]]`

Use Obsidian-style `[[page-name]]` where `page-name` is the slug (file
basename without `.md`). When the display text should differ:
`[[karpathy-andrej|Karpathy]]`.

Every `[[wikilink]]` must resolve to an existing page. The lint pass
catches broken ones.

### Images

Place under `wiki/assets/` with descriptive names. Reference as
`![Caption](../assets/diagram-foo.png)`.

## `index.md` — content catalog

Layout:

```markdown
# Wiki Index

Last updated: YYYY-MM-DD by <agent-name>

## By category

### Entities
- `[[karpathy-andrej]]` — researcher, originator of the LLM-wiki pattern
- `[[openai]]` — …

### Concepts
- `[[retrieval-augmented-generation]]` — …

### Sources
- `[[2024-12-llm-wiki-karpathy-gist]]` — Karpathy's original gist

### Synthesis
- `[[wiki-vs-rag-tradeoffs]]` — when to compile vs retrieve

## By tag
(auto-generated reverse-index)
```

The LLM updates this file at the end of every ingest, query that
produces a synthesis page, or lint that finds drift.

## `log.md` — operation chronicle

Append-only. Format:

```markdown
## [2026-05-24] ingest | karpathy LLM-wiki gist
- Source: raw/2024-12-llm-wiki-karpathy-gist.md
- Pages created: [[karpathy-andrej]], [[2024-12-llm-wiki-karpathy-gist]]
- Pages updated: [[retrieval-augmented-generation]] (added contrast)
- Notes: pattern subsequently adopted as the wiki's own structure

## [2026-05-24] query | "how does X relate to Y"
- Pages read: [[…]], [[…]]
- New synthesis page: [[x-vs-y-tradeoffs]]

## [2026-05-25] lint | weekly
- Orphans: 0
- Broken wikilinks: 0
- Stale pages: 1 — [[old-claim]] (superseded by [[new-source]]); marked status=stale
```

The `## [YYYY-MM-DD] <op> | <subject>` line is a strict prefix so simple
tools work:

```bash
grep "^## \[" wiki/log.md | tail -10        # last 10 operations
grep "^## \[" wiki/log.md | grep ingest     # all ingests
```

## Workflow: ingest (two-step chain-of-thought)

```text
Step 1 — ANALYZE
  Read raw source. Produce:
    - Key entities (and which already have pages vs need new ones)
    - Key concepts (likewise)
    - Connections to existing wiki: strengthens / extends / contradicts
    - Recommended page structure for the source summary
    - Any review items needing human judgment

Step 2 — GENERATE
  - Create / update pages per the analysis
  - Add cross-references
  - Update index.md
  - Append log.md entry
```

The two steps stay separate calls for quality and for traceability.

## Workflow: query

```text
1. Read index.md first.
2. Identify 2–6 candidate pages by category, tags, aliases.
3. Read the candidates. Read sources they cite if uncertainty is high.
4. Synthesize answer with [[wikilink]] citations on every claim.
5. If answer is substantial (>~300 words of original synthesis, or
   connects 3+ existing pages in a new way), file as
   pages/synthesis/<slug>.md and update index.md + log.md.
```

## Workflow: lint

```text
1. Walk pages/, collect every page's frontmatter.
2. Detect:
   - orphans (no inbound [[wikilinks]] in any other page)
   - broken links (page-name doesn't exist)
   - missing entries (page in pages/ not in index.md)
   - missing pages (entry in index.md not in pages/)
   - stale candidates (a source's `updated` > a page citing it; check claims)
   - missing entity / concept pages (entity name mentioned in >2 pages, no page)
3. Output report under wiki/.lint-report.md (gitignored — local-only).
4. Append summary to log.md.
```

## Special: the schema is not frozen

If a real need emerges to add a category, change a frontmatter field, or
adjust a workflow — propose the change in a PR to `schema.md` and
update every existing page to match. Schema drift is worse than a
schema change.
