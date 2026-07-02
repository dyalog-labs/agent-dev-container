# Slash commands

The kit ships two project slash commands. Everything else in the workflow happens through ordinary conversation with Claude.

For a quick reference to Claude Code's own built-in slash commands (distinct from the two project commands documented here), see [`claude-code-commands.html`](../../claude-code-commands.html) at the kit root.

## What each command does

### `/dyalog:bugfix <issue-number>`

Investigates a GitHub-issue-tracked bug. Writes failing regression tests that pin the behaviour, and a `docs/bugs/<id>.md` containing a verified minimal reproducer, a root-cause analysis pointing at specific files and functions, a fix outline, and an "Also Impacts" section covering wider implications of the root cause. Writes no production code. The regression tests are written but not committed with the bug document; they belong to the implementation cycle. The user reads the document, pushes back on guesses, and either approves the proposed fix or asks for revisions before implementation begins.

For APL bugs, the command uses the `dyalog-script` skill to verify expected behaviour against a real Dyalog interpreter.

### `/dyalog:crev <issue-number|path>`

Reviews work at any stage and writes a structured review to `docs/reviews/<id>.md`. The review classifies findings by severity (Critical, Major, Minor, Note) and ends with a recommendation (`Approve`, `Approve with minor changes`, `Request changes`).

Stages it covers:

| Stage | Trigger | What the review checks |
|---|---|---|
| Plan / design | path argument like `docs/plans/foo.md` | Coverage, out-of-scope honesty, testability of acceptance criteria |
| Tests-only (RED) | `docs/reviews/<id>.md` does not exist yet | Tests fail for the right reason, edge cases are covered, no implementation-detail asserts |
| Implementation (GREEN) | `docs/reviews/<id>.md` already exists | Architectural conformity, code quality, comment hygiene, full suite passes |
| Bug fix | `docs/bugs/<id>.md` referenced | Repro verified directly (reject if it cannot reproduce), fix addresses root cause not a workaround, tests demonstrate the bug and guard against regression |

The command picks the stage automatically from the inputs; if it cannot tell, it asks.

## What is NOT a slash command

Everything between bug-investigation and code-review is ordinary conversation:

- **Planning** happens in plan mode. Shift-tab in, state the goal, let Claude explore the codebase and propose a plan. Iterate by talking. When the plan is good, drop out of plan mode and ask Claude to save it to `docs/plans/<slug>.md`.
- **Issue creation** is a single natural-language request: ask Claude to "convert the plan at `docs/plans/<slug>.md` into a GitHub epic and child issues, each referencing the plan document for context."
- **The TDD cycle** is also conversation. "Proceed with issue 42" is interpreted as "create the feature branch, write the failing test surface for the acceptance criteria, then stop." The next "Proceed" after a review interprets the review state and either implements (RED was approved) or revises (request changes).
- **The PR open** is one more natural-language request: "Run the full suite, then push and open a PR summarising `docs/prs/42.md`."

The two slash commands exist because their inputs and outputs benefit from a strict template. The rest does not.

## The contract

Both commands follow three rules:

1. **One job.** `/dyalog:bugfix` analyses but does not fix. `/dyalog:crev` writes a review but does not modify the code under review.
2. **Stops at the dangerous moments.** Both commands stop and surface their output to the user. The user decides what to do next.
3. **Fails loudly, not silently.** Missing GitHub-issue context, missing PR doc when reviewing implementation, an unreproducible bug, all cause the command to stop and report rather than continue on guesswork.

## Files under `docs/`

| Path | Written by | What lives here |
|---|---|---|
| `docs/plans/<slug>.md` | Conversation in plan mode; saved by user request | Feature plans |
| `docs/bugs/<id>.md` | `/dyalog:bugfix` | Bug investigations (verified repro, RCA, fix outline, Also Impacts) |
| `docs/prs/<id>.md` | Conversation during the TDD cycle; appended each cycle | Per-cycle PR notes, the eventual PR body |
| `docs/reviews/<id>.md` | `/dyalog:crev` | Append-only review log per issue |

Issue-numbered files (`<id>`) wait until a GitHub issue exists. Pre-issue plan reviews use a path argument to `/dyalog:crev`; they land in `docs/reviews/<slug>.md` and are renamed when issues are created.

## Commits

The commands commit their own outputs: `/dyalog:bugfix` commits the bug document, `/dyalog:crev` commits the review file. Other artefacts (the plan in `docs/plans/`, the per-cycle PR notes in `docs/prs/`, the test surface and implementation diffs themselves) are committed during the conversational cycles. The fine-grained per-cycle history supports `git reset --hard HEAD~1` to roll back the most recent cycle, or further back.

## Customising for your team

- **Test commands** in each command's `allowed-tools` frontmatter: edit to match your stack.
- **Severity rubric** in `crev.md`: tighten or relax depending on how strict you want the gate.
- **Bug analysis structure** in `bugfix.md`: add team-specific sections (Affected versions, Customer impact, Rollback plan).
- **Add commands** if your team's workflow benefits from another structured entry point. Keep them narrow: a slash command earns its keep when its inputs and outputs benefit from a strict template.

## Out of scope for this command set

- No planning command. Plan mode is the canonical mechanism; no value in wrapping it.
- No "fix the failing test" command.
- No skip-review mode.
- No `--force` push. The hook blocks it.
