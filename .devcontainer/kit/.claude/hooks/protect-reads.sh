#!/usr/bin/env bash
#
# protect-reads.sh
# Fires on PreToolUse for the Read tool. Blocks reading paths whose contents
# are secret. protect-paths.sh stops writes to these paths; this hook closes
# the read side so an agent cannot exfiltrate credentials.
#
# Registered in settings.json under PreToolUse with the matcher "Read".
#
# Exit codes:
#   0 = allow
#   2 = block (stderr is shown to Claude as feedback)
#
# Input JSON shape:
#   { "tool_name": "Read", "tool_input": { "file_path": "..." }, ... }

set -euo pipefail

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  tool=$(echo "$input" | jq -r '.tool_name // empty')
  path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
else
  tool=$(echo "$input" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')
  path=$(echo "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')
fi

if [[ -z "${path}" ]]; then
  exit 0
fi

block() {
  local reason="$1"
  cat >&2 <<EOF
[hook: protect-reads] BLOCKED ${tool} on: ${path}
Reason: ${reason}

This path holds secrets and is read-protected by a project hook. Do not attempt
to work around it (no cat/grep in Bash, no base64, no alternate tooling). If the
user genuinely needs the contents, they will read it themselves.
EOF
  exit 2
}

# 1. Environment files at any depth.
if [[ "$path" =~ (^|/)\.env(\.[^/]+)?$ ]]; then
  block ".env files hold secrets."
fi

# 2. Credential directories.
if [[ "$path" =~ (^|/)(\.ssh|\.gnupg|\.aws|\.config/gcloud)/ ]]; then
  block "Credential directory."
fi

# 3. Standalone secret / private-key files.
if [[ "$path" =~ (^|/)(\.netrc|\.npmrc|\.pgpass|id_rsa|id_ed25519|id_ecdsa|id_dsa)$ ]] \
   || [[ "$path" =~ \.(pem|key|p12|pfx)$ ]]; then
  block "Private key or credential file."
fi

# 4. Personal gitignored memory.
if [[ "$path" =~ (^|/)CLAUDE\.local\.md$ ]]; then
  block "CLAUDE.local.md is the user's personal, gitignored memory."
fi

exit 0
