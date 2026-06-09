#!/usr/bin/env bash
#
# validate-hooks.sh
# Exercises the kit's PreToolUse hooks against positive and negative cases.
# Run after changing a hook to confirm it still behaves. Exits non-zero on any
# unexpected result.
#
# This file is part of the kit source, not the shipped payload: install-kit-here
# copies CLAUDE.md, PROCESS.md and .claude/ into a project, not this script.
#
# Usage:
#   ./validate-hooks.sh [HOOKS_DIR]
# HOOKS_DIR defaults to the kit's own .claude/hooks next to this script.

set -o pipefail

HOOKS_DIR="${1:-$(cd "$(dirname "$0")" && pwd)/.claude/hooks}"
bash_hook="$HOOKS_DIR/block-dangerous-bash.sh"
paths_hook="$HOOKS_DIR/protect-paths.sh"
reads_hook="$HOOKS_DIR/protect-reads.sh"

pass=0; fail=0

# expect HOOK EXPECTED_EXIT JSON DESC
expect() {
  local hook="$1" want="$2" json="$3" desc="$4" got
  printf '%s' "$json" | bash "$hook" >/dev/null 2>&1
  got=$?
  if [[ "$got" == "$want" ]]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    echo "FAIL: $desc (want exit $want, got $got)"
  fi
}

bash_json() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
path_json() { printf '{"tool_name":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"; }

echo "Validating hooks in: $HOOKS_DIR"
for h in "$bash_hook" "$paths_hook" "$reads_hook"; do
  [[ -f "$h" ]] || { echo "MISSING: $h"; exit 2; }
  bash -n "$h" || { echo "SYNTAX ERROR: $h"; exit 2; }
done

# block-dangerous-bash.sh: write-protection (block 10)
expect "$bash_hook" 2 "$(bash_json 'echo X > .env')"                           "bash: redirect to .env"
expect "$bash_hook" 2 "$(bash_json 'echo {} >> .claude/settings.local.json')"  "bash: redirect to settings.local.json"
expect "$bash_hook" 2 "$(bash_json 'echo {} > .mcp.json')"                     "bash: redirect to .mcp.json"
expect "$bash_hook" 2 "$(bash_json "sed -i s/a/b/ .env")"                      "bash: sed -i on .env"
expect "$bash_hook" 2 "$(bash_json 'cp /tmp/x.sh .claude/hooks/x.sh')"         "bash: cp into hooks/"
expect "$bash_hook" 2 "$(bash_json 'echo k >> .ssh/authorized_keys')"          "bash: write ssh key"
expect "$bash_hook" 0 "$(bash_json 'git log > /tmp/out')"                      "bash: git log redirect allowed"
expect "$bash_hook" 0 "$(bash_json 'echo x > src/main.go')"                    "bash: write normal file allowed"

# block-dangerous-bash.sh: secret reads (block 11)
expect "$bash_hook" 2 "$(bash_json 'cat .env')"                               "bash: cat .env blocked"
expect "$bash_hook" 2 "$(bash_json 'grep PASSWORD .env')"                     "bash: grep .env blocked"
expect "$bash_hook" 2 "$(bash_json 'cat .env.local')"                         "bash: cat .env.local blocked"
expect "$bash_hook" 2 "$(bash_json 'base64 .env')"                            "bash: base64 .env blocked"
expect "$bash_hook" 2 "$(bash_json 'cat .npmrc')"                             "bash: cat .npmrc blocked"
expect "$bash_hook" 2 "$(bash_json 'cat /home/user/.ssh/id_rsa')"            "bash: cat ssh key blocked"
expect "$bash_hook" 2 "$(bash_json 'cat server.key')"                        "bash: cat *.key blocked"
expect "$bash_hook" 2 "$(bash_json 'cat .env > /tmp/out')"                    "bash: read .env piped to write blocked"
expect "$bash_hook" 0 "$(bash_json 'cat .env.example')"                       "bash: .env.example template read allowed"
expect "$bash_hook" 0 "$(bash_json 'cat .env.sample')"                        "bash: .env.sample template read allowed"
expect "$bash_hook" 0 "$(bash_json 'cat .env.template')"                      "bash: .env.template template read allowed"
expect "$bash_hook" 0 "$(bash_json 'cat .env.dist')"                          "bash: .env.dist template read allowed"
expect "$bash_hook" 0 "$(bash_json 'cat .claude/settings.json')"             "bash: read settings.json allowed"
expect "$bash_hook" 0 "$(bash_json 'cat .git/config')"                        "bash: read .git/config allowed"
expect "$bash_hook" 0 "$(bash_json 'git log | head')"                         "bash: reader in pipeline, no secret, allowed"
expect "$bash_hook" 0 "$(bash_json 'cat README.md')"                          "bash: read normal file allowed"

# block-dangerous-bash.sh: go fail-fast (block 4a)
expect "$bash_hook" 2 "$(bash_json 'go test -failfast ./...')"                 "bash: go test -failfast"
expect "$bash_hook" 0 "$(bash_json 'go test ./...')"                           "bash: go test allowed"
expect "$bash_hook" 0 "$(bash_json 'go test -run TestFoo ./...')"              "bash: go test -run allowed"

# block-dangerous-bash.sh: regressions (pre-existing rules still fire)
expect "$bash_hook" 2 "$(bash_json 'git push --force origin main')"            "bash: force-push still blocked"
expect "$bash_hook" 2 "$(bash_json 'sudo rm -rf /tmp/x')"                      "bash: sudo still blocked"

# protect-paths.sh: new and regression
expect "$paths_hook" 2 "$(path_json Write .claude/settings.local.json)"        "paths: settings.local.json blocked"
expect "$paths_hook" 2 "$(path_json Write .mcp.json)"                          "paths: .mcp.json blocked"
expect "$paths_hook" 2 "$(path_json Write app/.env)"                           "paths: .env still blocked"
expect "$paths_hook" 2 "$(path_json Edit .claude/settings.json)"               "paths: settings.json still blocked"
expect "$paths_hook" 0 "$(path_json Write src/main.go)"                        "paths: normal file allowed"

# protect-reads.sh: Read-tool hook
expect "$reads_hook" 2 "$(path_json Read /workspace/.env)"                     "reads: .env blocked"
expect "$reads_hook" 2 "$(path_json Read /home/user/.ssh/id_rsa)"              "reads: ssh key blocked"
expect "$reads_hook" 0 "$(path_json Read /workspace/src/main.go)"              "reads: normal file allowed"

echo
echo "PASS=$pass FAIL=$fail"
[[ "$fail" == 0 ]]
