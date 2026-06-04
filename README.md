# agent-dev-container

A reproducible dev container and a slim Claude Code configuration for using Claude Code (and other AI coding agents) safely on day-to-day software work.

**Version:** see [`VERSION`](VERSION). **Licence:** MIT.

## What's here

- **`.devcontainer/`** builds a Docker image with Node 20, .NET 8, Go 1.24, Python 3, Dyalog APL 20, LSP servers for all of them, the GitHub CLI, `jq`, `git-delta`, oh-my-zsh, and the Claude Code CLI. Two named volumes preserve Claude Code's user-level config and shell history across rebuilds.
- **`.devcontainer/kit/`** is the master copy of the Claude Code configuration ("the kit") that gets baked into the image at `/opt/agent-dev-container/`. It contains the project conventions (`CLAUDE.md`), the day-to-day workflow (`PROCESS.md`), and a `.claude/` tree with hooks, skills, a status line, an audit log, and two slash commands (`/dyalog:bugfix`, `/dyalog:crev`).

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

## Windows users

The dev container runs on Windows through Docker Desktop's WSL2 backend. The setup that causes the fewest sharp edges:

1. Install Docker Desktop and enable the WSL2 backend (Settings → General → "Use the WSL 2 based engine"). Under Settings → Resources → WSL integration, enable the WSL2 distribution you intend to use.
2. Install VS Code with the "Dev Containers" and "WSL" extensions.
3. Clone this repository inside the WSL2 filesystem, not under `/mnt/c/`. From a WSL2 shell: `cd ~ && git clone https://github.com/dyalog-labs/agent-dev-container.git`. Bind-mounting from `/mnt/c/` over 9P has order-of-magnitude worse I/O and does not preserve Unix permission bits, which breaks the executable hook scripts.
4. Open the folder from inside WSL2: run `code .` in the WSL2 shell, then "Reopen in Container".

For `GH_TOKEN` (see [GitHub authentication](#github-authentication) below), export it in the WSL2 shell's startup file (`~/.zshrc` or `~/.bashrc` inside the distro), not as a Windows environment variable. VS Code launched from WSL2 inherits the WSL2 environment, and `remoteEnv` in `devcontainer.json` forwards that environment into the container.

If you must clone under `/mnt/c/` (for a Windows-side editor, say) and open through Docker Desktop without WSL2 integration, configure git globally before cloning so shell scripts under `.claude/hooks/` and `.claude/statusline/` keep their LF line endings; otherwise they fail silently inside the container:

```
git config --global core.autocrlf input
```

## GitHub authentication

The kit invokes `gh` for issue context inside `/dyalog:bugfix` and `/dyalog:crev`, for PR diffs and checks during review, and for opening pull requests at the end of a cycle. Inside the container, `gh` reads `GH_TOKEN` from the environment; `.devcontainer/devcontainer.json` forwards `GH_TOKEN` from the host into the container via `remoteEnv`.

Export the token in your host shell's startup file before opening the container:

```sh
export GH_TOKEN="github_pat_..."
```

A new terminal (or `source ~/.zshrc`) followed by "Reopen in Container" is enough. `remoteEnv` is read once at container start, so if the container is already running with no token or an old one, rebuild to pick up the new value.

Verify inside the container:

```
gh auth status
gh repo view
```

If `GH_TOKEN` is unset, `gh` falls back to browser-based device-code auth on first use. That works, but the resulting credentials live in `~/.config/gh/` rather than on a persistent volume, so they vanish whenever the container is rebuilt, and the token has broader scope than the steps below require.

### Fine-grained tokens, scoped to one repository

Prefer a fine-grained personal access token over a classic one. A classic `repo`-scoped token grants access to every repository the account can see; a fine-grained token can be restricted to a single repository and to the minimum permissions the kit actually needs.

Create one at Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. The relevant choices:

- Repository access: "Only select repositories" → pick the project this container will work on.
- Repository permissions:
  - Contents (read and write): push commits, create branches.
  - Issues (read and write): read issue bodies for `/dyalog:bugfix` and `/dyalog:crev`; create or comment on issues from conversation.
  - Pull requests (read and write): open PRs, read diffs and comments.
  - Actions (read): only if you use `gh pr checks` or `gh run view`.
  - Metadata (read): required by GitHub, added automatically.
- Expiry: the shortest period you can tolerate. 30 to 90 days is reasonable.

If the target repository is owned by an organisation that enforces SAML SSO, authorise the token for the org after creation (token page → Configure SSO → authorise the org). Until that step, `gh` returns a 403 with a SAML hint.

A token restricted to one repository means one token per project. For multiple repositories in the same container, either rotate `GH_TOKEN` between sessions or broaden the token to a small, trusted set of repositories. Avoid classic tokens for shared or workshop machines: a single leak exposes every repository the account can see.

## Layout

```
.
├── README.md                              this file
├── VERSION                                semver version of the kit baked into the image
├── LICENSE                                MIT
├── .gitignore
└── .devcontainer/
    ├── README.md                          dev container reference: mounts, env vars, troubleshooting
    ├── Dockerfile                         multi-runtime image with Claude Code
    ├── devcontainer.json                  VS Code dev container config
    ├── install-kit-here.sh       bootstrap script: drops the kit into a project root inside the container
    └── kit/                               master copy of CLAUDE.md, PROCESS.md, .claude/, baked into the image
```

The kit is held in `.devcontainer/kit/` rather than at the repo root because it ships baked into the dev container image. The repo's root is the host directory for the image, not a working project.

## Working on the kit itself

Edit files under `.devcontainer/kit/`. Rebuild the image to pick up the changes (`Reopen in Container → Rebuild`). The repo root has no `.claude/` and no `CLAUDE.md` of its own; opening this repo in Claude Code does not auto-load the kit's hooks or commands. To dry-run the kit, `install-kit-here` into a scratch project mounted as a workspace.

## Adopting the kit without the dev container

If you want the kit but not the container, copy `.devcontainer/kit/CLAUDE.md`, `.devcontainer/kit/PROCESS.md`, and `.devcontainer/kit/.claude/` into your project root, `chmod +x .claude/hooks/*.sh .claude/statusline/*.sh`, merge `.devcontainer/kit/.gitignore` into your `.gitignore`, and ensure `jq`, `git`, and `gh` are installed locally. Restart Claude Code.

## Versioning

The kit follows [Semantic Versioning](https://semver.org/). `VERSION` at this repo's root tracks the kit version that the dev container image bakes in. The kit's own changelog is at `.devcontainer/kit/CHANGELOG.md`.

While the kit is `0.x`, expect breaking changes between minor versions.

## Reporting issues, contributing

Issues and PRs welcome at https://github.com/dyalog-labs/agent-dev-container/issues. When filing, include the `VERSION` (or, for projects bootstrapped via `install-kit-here`, the `KIT_VERSION` recorded at install time).
