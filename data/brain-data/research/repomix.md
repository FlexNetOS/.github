# Research: repomix

**Status:** Pre-adoption research. **Third-party upstream — vendored as a tool. Clone-only (gitignored) until/unless FlexNetOS commits to forking.**
**Action gated by this dossier:** Operate repomix as a gitignored local clone (`tools/repomix/`) plus a pinned wrapper (`tools/bin/repomix`) for the umbrella's clone-and-research-before-fork ritual. **No submodule registration yet** — per the user's policy on 2026-05-28, tool/upstream clones stay out of `MANIFEST.yaml` and `.gitmodules` until the umbrella forks them.

**Cross-reference:** Reinforces and operationalizes the existing
`feedback-research-before-fork` rule (never `gh repo fork` before
`data/brain-data/research/<name>.md` exists). Repomix is the missing
mechanical step that produces a reviewable codebase pack so the
dossier can be informed by source, not just README skimming. Companion
to the existing `n8n.md`, `paperclip.md`, `ai-top-utility.md`,
`fabro.md`, `my-github-reconciliation.md` dossiers.

## 1. Identity

| Field | Value |
| --- | --- |
| Upstream | `https://github.com/yamadashy/repomix` |
| Our placement | `tools/repomix/` — **gitignored local clone**, not a submodule |
| License | **MIT** (clean — vendor freely; tool, not product) |
| Default branch | `main` |
| Latest release at research time | `v1.14.1` (2026-05-27) |
| Stars | ~25.7k |
| Primary language | TypeScript (Node `>=22.0.0`, `type: module`) |
| Distribution | npm package `repomix` (`bin: ./bin/repomix.cjs`); Docker image `ghcr.io/yamadashy/repomix`; no GitHub release tarballs/binaries |
| Homepage / docs | <https://repomix.com> |
| Topics | `ai`, `llm`, `mcp`, `developer-tools`, `claude`, `gpt`, `gemini`, `deepseek`, `chatbot`, `nodejs`, `typescript` |

## 2. Purpose (per upstream README)

> *"Repomix is a powerful tool that packs your entire repository into a
> single, AI-friendly file. Perfect for when you need to feed your
> codebase to Large Language Models (LLMs) or other AI tools like
> Claude, ChatGPT, DeepSeek, Perplexity, Gemini, Gemma, Llama, Grok, and
> more."*

