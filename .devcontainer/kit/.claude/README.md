# `.claude/settings.json`

Project-level Claude Code configuration. Applies to anyone who opens this repo and runs Claude Code from it.

## What's set

### `attribution`

```json
"attribution": {
  "commit": "",
  "pr": ""
}
```

Suppresses the `Co-Authored-By: Claude <noreply@anthropic.com>` trailer in commit messages and the "Generated with Claude Code" footer in PR descriptions. `CLAUDE.md` requires commit messages to be invariant statements about the code; AI bylines violate that rule.

### `env.ENABLE_LSP_TOOL`

```json
"env": {
  "ENABLE_LSP_TOOL": "1"
}
```

Enables Claude Code's Language Server Protocol integration. With LSP, Claude uses the language server for semantic queries (`findReferences`, `goToDefinition`, `hover`, `documentSymbol`) instead of grep. Without `ENABLE_LSP_TOOL=1` the plugins below have no effect.

### `enabledPlugins`

```json
"enabledPlugins": {
  "typescript-lsp@claude-plugins-official": true,
  "pyright@claude-plugins-official": true
}
```

Enables LSP plugins for TypeScript/JavaScript and Python. Plugin installation is a separate step: each plugin must be installed once via `/plugin install <name>` before it can be enabled here.

**To add a language**: add the plugin here and install the corresponding language-server binary. Plugins in the official marketplace (search `lsp` under `/plugin Discover`): `typescript-lsp`, `pyright`, `gopls-lsp`, `rust-analyzer-lsp`, `clangd-lsp`, `kotlin-lsp`, `php-lsp`, `ruby-lsp`, `csharp-lsp`, `java-lsp`.

**Required binaries on PATH** for the default languages:

- `typescript-language-server` (`npm i -g typescript-language-server typescript`)
- `pyright` (`npm i -g pyright` or `pip install pyright`)

Both are installed by the dev container. To verify: `which typescript-language-server` and `which pyright`.

### `hooks`

The four kit hooks. See `.claude/hooks/README.md`.

### `permissions`

```json
"permissions": {
  "deny": [
    "Read(./.env)",
    "Read(**/.env)",
    "Read(**/.ssh/**)",
    "Read(**/*.pem)",
    "Read(**/id_rsa)",
    "Read(**/CLAUDE.local.md)"
  ]
}
```

A `deny` list (abbreviated above) that stops the `Read` tool opening secret files: `.env` files, credential directories, private keys, and `CLAUDE.local.md`. This is defence-in-depth alongside `protect-reads.sh`, which enforces the same paths as a `PreToolUse` hook. The Bash side is covered by `block-dangerous-bash.sh` block 11, which blocks reader commands (`cat`, `grep`, `base64`, ...) pointed at a secret; reads through an interpreter (`python -c`) remain the container's boundary. See `.claude/hooks/README.md`.

### `statusLine`

```json
"statusLine": {
  "type": "command",
  "command": "$CLAUDE_PROJECT_DIR/.claude/statusline/statusline.sh",
  "padding": 0
}
```

A custom status line shown at the bottom of the Claude Code terminal. Three fields, in order:

1. **Current git branch**, read from the workspace `cwd`. Detached HEADs show as `detached@<sha>`; non-git directories show as `no-git`. Branch names are coloured cyan.
2. **Context usage**, the percentage of the context window in use plus raw token counts (e.g. `ctx 62% (124k/200k)`). Green under 50%, yellow under 80%, red beyond. Counts input + cache-creation + cache-read tokens; excludes output tokens.
3. **Auto-compact headroom**, the percentage of the window remaining before auto-compact fires (e.g. `33% to auto-compact`). Auto-compact triggers at 95% of the window. Dim under healthy levels, yellow under 30% headroom, red under 10%, and `auto-compact imminent` when overshot.

The script is at `.claude/statusline/statusline.sh`. The `protect-paths.sh` hook blocks edits to it.

**To customise**: edit the script. Knobs at the top: `AUTO_COMPACT_THRESHOLD` (default 95) and the ANSI colour variables. Comment out a colour value to render the field plain.

**Dependencies**: `jq` and `git`. The dev container installs both. If `jq` is missing, the status line prints a one-time hint and exits cleanly.

## Verifying LSP is working

With the relevant language servers installed, after Claude Code starts:

1. Open a TypeScript or Python file.
2. Ask Claude to find references to a function defined in that file ("find all callers of `validateEmail`").
3. In the response, Claude should invoke an `LSP` tool (`findReferences`, `goToDefinition`, `hover`, `documentSymbol`) and return file:line locations directly.

If Claude falls back to `Grep` and `Read`, LSP is not connecting. Common causes:

- `ENABLE_LSP_TOOL` not set (`echo $ENABLE_LSP_TOOL` inside the dev container).
- Language server binary not on PATH (`which <binary-name>`).
- Plugin installed but not enabled (`/plugin list` should show it as enabled).
- Claude Code was not restarted after the plugin was enabled.

If LSP fails to connect despite correct configuration, restart Claude Code.

## Out of scope for this file

- **Broad permission rules.** The `permissions.deny` list here is scoped to read-protection for secret files. Wider allow/ask decisions are made interactively or through plan/auto/bypass modes.
- **MCP servers.** The pipeline uses the `gh` CLI. Add MCP servers here if you adopt them.
- **`disableBypassPermissionsMode` enforcement.** A managed-settings concern.

## Customising for your team

Settings precedence: project settings (this file) are merged with user settings (`~/.claude/settings.json`) and managed settings (deployed by org admins). For a real team:

- Move the kit hooks into a plugin so they ship with updates.
- Move LSP plugin choices into per-developer user settings if your team works across many language stacks.
- Keep `attribution` in project settings; it is team policy, not personal preference.
