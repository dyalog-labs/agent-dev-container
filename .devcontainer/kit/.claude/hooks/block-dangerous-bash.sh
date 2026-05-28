#!/usr/bin/env bash
#
# block-dangerous-bash.sh
# Fires on PreToolUse for the Bash tool. Blocks commands that match a deny-list
# of irreversible or test-bypassing patterns.
#
# Exit codes:
#   0 = allow
#   2 = block (stderr is shown to Claude as feedback)
#
# Reads JSON from stdin in the shape:
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }

set -euo pipefail

# Read stdin once.
input=$(cat)

# Extract the command. If jq isn't available, fall back to grep, but jq is
# strongly preferred and ships in the agent-dev-container.
if command -v jq >/dev/null 2>&1; then
  command=$(echo "$input" | jq -r '.tool_input.command // empty')
else
  command=$(echo "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

# No command extracted? Don't block, could be a malformed payload, let it through
# and let Claude Code's own validation handle it.
if [[ -z "${command}" ]]; then
  exit 0
fi

# Helper: emit a blocking message to stderr and exit with code 2.
block() {
  local reason="$1"
  cat >&2 <<EOF
[hook: block-dangerous-bash] BLOCKED.
Reason: ${reason}
Command: ${command}

This action is forbidden by a project hook. If you believe this is wrong,
ask the user, they can edit .claude/hooks/block-dangerous-bash.sh and
restart Claude Code. Do NOT attempt to work around the hook.
EOF
  exit 2
}

# ──────────────────────────────────────────────────────────────────────────
# Deny patterns. Order matters: most specific first so error messages are useful.
# ──────────────────────────────────────────────────────────────────────────

# 1. Force-push to any branch. Never warranted from an agent.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+push[[:space:]].*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$))'; then
  block "git push with --force / --force-with-lease / -f. Force pushes are not allowed from Claude. The human pushes if a force-push is genuinely needed."
fi

# 2. Push directly to main / master / develop. Feature branches only.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+push[[:space:]]+\S+[[:space:]]+(main|master|develop)([[:space:]]|$)'; then
  block "git push targeting main/master/develop directly. Open a PR instead."
fi

# 3. Skipping commit hooks.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+commit[[:space:]].*--no-verify'; then
  block "git commit --no-verify. Pre-commit hooks exist for a reason. Fix the failure, don't bypass it."
fi

# 3a. git add with bulk flags. Force file-by-file staging so unrelated changes
# don't sneak into commits. Allowed: explicit paths and `git add -p` (interactive
# patch mode is explicit by nature).
#
# Block:  git add .
#         git add -A | --all | -A . | --all .
#         git add -u | --update
#         git add :/   (top-level pathspec magic)
#         git add <anything containing a glob char: *, ?, [>
# Allow:  git add path/to/file [path/to/another]
#         git add -p [path]
#         git add --patch [path]
#         git add -i (interactive, same selectivity guarantee as -p)

# 3a-i. Block `git add .` (the bare `.` argument). Has to come before the
# glob check because `.` isn't a glob char but is just as bulk.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+add([[:space:]]+[^[:space:]]+)*[[:space:]]+\.([[:space:]]|$)'; then
  block "git add with a bare '.' adds everything in the current directory, including files you didn't touch as part of this issue. Stage each changed file by path."
fi

# 3a-ii. Block bulk flags: -A, --all, -u, --update.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+add[[:space:]].*(-A|--all|--update)([[:space:]]|$)'; then
  block "git add -A / --all / --update stages files in bulk. Stage each changed file by path so unrelated changes don't enter the commit."
fi
# Catch `-u` separately, has to not collide with combined flags. `git add -u` is
# the dangerous form. Standalone `-u` short flag, no other chars attached.
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+add([[:space:]]+\S+)*[[:space:]]+-u([[:space:]]|$)'; then
  block "git add -u stages all modifications to tracked files. Stage each changed file by path."
fi

# 3a-iii. Block glob characters in any pathspec argument: *, ?, [
# Allowed:  git add src/users.ts
# Blocked:  git add src/*  |  git add 'src/*.ts'  |  git add 'tests/[!u]*'
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+add([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^[:space:]]*[*?[]'; then
  block "git add with a glob (*, ?, [) hides which files are being staged. Spell out each path explicitly."
fi

# 3a-iv. Block magic pathspec `:/` (means "everything from the repo root").
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+add([[:space:]]+\S+)*[[:space:]]+:/?([[:space:]]|$)'; then
  block "git add :/ uses pathspec magic to stage from the repo root. Stage each changed file by path."
fi

# 3b. git commit -a / --all. Same problem as `git add -A`: silently picks up
# every modified tracked file, including ones unrelated to the issue.
# Allowed: git commit -m "..." (with explicit prior `git add <paths>`)
# Blocked: git commit -a, git commit --all, git commit -am "...", git commit -ma "..."
if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+commit[[:space:]].*(--all([[:space:]]|$)|-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$))'; then
  block "git commit -a / --all bypasses the staging step and commits every modified tracked file. Stage changed files individually with 'git add <path>', then commit."
fi

# 4. Test bypass flags. Bail / fail-fast / exit-on-first-failure are fine in
# normal use, but the definition-of-done is "the full suite passes". We catch
# the common abuse patterns here so a final test run does not silently truncate.
if echo "$command" | grep -qE '(npm|pnpm|yarn)[[:space:]]+(run[[:space:]]+)?test[[:space:]].*--bail'; then
  block "Test runner invoked with --bail. The full suite must run before work is considered done. Fix failing tests, don't truncate the run."
fi

if echo "$command" | grep -qE '(^|[[:space:];&|])(pytest|python[[:space:]]+-m[[:space:]]+pytest)[[:space:]].*(-x|--exitfirst|--maxfail)'; then
  block "pytest invoked with -x / --exitfirst / --maxfail. The full suite must run before work is considered done. Fix failing tests, don't truncate the run."
fi

# 5. Recursive deletes at the filesystem root or home directory. Belt-and-braces
#, the dev container should prevent damage, but blocking these explicitly stops
# Claude from even trying.
if echo "$command" | grep -qE '(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+|-r[[:space:]]+|-rf[[:space:]]+|-fr[[:space:]]+)(/|/\*|~|~/|\$HOME)([[:space:]]|$)'; then
  block "rm -rf targeting /, /*, \$HOME or ~. Refusing on principle."
fi

# 6. Recursive deletes inside .git. Destroys the repo's history.
if echo "$command" | grep -qE '(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+|-rf?[[:space:]]+).*\.git([[:space:]/]|$)'; then
  block "rm -rf on .git. The repo's history is not something the agent destroys."
fi

# 7. Piping curl/wget straight to a shell. Classic supply-chain risk.
if echo "$command" | grep -qE '(curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|fish)([[:space:]]|$)'; then
  block "Piping curl/wget to a shell. Download the script, read it, then ask the user before running it."
fi

# 8. sudo. Inside the dev container there is no legitimate reason for an agent
# to need root.
if echo "$command" | grep -qE '(^|[[:space:];&|])sudo([[:space:]]|$)'; then
  block "sudo. The container already has the permissions Claude needs. If you genuinely need root, tell the user and let them run it."
fi

# 9. Modifying shell rc files outside the workspace.
if echo "$command" | grep -qE '>>?[[:space:]]*~/\.(bashrc|zshrc|profile|bash_profile)([[:space:]]|$)'; then
  block "Writing to shell rc files (~/.bashrc, ~/.zshrc, etc.). Not within scope of an agentic coding task."
fi

# 10. Disabling the firewall.
if echo "$command" | grep -qE '(iptables[[:space:]]+-F|ufw[[:space:]]+disable|systemctl[[:space:]]+(stop|disable)[[:space:]]+(ufw|firewalld))'; then
  block "Disabling the firewall. The egress firewall is part of the container's safety model. Hands off."
fi

# All checks passed.
exit 0
