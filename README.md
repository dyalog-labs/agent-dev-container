# agent-dev-container

A reproducible dev container, a slim Claude Code configuration, and a one-day workshop curriculum for using Claude Code (and other AI coding agents) safely on day-to-day software work.

**Version:** see [`VERSION`](VERSION). **Licence:** MIT.

## What's here

- **`.devcontainer/`** builds a Docker image with Node 20, .NET 8, Go 1.24, Python 3, Dyalog APL 20, LSP servers for all of them, the GitHub CLI, `jq`, `git-delta`, oh-my-zsh, and the Claude Code CLI. Two named volumes preserve Claude Code's user-level config and shell history across rebuilds.
- **`.devcontainer/kit/`** is the master copy of the Claude Code configuration ("the kit") that gets baked into the image at `/opt/agent-dev-container/`. It contains the project conventions (`CLAUDE.md`), the day-to-day workflow (`PROCESS.md`), and a `.claude/` tree with hooks, skills, a status line, an audit log, and two slash commands (`/dyalog:bugfix`, `/dyalog:crev`).
- **`claude-code-workshop-program.md`** is the one-day curriculum that walks attendees through the layers (container → permissions → CLAUDE.md → skills → subagents → hooks) and then puts them through a constrained TDD loop using the kit.

## Quick start

Clone this repository and open it in VS Code with the Dev Containers extension installed. VS Code prompts "Reopen in Container"; the first build takes 5 to 10 minutes, subsequent opens are seconds.

To work on your own project inside the container:

```
cd /workspace/your-project
install-kit-here
claude
```

`install-kit-here` copies `CLAUDE.md`, `PROCESS.md`, and `.claude/` from `/opt/agent-dev-container/` into your project root, preserving permissions on the hook and statusline scripts. Restart Claude Code so the hooks, statusline, and project commands load.

`/dyalog:bugfix <issue>` investigates a bug end-to-end. `/dyalog:crev <issue-or-path>` reviews work at any stage. Everything else (planning, issue creation, TDD cycles, PR opening) is ordinary conversation with Claude. See `.devcontainer/kit/PROCESS.md` for the walkthrough.

## Layout

```
.
├── README.md                              this file
├── VERSION                                semver version of the kit baked into the image
├── LICENSE                                MIT
├── claude-code-workshop-program.md        one-day workshop curriculum (delete if not running the workshop)
├── .gitignore
└── .devcontainer/
    ├── README.md                          dev container reference: mounts, env vars, troubleshooting
    ├── Dockerfile                         multi-runtime image with Claude Code
    ├── devcontainer.json                  VS Code dev container config
    ├── install-kit-here.sh       bootstrap script: drops the kit into a project root inside the container
    └── kit/                               master copy of CLAUDE.md, PROCESS.md, .claude/, baked into the image
```

The kit is held in `.devcontainer/kit/` rather than at the repo root because it ships baked into the dev container image. The repo's root is the host directory for the image and curriculum, not a working project.

## Working on the kit itself

Edit files under `.devcontainer/kit/`. Rebuild the image to pick up the changes (`Reopen in Container → Rebuild`). The repo root has no `.claude/` and no `CLAUDE.md` of its own; opening this repo in Claude Code does not auto-load the kit's hooks or commands. To dry-run the kit, `install-kit-here` into a scratch project mounted as a workspace.

## Adopting the kit without the dev container

If you want the kit but not the container, copy `.devcontainer/kit/CLAUDE.md`, `.devcontainer/kit/PROCESS.md`, and `.devcontainer/kit/.claude/` into your project root, `chmod +x .claude/hooks/*.sh .claude/statusline/*.sh`, merge `.devcontainer/kit/.gitignore` into your `.gitignore`, and ensure `jq`, `git`, and `gh` are installed locally. Restart Claude Code.

## Versioning

The kit follows [Semantic Versioning](https://semver.org/). `VERSION` at this repo's root tracks the kit version that the dev container image bakes in. The kit's own changelog is at `.devcontainer/kit/CHANGELOG.md`.

While the kit is `0.x`, expect breaking changes between minor versions.

## Reporting issues, contributing

Issues and PRs welcome at https://github.com/dyalog-labs/agent-dev-container/issues. When filing, include the `VERSION` (or, for projects bootstrapped via `install-kit-here`, the `KIT_VERSION` recorded at install time).
