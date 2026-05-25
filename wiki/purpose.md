# Wiki purpose

> Schema (`schema.md`) defines *how* this wiki is structured.
> Purpose (this file) defines *why* it exists.
> Together they make the LLM a disciplined wiki maintainer instead of a
> generic chatbot.

## Mission

Build a single, persistent, cross-referenced knowledge base that
compounds across every project, paper, and conversation in the
FlexNetOS world — so that knowledge accumulated once is never re-derived
on the next query.

The wiki is the **memory layer** for everything happening under this
umbrella. When ruvector ingests a new vector-DB technique, when
mempalace ships a new memory pattern, when a paper changes our
understanding of how agents should be evaluated — the wiki is where
that understanding lands and stays.

## In scope

This wiki accumulates and synthesizes knowledge about:

1. **Agent systems and orchestration** — multi-agent patterns,
   evaluation, harnesses, runtime guarantees, safety.
2. **LLM internals and runtimes** — model architecture, attention
   variants, KV-cache strategies, llama.cpp internals, training/fine-tuning
   pipelines.
3. **Vector databases and graph stores** — index algorithms, GNN
   layers, retrieval patterns, hybrid search.
4. **Knowledge representation** — RAG variants, LLM-wiki / GraphRAG /
   GAR patterns, document layouts, citation tracking.
5. **OS-level infrastructure** — Debian packaging, devcontainer
   patterns, self-hosted runners, secrets management, the boring
   plumbing that has to work for the interesting stuff to ship.
6. **Methodology and practice** — software-engineering patterns we
   adopt across projects, test strategies, observability conventions.

## Out of scope (these belong elsewhere)

- **Per-project documentation.** A specific repo's API reference,
  changelog, or release notes lives in that repo's `docs/`, not here.
  The wiki may *reference* such documentation but doesn't duplicate it.
- **Operational secrets and runbooks.** Secrets in `secrets/`,
  runbooks in `docs/`.
- **Conversation logs and one-off chat transcripts.** Append to
  `log.md` if the operation produced or consumed wiki pages;
  otherwise the conversation is fine staying in the chat history.
- **Personal notes that aren't research-relevant** — journaling,
  reminders, todos. Use `~/.claude/` notes or a different system.

## Key questions the wiki should answer

These are the questions a query should be able to answer reliably from
the current page set. If you ingest a source and the wiki gets visibly
better at answering one of these, you've done it right.

1. **What's the current best-known approach for *X*?** (where X is in
   any of the in-scope areas)
2. **Where does this technique come from, and what alternatives did the
   authors compare against?**
3. **What contradicts this claim?** (the wiki should track contradictions,
   not just consensus)
4. **What's the gap?** What's claimed without evidence; what's measured
   only in narrow conditions; what's been proposed but never deployed.
5. **Who are the people / labs / projects that matter in this area?**
   The entity pages should cluster useful citations.
6. **What did we change our mind about?** Stale pages and superseding
   pages should make the evolution legible.

## Evolving thesis (update as understanding deepens)

> Current best understanding — this section gets revised, not appended.

- Retrieval-augmented patterns suffer from re-deriving knowledge on
  every query. **Compiled-wiki patterns** (this very wiki, GraphRAG,
  curated knowledge graphs) compound across queries — at the cost of
  ingest-time work and human curation. The right architecture depends on
  query density and source churn rate.
- Self-maintaining knowledge bases were impractical pre-LLM because the
  maintenance cost grew faster than the value. LLMs change the unit
  economics — bookkeeping is the part LLMs are best at and humans hate
  most.
- The hard problem is not "build a knowledge base"; it's "keep a
  knowledge base coherent as it grows." That's what the lint operation
  is for. A wiki without periodic lint drifts toward incoherence.

## What the wiki is *not* trying to be

- Not a search engine. Use `qmd` or `grep` if you need full-text
  search.
- Not Wikipedia. We're partial, opinionated, and traceable to specific
  sources we care about.
- Not a permanent record of every URL someone has shared in chat. Be
  selective. If a source isn't worth a summary page, it isn't worth
  ingesting.
