#!/usr/bin/env bash
#
# audit-log.sh
# Fires on PreToolUse for every tool. Appends one line per call to an audit log.
# Non-blocking: always exits 0. This is observability only.
#
# The log lives at .claude/audit.log (gitignored, add it to .gitignore).
#
# Async-friendly: cheap enough to run inline, no need for the async flag.

set -euo pipefail

input=$(cat)
log_file="${CLAUDE_PROJECT_DIR:-.}/.claude/audit.log"

if command -v jq >/dev/null 2>&1; then
  tool=$(echo "$input" | jq -r '.tool_name // "?"')
  # Pull a useful summary of the tool input. For Bash, that's the command;
  # for Edit/Write, the file path; otherwise the first 80 chars of input.
  summary=$(echo "$input" | jq -r '
    if .tool_input.command then .tool_input.command
    elif .tool_input.file_path then .tool_input.file_path
    elif .tool_input.pattern then .tool_input.pattern
    elif .tool_input.url then .tool_input.url
    else (.tool_input | tostring)
    end
  ' | head -c 200)
  session=$(echo "$input" | jq -r '.session_id // "no-session"')
else
  tool="?"
  summary="(jq not available, install jq in your dev container for useful audit logs)"
  session="no-session"
fi

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Make sure the directory exists. The file may not yet.
mkdir -p "$(dirname "$log_file")"

# Single-line entry. Tabs as separators so it's easy to grep / awk.
printf '%s\t%s\t%s\t%s\n' "$timestamp" "$session" "$tool" "$summary" >> "$log_file"

# Never block.
exit 0
