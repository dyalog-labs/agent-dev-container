---
description: Investigate a bug and write docs/bugs/<ID>.md, repro, RCA, fix outline. NO code changes.
argument-hint: <github-issue-number>
allowed-tools: Read, Edit, Glob, Grep, Bash(gh issue view:*), Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), Bash(git status:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(rg:*), Bash(mkdir:*), Bash(ls:*), Bash(cat:*), Bash(npm test:*), Bash(npm run:*), Bash(pnpm test:*), Bash(pnpm run:*), Bash(yarn test:*), Bash(pytest:*), Bash(python:*), Bash(python -m pytest:*), Bash(node:*), Bash(go test:*), Bash(go run:*), Bash(cargo test:*), Bash(cargo run:*), Bash(curl:*), Write
---

# /bugfix - Fix a bug by GitHub issue ID

Fix the bug described in GitHub issue $ARGUMENTS.

## Process

1. **Gather context**: Read the GitHub issue using `gh` to understand the reported problem, including any reproducer code.

2. **Create branch**: `git switch -c $ARGUMENTS-{slug-from-issue-title}` from `main`.

3. **Minimal reproducer**: Verify the bug with the smallest possible reproducer. If the issue includes one, confirm it fails. If not, construct one. If we're dealing with APL, test against Dyalog (using the "dyalog-script" skill) to confirm correct expected behaviour.

4. **Regression tests**: Write tests that demonstrate the bug — they must FAIL on the current code. These tests define the acceptance criteria for the fix.

5. **Root cause analysis**: Investigate the interpreter source to identify the root cause. Write `docs/bugs/$ARGUMENTS.md` containing:
   - Summary of the bug
   - Minimal reproducer
   - Root cause explanation (which file, which function, why it fails)
   - Fix proposal(s) with trade-offs if applicable

6. **Commit the bug document**: Stage only `docs/bugs/$ARGUMENTS.md` and commit. Subject: `Investigate #$ARGUMENTS` (imperative, under 72 chars, no trailing full stop). Body: one short paragraph stating the root cause finding. Trailer: `Refs #$ARGUMENTS`. Do not stage reproducer scripts or regression tests in this commit; those belong to the implementation cycle.

7. **Stop for review**: Present a summary to the user covering:
   - The reproducer and Dyalog reference output, if relevant
   - The regression tests written
   - The root cause finding
   - Proposed fix approach


NOTE CAREFULLY: once the root cause is understood, ensure that the fix is not narrowly scoped to the reproducer only. Consider as part of the analysis if the root cause has wider implications. For example, if the problem was mixed buffers in special circumstances when applied via primitive A, ensure that your fix also applies to similar circumstances for primitives B, C and D. The RCA should have a section **Also Impacts** listing such wider implications.

Do NOT proceed to implementation until the user approves.


