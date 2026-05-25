# `wiki/raw/` — the source layer (immutable)

Drop documents here. The LLM reads from this directory but **never
modifies** anything in it. Each file gets exactly one corresponding
summary page under `../pages/sources/`.

## Accepted formats

- **Markdown** — preferred. Web articles, READMEs, notes. Use the
  Obsidian Web Clipper or similar to convert HTML to clean markdown.
- **PDF** — papers, books. The LLM extracts text and any image
  references; embedded images go to `../assets/`.
- **Plain text** — transcripts, notes, code snippets.
- **HTML** — works but markdown is preferred; HTML may have visual
  artifacts that pollute the extraction.

## Naming

Use a date prefix so files sort chronologically and so the
corresponding source page can match:

```
YYYY-MM-<short-slug>.<ext>
```

Examples:

```
2024-12-llm-wiki-karpathy-gist.md
2025-03-graphrag-microsoft-paper.pdf
2026-05-ruvector-architecture-notes.md
```

The corresponding source page becomes
`pages/sources/2024-12-llm-wiki-karpathy-gist.md`.

## What happens when you drop a file

1. You: `cp some-paper.pdf wiki/raw/2026-05-some-paper.pdf`
2. You: `make wiki.ingest SRC=wiki/raw/2026-05-some-paper.pdf`
3. LLM (analyze): reads source, identifies entities/concepts, plans
   page edits.
4. LLM (generate): writes `pages/sources/2026-05-some-paper.md`,
   creates or updates entity/concept pages, adds cross-references,
   updates `../index.md`, appends to `../log.md`.

You read the resulting pages. If something's off, edit the prompt or
the schema and re-ingest — the source file in `raw/` stays untouched.

## Hard rules

- **Never edit files in `raw/` after they land.** Treat them as
  immutable. If you find a better version of the same source, file it
  as a new entry and mark the old one with a frontmatter `superseded_by`
  pointer in its summary page.
- **No secrets, no PII** without redaction. This is a git-tracked
  directory.
- **Auto-watch is best-effort.** If you drop a file and nothing happens,
  run `make wiki.ingest` explicitly — auto-watch may be off.