Concretely: walks a directory, applies `.gitignore` + a configurable
allow/deny filter, optionally compresses (tree-sitter-driven "summarize
to signatures"), counts tokens per popular tokenizer, and emits a
single pack file (XML by default, Markdown or plain-text on request)
suitable for paste-into-LLM or attach-as-context. Also exposes an
MCP server so any MCP-capable agent can pack a repo on demand.

## 3. Stack inventory

- Pure Node/TypeScript CLI; no native deps.
- Package layout (per upstream `package.json`):
  - `name`: `repomix`, `version`: `1.14.1`
  - `bin`: `./bin/repomix.cjs`
  - `engines`: `{ node: ">=22.0.0", yarn: ">=1.22.22" }`
  - `main`: `./lib/index.js`, `type`: `module`
- Run modes (informational, from `repomix --help` lineage):
  - `repomix [path]` — pack a local directory
  - `repomix --remote <url>` — clone-and-pack in one shot (in-tree, ephemeral)
  - `repomix --mcp` — start the MCP server
- Output formats: `xml` (default, best for LLM context), `markdown`, `plain`.
- Compression mode: `--compress` runs a tree-sitter pass that reduces
  source files to declarations + comments, dropping function bodies.

## 4. License caveat

**MIT — no friction.** Tool licensing is permissive; embedding the
binary or shipping output is unrestricted. The packs repomix *produces*
inherit whatever license the upstream repo carries — irrelevant for
internal pre-fork research but worth noting before publishing a pack
publicly.

## 5. FlexNetOS-side intent

**Repomix is plumbing for the umbrella's research-before-fork rule.**
The intent is *not* to ship repomix as a product, fork it (yet), or
expose it externally. It is the mechanical step that turns the rule
into a reviewable artifact:

1. Operator says "let's add `<owner>/<repo>` to the umbrella."
2. `make research.pack URL=https://github.com/<owner>/<repo>` clones
   the original upstream into a temp workspace, runs repomix against
   it, and drops the result at
   `data/brain-data/research/<name>/repomix-pack.xml` plus a short
   summary at `data/brain-data/research/<name>/repomix-summary.md`.
3. Operator (and any agent assisting them) reads the pack + summary
   alongside the upstream README, fills in
   `data/brain-data/research/<name>.md` using the existing dossier
   shape.
4. **Only after the dossier exists** does `gh repo fork` run.

## 6. Pre-adoption audit

- ✅ License is MIT — no friction to use as a tool.
- ✅ Pure Node, no native deps — host Node 24 (mise-managed) satisfies the `>=22.0.0` engine constraint.
- ✅ Active upstream, recent release (`v1.14.1` published 2026-05-27).
- ✅ Topic match (`mcp`, `llm`, `developer-tools`) — within the umbrella's stated scope.
- ✅ Belongs under `tools/` (umbrella's *consumed-tool* tree), not `repos/`. `tools/` is for plumbing the umbrella *uses*; `repos/` is for projects we ship/own/fork as products.
- ⚠️ Upstream does **not** publish GitHub release binaries — only npm + Docker + GHCR. `tools/assets.json` is therefore *not* the right delivery channel (it requires a `https://github.com/.../releases/...` tarball with a sha256). Instead: pin via `npx --yes repomix@<ver>` in the wrapper, with the local clone as the hermetic/audit pin.
- ⚠️ **Stays out of MANIFEST/.gitmodules until forked.** Per user's 2026-05-28 policy: tool clones live in gitignore until the umbrella commits to forking them. Once forked, this dossier's §7 step becomes "promote to `tools/MANIFEST.yaml` + `.gitmodules`."
- ⚠️ Engine is Node `>=22`. Host has Node 24.15.0 via mise → fine.

## 7. Adoption plan

Case: **vendored as gitignored clone — promotion to submodule deferred.**

### What's in scope now (committed)
1. **Wrapper at `tools/bin/repomix`** — pins the npm version via
   `npx --yes repomix@<VERSION>`, honors
   `FLEXNETOS_NO_TOOL_DOWNLOAD=1` to fall back to the local clone.
2. **`scripts/clone-and-pack.sh`** — the umbrella's research-step
   orchestrator. Clones the original upstream into
   `.attic/research-work/<name>/` (gitignored), runs repomix, drops
   pack + compressed pack + summary under
   `data/brain-data/research/<name>/`, and seeds a stub dossier if
   missing.
3. **`Makefile` `research.pack` target** — wraps the script.
4. **`docs/fork-workflow.md` "Step 0" section** — documents the ritual.
5. **`.gitignore` entry** for `tools/repomix/` — clone stays
   uncommitted until forked.
6. **This dossier** — committed under `data/brain-data/research/`.

### Deferred until FlexNetOS forks repomix (out of scope right now)
- Adding an entry to `tools/MANIFEST.yaml`.
- Adding a block to `.gitmodules` (and removing the gitignore line).
- Setting up the fork-and-track branch model (`main` mirrors upstream,
  `develop` carries FlexNetOS changes) per `docs/fork-workflow.md`.

### Hermetic mode bring-up (optional)
- `(cd tools/repomix && npm ci && npm run build)` once, then
  `FLEXNETOS_NO_TOOL_DOWNLOAD=1 tools/bin/repomix --version` should
  succeed without network.

## 8. Sync risk

**Low.**

- Upstream releases roughly monthly. Pin is at the wrapper layer
  (`REPOMIX_VERSION` env var, defaulted to a literal in the script).
- The local clone tracks `main` (shallow). It's gitignored, so the
  umbrella doesn't pin a SHA — operators `git pull` inside
  `tools/repomix/` when they want a fresher build.
- No FlexNetOS patches on the tool. **No fork = no rebase work.**
- API-stability of repomix is good (CLI flags have been backward-
  compatible across the 1.x line).

## 9. Verification

```bash
cd /home/drdave/workspace/my-github

# 1. Wrapper actually runs
tools/bin/repomix --version
tools/bin/repomix --help | head -20

# 2. End-to-end: pack an upstream by URL
scripts/clone-and-pack.sh https://github.com/yamadashy/repomix
test -s data/brain-data/research/repomix/repomix-pack.xml
test -s data/brain-data/research/repomix/repomix-summary.md
```

## 10. Open decisions for user

- [ ] Confirm `tools/repomix/` stays gitignored until/unless we fork
      repomix. (Default in this dossier: yes — matches the
      `feedback-always-commit` + clone-stays-gitignored policy
      established 2026-05-28.)
- [ ] Confirm the wrapper's default version is acceptable
      (`REPOMIX_VERSION=1.14.1` at dossier time). Bumping is a
      one-line change.
- [ ] Confirm scope of "Step 0": packs go under
      `data/brain-data/research/<name>/` per project, **not**
      committed verbatim if they're large. Suggested: commit only
      the `repomix-summary.md`; gitignore the full pack XML unless
      explicitly needed for the wiki. Operator decides per-target.
- [ ] Optional: also expose repomix's MCP server in the umbrella
      (`tools/bin/repomix --mcp`) so agents can request packs
      directly. Low lift; defer until first agent asks for it.

## 11. Decision log

- **2026-05-28** — Initial wiring committed. Tool added as
  **gitignored local clone** (not a submodule) per user policy:
  "We keep the clone in gitignore until it passes from clone to
  fork." MANIFEST/.gitmodules promotion deferred until/unless
  FlexNetOS forks the repo.
- **2026-05-28** — A previous attempt this session vendored repomix
  as a full submodule and was reverted by the user. This dossier
  reflects the corrected approach.
