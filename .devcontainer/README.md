# Agent dev container

A multi-runtime dev container for working with Claude Code (and AI coding agents generally). Used as the platform for the "Claude Code, safely and effectively" workshop, and reusable outside it.

## What's installed

- Node.js 20, .NET 8, Go 1.24, Python 3 with pipx, Dyalog APL 20
- LSP servers for TypeScript, C#, Go, Python
- `gh` (GitHub CLI), `jq`, `fzf`, `git-delta`, zsh with oh-my-zsh
- Claude Code CLI, pinned to auto-update
- The kit (`CLAUDE.md`, `PROCESS.md`, `.claude/`) baked into the image at `/opt/agent-dev-container/`

## Installing the kit into a project

The kit is project-level configuration and belongs at the root of each project. A read-only master copy lives at `/opt/agent-dev-container/` in the container, with a wrapper on `PATH`:

```
cd /workspace/my-project
install-kit-here
```

`install-kit-here` copies `CLAUDE.md`, `PROCESS.md`, and `.claude/` into the current directory. If any of these files already exist, the script lists the conflicts and stops without overwriting.

After installing, restart Claude Code (or reload the window) to load the hooks, statusline, and project commands.

## What lives where

| Path | Purpose | Volume |
|---|---|---|
| `/workspace/<project>/CLAUDE.md` | project conventions | bind-mounted to host workspace |
| `/workspace/<project>/.claude/` | project commands, hooks, statusline | bind-mounted to host workspace |
| `/home/node/.claude/` | Claude Code's user-level config (auth, settings) | persistent volume `claude-code-config-<id>` |
| `/commandhistory/` | shell history | persistent volume `claude-code-bashhistory-<id>` |
| `/opt/agent-dev-container/` | read-only master copy of the kit | baked into image |

Claude Code merges user-level (`/home/node/.claude/`) and project-level (`/workspace/<project>/.claude/`) configuration: user-level for auth and global preferences, project-level for commands, hooks, statusline, and the agent.

## Customising for your stack

`.claude/settings.json` enables LSP plugins for TypeScript and Python out of the box. To use C# or Go, add to `enabledPlugins` after installing the kit:

```json
"enabledPlugins": {
  "typescript-lsp@claude-plugins-official": true,
  "pyright@claude-plugins-official": true,
  "gopls@claude-plugins-official": true,
  "csharp-ls@claude-plugins-official": true
}
```

Plugin names follow the `claude-plugins-official` registry. Confirm with `/plugin list` if a name does not resolve.

The VS Code extensions list in `devcontainer.json` is TypeScript-leaning (`eslint`, `prettier`, `gitlens`). Add `ms-dotnettools.csharp` for C#, `dyalog.apl` for APL, etc.

## Environment variables

- `TZ` (default `Europe/London`): overridden by host `TZ` if set.
- `GH_TOKEN`: forwarded from the host via `remoteEnv` for `gh`. See "GitHub authentication" in the top-level [`README.md`](../README.md) for setup and fine-grained-token guidance.

## Architecture support

The Dockerfile detects `dpkg --print-architecture` and pulls the right binary for Dyalog, Go, and git-delta on `amd64` and `arm64`. Other architectures (s390x, ppc64le) are not supported; the build exits with an error.

## Troubleshooting

**`claude` not found at runtime.** Run `which claude` and re-source the shell rc.

**`bundle-docs` build fails.** The APL documentation tooling needs CGO and the fts5 build tag. Install `libsqlite3-dev` via apt if the Go build complains about missing sqlite3 headers.

**Hooks not firing.** `.claude/hooks/*.sh` need the executable bit. The install script preserves this with `cp -p`. If files were copied another way: `chmod +x .claude/hooks/*.sh .claude/statusline/*.sh`.

**Statusline shows `(install jq for a working status line)`.** Check `which jq` and the `PATH`. `jq` is installed via apt in this container.
