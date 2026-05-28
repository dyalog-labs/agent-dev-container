# Hooks

Hooks fire on every tool call regardless of what the slash commands say. They are wired up in `.claude/settings.json` as `PreToolUse` handlers.

## What's installed

| Hook | Matches | What it does | Blocking |
|---|---|---|---|
| `block-dangerous-bash.sh` | `Bash` | Deny-list of shell patterns: force-push, push to main, `--no-verify`, test-bypass flags, `rm -rf` at sensitive roots, `curl ... \| sh`, `sudo`, edits to shell rc files, disabling the firewall, `git add` with wildcards or bulk flags, `git commit -a`. | Yes (exit 2) |
| `protect-paths.sh` | `Edit\|Write\|MultiEdit` | Deny-list of paths: `.env*`, `.git/`, `.claude/hooks/`, `.claude/statusline/`, `.claude/settings.json`, credential directories (`.ssh/`, `.gnupg/`, `.aws/`, `.config/gcloud/`), `CLAUDE.local.md`. | Yes (exit 2) |
| `audit-log.sh` | every tool (matcher `""`) | Appends one line per tool call to `.claude/audit.log`. | No (always exit 0) |

## How blocking works

A `PreToolUse` hook that exits 2 stops the tool call. Anything the hook writes to stderr is shown to Claude as feedback. Exit 0 lets the call through. Any other exit code is treated as a hook error and surfaced to the user but does not block.

To verify a hook fires:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | .claude/hooks/block-dangerous-bash.sh
echo "exit: $?"
```

The block message appears on stderr and `exit: 2`.

## What `protect-paths.sh` covers

The hook protects three categories:

- **Kit integrity**: `.claude/hooks/`, `.claude/statusline/`, `.claude/settings.json`. Editing these from inside a hooked session would let a prompt injection disable the safety mechanism.
- **Secrets**: `.env` files at any depth, credential directories (`.ssh/`, `.gnupg/`, `.aws/`, `.config/gcloud/`).
- **Git internals**: anything under `.git/`. Operations on these go through the `git` CLI.

Plus `CLAUDE.local.md`, the user's personal gitignored memory.

## What `protect-paths.sh` does not cover

Project content is not hook-protected. 

## Customising

Edit the scripts directly. After editing `.claude/settings.json`, restart Claude Code. Hook scripts themselves are read fresh on each invocation.

Common adjustments:

- Add language-specific test-bypass flags to `block-dangerous-bash.sh` (the bundled rules cover npm, pnpm, yarn, pytest, go, cargo).
- Add team-specific paths to `protect-paths.sh`: infrastructure-as-code directories, generated code directories, secret-bearing config files.
- Rotate `.claude/audit.log` for long-running use. The file is gitignored by default. Add `.claude/audit.log` to `.gitignore` if it isn't already.
- Add a `Stop` hook that runs the test suite and returns exit 2 on failure. Not included by default.

## Hook scope

Hooks block patterns. They do not judge intent or read context. Logic bugs in code, novel attacks not on the deny-list, and host-level concerns are out of scope for the hook layer. The first two are the reviewer's responsibility; the third is the dev container's.

## When a hook blocks something legitimate

1. Read the stderr message. It names the hook and the pattern.
2. Decide whether the pattern is too broad or whether the action was wrong. The action is usually wrong.
3. If the pattern is too broad, edit the script. Restart Claude Code if `settings.json` changed; hook scripts themselves are read fresh.
4. Do not ask Claude to disable the hook.
