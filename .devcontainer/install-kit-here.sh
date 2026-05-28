#!/usr/bin/env bash
#
# Install the kit into the current directory.
#
# The kit (CLAUDE.md, PROCESS.md, .claude/) is baked into the dev container
# at /opt/agent-dev-container/. This script copies it into the project root
# from which the script is invoked, then prints next steps.
#
# Safe to re-run: existing files are not silently overwritten; the script
# stops and lists conflicts instead.

set -euo pipefail

KIT_ROOT=/opt/agent-dev-container
TARGET=$(pwd)

if [[ ! -d "$KIT_ROOT" ]]; then
  echo "error: kit not found at $KIT_ROOT" >&2
  echo "       this script only works inside the agent-dev-container" >&2
  exit 1
fi

# Refuse to run in the user's home directory or inside the kit itself.
if [[ "$TARGET" == "$HOME" ]] || [[ "$TARGET" == "$KIT_ROOT"* ]]; then
  echo "error: refusing to install kit into $TARGET" >&2
  echo "       run this from a project root (e.g. cd /workspace/my-project)" >&2
  exit 1
fi

# Check for conflicts before copying anything.
declare -a conflicts=()
for f in CLAUDE.md PROCESS.md .claude KIT_VERSION; do
  if [[ -e "$TARGET/$f" ]]; then
    conflicts+=("$f")
  fi
done

if [[ ${#conflicts[@]} -gt 0 ]]; then
  echo "error: the following already exist in $TARGET:" >&2
  for c in "${conflicts[@]}"; do
    echo "       $c" >&2
  done
  echo >&2
  echo "remove or rename them first, or install the kit into a fresh project root." >&2
  exit 1
fi

# Copy. Preserve permissions (the hooks and statusline need to stay executable).
cp -rp "$KIT_ROOT/CLAUDE.md" "$TARGET/"
cp -rp "$KIT_ROOT/PROCESS.md" "$TARGET/"
cp -rp "$KIT_ROOT/.claude" "$TARGET/"

# Record the kit version this project was bootstrapped from.
if [[ -f "$KIT_ROOT/VERSION" ]]; then
  cp -p "$KIT_ROOT/VERSION" "$TARGET/KIT_VERSION"
fi

# Handle .gitignore: copy as .gitignore if the target has none, otherwise copy
# alongside as .gitignore.kit for the user to merge manually.
if [[ -f "$KIT_ROOT/.gitignore" ]]; then
  if [[ -f "$TARGET/.gitignore" ]]; then
    cp -p "$KIT_ROOT/.gitignore" "$TARGET/.gitignore.kit"
    GITIGNORE_NOTE=$'  .gitignore.kit (existing .gitignore preserved; merge manually)'
  else
    cp -p "$KIT_ROOT/.gitignore" "$TARGET/.gitignore"
    GITIGNORE_NOTE='  .gitignore     standard ignores for Claude Code state and common toolchains'
  fi
fi

cat <<EOF
Kit installed in $TARGET.

Files added:
  CLAUDE.md      project memory: workflow conventions, definition of done
  PROCESS.md     feature-to-PR walkthrough using the slash commands
  .claude/       commands (bugfix, crev), hooks, statusline, skills, audit log
  KIT_VERSION    the kit version this project was bootstrapped from
${GITIGNORE_NOTE:-}

Next steps:
  1. Add .claude/audit.log to your .gitignore.
  2. If your project uses TypeScript or Python, the LSP plugins referenced
     in .claude/settings.json are already installed in this container.
     Other languages: edit .claude/settings.json enabledPlugins and install
     the corresponding language servers.
  3. Restart Claude Code so the hooks, statusline, and project commands load.
  4. Read PROCESS.md for the workflow.

To remove later: rm -rf CLAUDE.md PROCESS.md .claude/
EOF
