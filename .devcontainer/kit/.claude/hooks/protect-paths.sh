#!/usr/bin/env bash
#
# protect-paths.sh
# Fires on PreToolUse for Edit / Write / MultiEdit. Blocks modifications to
# paths the agent should never touch.
#
# Scope: this hook enforces three categories.
#   1. Kit integrity, the agent must not edit the safety mechanism itself
#      (hooks, statusline, settings.json).
#   2. Security boundary, secrets and credentials are off-limits regardless
#      of intent.
#   3. Git internals, edits to .git/ go through the git CLI, not file edits.
#
# Out of scope: project content like CI workflows, dev container config, and
# lockfiles. These are legitimate edits in normal work and are policed by
# human and agent review, not the hook. A review has context the hook does
# not, it can judge whether the change is sensible.
#
# Exit codes:
#   0 = allow
#   2 = block (stderr is shown to Claude as feedback)
#
# Input JSON shape:
#   { "tool_name": "Edit"|"Write"|"MultiEdit",
#     "tool_input": { "file_path": "...", ... }, ... }

set -euo pipefail

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  tool=$(echo "$input" | jq -r '.tool_name // empty')
  path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
else
  # Fallback parsing, the agent-dev-container has jq, but in case it doesn't.
  tool=$(echo "$input" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')
  path=$(echo "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')
fi

# Nothing to check, let it through.
if [[ -z "${path}" ]]; then
  exit 0
fi

# Normalise: strip leading ./, collapse a workspace prefix if present.
# We work with the path as Claude sees it; the deny-list patterns below match
# both absolute and relative forms.
block() {
  local reason="$1"
  cat >&2 <<EOF
[hook: protect-paths] BLOCKED ${tool} on: ${path}
Reason: ${reason}

This path is protected by a project hook. If the user genuinely wants this
change, they will make it themselves. Do not attempt to work around the hook
(no shell redirects, no sed in Bash, no creative renames).
EOF
  exit 2
}

# ──────────────────────────────────────────────────────────────────────────
# Deny-list. Add to this for your team's specific protected paths.
# ──────────────────────────────────────────────────────────────────────────

# 1. Environment files at any depth. Secrets live here.
if [[ "$path" =~ (^|/)\.env(\.[^/]+)?$ ]]; then
  block ".env files hold secrets and are not edited by an agent."
fi

# 2. Anything inside .git/. Operations on git internals go through the git CLI,
# never through file edits.
if [[ "$path" =~ (^|/)\.git/ ]]; then
  block "Files under .git/ are managed by git itself, not edited directly."
fi

# 3. The hooks directory and statusline directory. Disabling hooks or
# hijacking the statusline from inside a hooked session would be a prompt-
# injection's dream. Both are edited by humans, out-of-band.
# settings.local.json is merged over settings.json, so it can grant permissions
# or rewire hooks just as effectively and is protected on the same footing.
if [[ "$path" =~ (^|/)\.claude/hooks/ ]] \
   || [[ "$path" =~ (^|/)\.claude/statusline/ ]] \
   || [[ "$path" =~ (^|/)\.claude/settings(\.local)?\.json$ ]]; then
  block "The .claude/hooks/, .claude/statusline/, and .claude/settings.json (and settings.local.json) are out of bounds for the agent. Edited by humans only."
fi

# 3b. MCP server configuration. Introducing or altering an MCP server from
# inside a hooked session would hand a prompt injection a new tool surface.
if [[ "$path" =~ (^|/)\.mcp\.json$ ]]; then
  block ".mcp.json defines MCP servers (the tool surface). Edited by humans only."
fi

# 4. SSH keys, PGP keys, AWS credentials, anything that smells like a secret.
if [[ "$path" =~ (^|/)(\.ssh|\.gnupg|\.aws|\.config/gcloud)/ ]]; then
  block "Credential directory. Off-limits."
fi

# 5. Local config files, including CLAUDE.local.md, which is gitignored
# personal context, not for the agent to mutate.
if [[ "$path" =~ (^|/)CLAUDE\.local\.md$ ]]; then
  block "CLAUDE.local.md is the user's personal, gitignored memory. The agent does not edit it."
fi

# All clear.
exit 0
