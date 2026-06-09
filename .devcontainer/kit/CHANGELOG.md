# Changelog

All notable changes to the kit are recorded here. Versions follow [Semantic Versioning](https://semver.org/): MAJOR for breaking changes to the workflow or command contracts, MINOR for new commands or hooks, PATCH for fixes that don't change behaviour. While the kit is on `0.x`, expect breaking changes between minor versions.

## [0.7.0] - 2026-06-09

### Added

- `protect-reads.sh`, a `PreToolUse` hook on the `Read` tool. It blocks reading secret files: `.env*`, credential directories (`.ssh/`, `.gnupg/`, `.aws/`, `.config/gcloud/`), private-key and credential files (`*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`, `id_ecdsa`, `id_dsa`, `.netrc`, `.npmrc`, `.pgpass`), and `CLAUDE.local.md`. This closes the read side of the secrets boundary that `protect-paths.sh` already guards on writes.
- `permissions.deny` block in `settings.json` listing the same secret paths for the `Read` tool, as defence-in-depth alongside the hook.
- `block-dangerous-bash.sh` rule (block 10) for writes to protected paths through Bash: redirects, `tee`, `sed -i`, `dd`, `truncate`, `install`, and `cp`/`mv`/`ln`. It fires only when a command both references a protected path and writes, closing the Bash side of the write boundary that `protect-paths.sh` enforces on Edit/Write/MultiEdit.
- `block-dangerous-bash.sh` rule (block 11) for reads of secret files through Bash: a reader command (`cat`, `grep`, `head`, `tail`, `base64`, `xxd`, `sed`, and similar) pointed at `.env`, a credential directory, a private key, or a credential file. This closes the Bash side of the read boundary that `protect-reads.sh` enforces on the Read tool. It is scoped to secrets, so non-secret protected paths (`.claude/settings.json`, `.git/config`) stay readable, and template env files (`.env.example`, `.env.sample`, `.env.template`, `.env.dist`) are exempt. Reads through an interpreter remain out of scope.
- `block-dangerous-bash.sh` rule for `go test -failfast`, the Go analogue of the existing `pytest -x` test-truncation guard.

### Changed

- `protect-paths.sh` now also blocks `.claude/settings.local.json` (merged over `settings.json`, so equally able to rewire hooks or grant permissions) and `.mcp.json` (the MCP server set).

## [0.6.0] - 2026-06-04

### Removed

- The firewall guard in `block-dangerous-bash.sh` (the rule blocking `iptables -F`, `ufw disable`, and `systemctl stop/disable` of `ufw`/`firewalld`). The container configures no egress firewall, so the guard protected nothing and its message described a safety mechanism that is not present. The hook's other deny-list patterns are unchanged.
- `claude-code-workshop-program.md`, the one-day workshop curriculum, from the repo root, together with its references in the top-level `README.md`.

## [0.5.0] - 2026-05-28

### Changed

- Slash-command surface reduced to two commands. `/dyalog:bugfix` (bug investigation, repro, RCA, fix outline) and `/dyalog:crev` (review at any stage: plan, tests-only, implementation, bug fix). Everything else (planning, issue creation, TDD cycles, PR opening) is now ordinary conversation with Claude.
- `docs/` layout flattened. Plans live at `docs/plans/<slug>.md`, bug investigations at `docs/bugs/<id>.md`, PR notes at `docs/prs/<id>.md`, reviews at `docs/reviews/<id>.md`. Previous `docs/plans/{design,bugs,prs,reviews}/` nesting is gone.
- `PROCESS.md` rewritten around the conversational pipeline with two structured stops.

### Removed

- Slash commands `/dyalog:plan`, `/dyalog:plan-review`, `/dyalog:issue`, `/dyalog:proceed`, `/dyalog:chore`, `/dyalog:code-review`, `/dyalog:done`. Their work is now done conversationally or, in the case of code review, by `/dyalog:crev`.
- Subagent `adversarial-reviewer.md`. `/dyalog:crev` invokes the review inline.

## [0.4.x and earlier]

The pre-0.5 kit shipped an eight-command pipeline (`plan`, `plan-review`, `issue`, `proceed`, `chore`, `code-review`, `done`, `bugfix`) plus an adversarial-reviewer subagent. The hooks, skills, status line, dev container, and project conventions listed below all originated in those versions and survive into 0.5.

### Skills (model-triggered)

- `dyalog-docsearch` searches the local Dyalog documentation corpus via the `docsearch` CLI.
- `dyalog-script` executes APL code via `dyalogscript`.

### Hooks

- `block-dangerous-bash.sh` denies force-push, `--no-verify`, test bypass flags, `git add` wildcards, and similar foot-guns.
- `protect-paths.sh` denies edits to `.env`, `.git/`, `.claude/hooks/`, `.claude/statusline/`, `.claude/settings.json`, lockfiles, `CLAUDE.local.md`, and similar files.
- `audit-log.sh` records every tool call to `.claude/audit.log` (non-blocking).

### Statusline

- Custom three-segment status line: git branch, context-window usage, auto-compact headroom.

### Dev container

- `.devcontainer/` with a Dockerfile that installs Node 20, .NET 8, Go 1.24, Python 3, Dyalog APL 20, LSP servers for TypeScript / C# / Go / Python, the GitHub CLI, `jq`, `delta`, oh-my-zsh, and the Claude Code CLI.
- `csharp-ls` pinned to `0.16.0` and made non-fatal because the publisher has occasionally pushed broken NuGet packages.
- The kit itself baked into the image at `/opt/agent-dev-container/` with an `install-kit-here` bootstrap script for adding the kit to projects that don't have it.

### Project conventions (CLAUDE.md)

- Branch naming `<issue-id>-<slug>`.
- Writing style: invariants over narrative, no emojis, no em-dashes, no en-dashes, no bold in commit/PR/issue text, UK English, professional tone, concise.
- Per-cycle commits, agent commits its own work.
- Definition of done: all tests pass, linters pass, PR doc honest, latest review is `approved`.

### Documentation

- `PROCESS.md` walks through a feature from idea to merged PR using the kit.
- `CLAUDE.md` is the project memory loaded into every session.
- `.claude/README.md` documents the settings.json choices.
- `.claude/commands/README.md` describes what the slash commands do and what is not a slash command.
- `.devcontainer/README.md` explains the container and the kit integration.
- `claude-code-workshop-program.md` is the one-day workshop curriculum.

### Known limitations

- The C# LSP (`csharp-ls`) is pinned to an old version because the publisher's recent releases have shipped broken NuGet packages. C# LSP support degrades gracefully (build succeeds without it) if even the pinned version fails.
- The hooks block `git add` wildcards. Every staged path must be spelled out. This is deliberate; downstream tooling that runs `git add .` will fail.
