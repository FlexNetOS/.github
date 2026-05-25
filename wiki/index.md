# Wiki Index

The LLM-maintained content catalog. Read this **first** before any
query — it's how you navigate the wiki without re-reading every page.

**Last updated:** 2026-05-24 — initial scaffold (no pages yet)

**Page count:** 0 entity · 0 concept · 0 source · 0 synthesis

---

## By category

### Entities

People, places, organizations, products, libraries. *(none yet — first ingest will create entries here)*

### Concepts

Ideas, techniques, frameworks, patterns. *(none yet)*

### Sources

One summary page per ingested raw document. *(none yet)*

### Synthesis

Multi-source comparisons, analyses, theses produced from queries. *(none yet)*

---

## By tag

*Auto-generated reverse-index — populates after first ingest.*

---

## Suggested first ingestions

A pre-warmed set of sources that establish baseline coverage of the
[`purpose.md`](purpose.md) in-scope areas. Drop any of these into
`raw/` and run `make wiki.ingest`:

- `repos/external/llm_wiki/llm-wiki.md` — Karpathy's original
  LLM-Wiki pattern (becomes our `entities/karpathy-andrej` and
  `concepts/llm-wiki-pattern` and a `sources/` page)
- Any paper on retrieval-augmented generation, GraphRAG, or
  vector-store architecture you have on hand
- The README of any FlexNetOS owned repo (`ruvector`, `ruOS`,
  `understand-anything`) — establishes baseline entity pages for
  our own projects
