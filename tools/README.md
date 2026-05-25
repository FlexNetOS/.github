# `tools/` — per-toolchain shared configuration

Each subdirectory here is a **git submodule** pointing at a small,
focused FlexNetOS repo that holds shared lint/format/type/build configs
for one language ecosystem. Any FlexNetOS project can opt-in by
symlinking or copying the configs it needs.

## The four (planned) repos

| Path | Repo | Provides |
| --- | --- | --- |
| `tools/node/` | `FlexNetOS/node-tools` | ESLint flat-config, Prettier, tsconfig presets, package.json template, husky/lint-staged |
| `tools/cargo/` | `FlexNetOS/cargo-tools` | `rustfmt.toml`, `clippy.toml`, `deny.toml`, `Cargo.toml` template, `.cargo/config.toml` |
| `tools/python/` | `FlexNetOS/python-tools` | `ruff.toml`, `pyproject.toml` template, `uv` config, pyright `pyrightconfig.json` |
| `tools/shell/` | `FlexNetOS/shell-tools` | `.shellcheckrc`, `.shfmt`, shared bash fragments, POSIX-shell linter wrapper |

These repos do **not exist yet** — they get created at the same time
as the submodule add. See "Bootstrapping a new tools repo" below.

## Why separate repos and not just files in this umbrella

- **Adopt incrementally.** A FlexNetOS project that wants only the
  Rust configs adds `FlexNetOS/cargo-tools` as its own submodule
  (under whatever path makes sense) and ignores the rest.
- **Each tools repo cuts its own releases.** When `cargo-tools`
  upgrades to a new rustfmt config, downstream projects bump the
  submodule pin on their own schedule.
- **Dependabot reach.** Dependabot at each tools repo watches its
  ecosystem; consumers bump via their own dependabot configs.
- **Independent CI.** Tools repos test their configs against a small
  matrix of fixture projects without weighing down the umbrella.

## Layout of each tools repo

Standardized so consumers know what to expect:

```text
<tools-repo>/
├── README.md             what's in here + how to consume
├── Makefile              `make install TARGET=/path/to/project` symlinks
├── install.sh            same, as a script (for non-make builds)
├── configs/              the actual config files (one per tool)
│   ├── eslint.config.mjs   (node)
│   ├── prettier.config.mjs
│   ├── tsconfig.base.json
│   └── …
├── templates/            scaffolding (cargo generate / cookiecutter / etc.)
│   ├── basic/            minimal starter
│   └── full/             everything-on starter
└── docs/                 brief notes per tool: what changed vs upstream defaults
```

## Bootstrapping a new tools repo (one-time, per language)

```bash
# 1. Create the repo on GitHub
gh repo create FlexNetOS/node-tools --public \
  --description "Shared Node/TypeScript configs for FlexNetOS projects"

# 2. Initialize locally
cd /tmp
git clone https://github.com/FlexNetOS/node-tools && cd node-tools
mkdir -p configs templates docs
# … populate from existing per-project configs we've been hand-copying …
git add -A && git commit -m "feat: initial scaffold"
git push

# 3. Submodule it into the umbrella
cd /path/to/my-github
git submodule add https://github.com/FlexNetOS/node-tools tools/node
git commit -m "feat(tools): add node-tools submodule"
```

## How a downstream project consumes these

Two patterns:

### Pattern A — submodule the tools repo directly

The downstream project adds the tools repo as its own submodule:

```bash
cd my-rust-project
git submodule add https://github.com/FlexNetOS/cargo-tools .tools/cargo
ln -s .tools/cargo/configs/rustfmt.toml rustfmt.toml
ln -s .tools/cargo/configs/clippy.toml clippy.toml
```

When the tools repo updates, the project does `git submodule update --remote .tools/cargo`.

### Pattern B — vendor a pinned snapshot

For projects where a submodule is overkill, copy the configs at a
specific tag and check them in:

```bash
curl -fsSL https://raw.githubusercontent.com/FlexNetOS/cargo-tools/v1.2.0/configs/rustfmt.toml \
  > rustfmt.toml
```

Pattern A is preferred — it keeps the link explicit and bumpable in
one place.

## Versioning

Each tools repo follows Conventional Commits and uses the umbrella's
`reusable-release.yml` to cut semver tags (`v1.0.0`, `v1.1.0`, …).
Downstream consumers pin to a major tag (`@v1`) or to a specific tag,
NOT to `main`. Pinning to `main` makes every config tweak a potential
breaking change for every consumer.

## When to fold a config back into per-project

If a tools-repo config diverges noticeably between projects (e.g.
ruvector needs stricter clippy than ruOS), the right move is to
**carry the override locally** in the diverging project, not to fork
the tools repo. The shared repo holds the common subset.
