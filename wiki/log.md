# Wiki Log

> Append-only chronicle of every ingest, query, and lint pass.
>
> Format (strict): `## [YYYY-MM-DD] <op> | <subject>` so the log is
> parseable with `grep "^## \[" wiki/log.md`.

---

## [2026-05-24] init | wiki scaffolded

- Created skeleton: `AGENTS.md`, `README.md`, `schema.md`, `purpose.md`,
  `index.md`, `log.md`, `raw/`, `pages/{entities,concepts,sources,synthesis}/`.
- No pages ingested yet. First `make wiki.ingest` will overwrite this
  init entry with real operational history.
- Pattern source: [Karpathy LLM-Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f),
  local copy at `repos/external/llm_wiki/llm-wiki.md` once that
  submodule is initialized.
