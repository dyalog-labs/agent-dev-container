# Project conventions for Claude

This file is project memory. It applies to every session, every command, every subagent. Keep it short; long memory files lose effectiveness in long sessions.

## Per-Issue Workflow

We operate a red/green TDD workflow. 

1. Create branch: {issue-id}-{slug-from-title}
2. Write tests defining expected behaviour - show that they fail (RED)
3. Create/update docs/prs/{issue-id}.md with test details
4. STOP → Present tests for review → Wait for approval
5. Commit approved tests
6. Implement until tests pass (GREEN)
7. Run full test suite (no regressions)
8. Run linters and formatters
9. Update docs/prs/{issue-id}.md with implementation details
10. STOP → Present implementation for review → Wait for approval
11. Commit implementation
12. Create upstream PR

Note: Always create/update the PR doc in docs/prs/{issue-id}.md when stopping for ANY review.

## Writing style

These rules apply to every piece of author-voice writing: code comments, commit messages, PR descriptions, GitHub issue text, and the markdown files under `docs/plans/`. The principles are the same; only the format differs.

### Shared principles

**Invariants over narrative.** Write what is true now and why, not how we got here. The reader cares about the current state of the world; the story of how it was built is rarely useful and ages badly.

If you find yourself writing "we", "I", "originally", "previously", "used to", "first tried", "for now", "TODO without a date", stop. Those are narrative markers. Rewrite to state the invariant, or delete.

**No apologetic hedging.** "This is a bit ugly but…", "Sorry, this is hacky…", "Not sure if this is right…". If the code or change is wrong, fix it. If it's correct but counterintuitive, explain *why* it's correct. Apologies tell the reader nothing they can act on.

**No emojis** in any artefact: code, commits, PRs, issues, and the markdown files under `docs/plans/`. Not ✅ ❌ 🎉 🚀, not "harmless" decoration like ✓ markers. Slash commands may use emoji in their terminal-output confirmation messages (those don't ship anywhere) but the rule is absolute for anything that lands in git, in GitHub, or in `docs/`.

**No em-dashes.** The em-dash (`—`) is overused by AI-generated writing and reads as a tell. Use one of: a full stop (when joining two independent clauses), a comma (when the second clause modifies the first), parentheses (for genuine asides), or a colon (when introducing a list or expansion). The en-dash (`–`) is also banned for the same reason. Hyphens in compound modifiers (`red-green`, `single-concern`) are fine.

**No bold formatting in commit messages, PR bodies, or issue comments.** Markdown bold (`**word**`) clutters terminal output, git log, and email notifications. Markdown files under `docs/plans/` may use bold where it genuinely aids structure (the templates already do this), but only there.

**UK English spelling.** `behaviour` not behavior, `colour` not color, `organise` not organize, `licence` (noun) / `license` (verb), `programme` (for events; `program` for code), `recognise`, `analyse`, `centre`, `defence`. Use `-ise` not `-ize` (so `prioritise`, `summarise`, `optimise`). Both `disk` and `disc` are correct in UK English depending on context; default to `disk` for storage.

**Professional tone.** Direct, calm, technical. No exclamation marks for emphasis. No "obviously", "clearly", "simply", which read as condescending to readers who didn't find it obvious. No "just" minimising the work ("just rename it"). State the change; let it stand.

**Concise.** Shorter is better when it carries the same information. If a sentence can be cut without loss, cut it.

### Code comments

A comment exists to tell the reader something the code can't tell them on its own: a non-obvious invariant, a constraint imposed from outside the code, a reason a counterintuitive choice is correct. It does NOT describe the path that got us here, what we tried first, what the previous implementation did, or how the author was feeling.

Bad (narrative):
```ts
// Initially we tried using a regex here but it was too slow,
// so we switched to a manual scan. Then we noticed it broke
// on unicode so we added the normalise step.
function normaliseAndScan(input: string) { ... }
```

Good (invariant):
```ts
// Input is NFC-normalised before scanning because the wire
// format guarantees NFC but downstream consumers don't.
function normaliseAndScan(input: string) { ... }
```

Bad (restating the code):
```ts
// Increment counter by 1
counter += 1;
```

Good (silence):
```ts
counter += 1;
```

Bad (apologising):
```ts
// This is a bit ugly but it works. TODO: refactor.
function handle() { ... }
```

Good (either fix it or describe the constraint that makes it necessary):
```ts
// Branchless to satisfy the constant-time requirement; see
// docs/security/timing.md.
function handle() { ... }
```

**No GitHub issue IDs in source code or test comments.** Never write `// fixes #42`, `// see issue 123`, `// per discussion in #99`, or any variant.

Reasons: issue IDs go stale when repos are renamed or migrated; the link is already in the commit, PR, changelog, and `docs/plans/`; reasoning by issue number forces the reader to context-switch instead of understanding the code on its own. If the issue contains context the code can't express, copy the *content* into the comment as an invariant, not the link.

Bad:
```py
# See #1234 for handling the edge case where users have null email
if user.email is None:
    return False
```

Good:
```py
# Soft-deleted users keep their account row but lose their email
# (GDPR right-to-erasure). Treat them as ineligible.
if user.email is None:
    return False
```

### Commit messages

Format: a short subject line (under 72 characters, imperative mood, no trailing full stop), a blank line, then an optional body wrapped at ~72 characters.

The subject says what changed. The body says *why*: the constraint, the bug, the contract that necessitated the change. Not the journey of writing it.

Issue references go in a trailer line: `Closes #42` or `Refs #42`. The trailer is the only place issue numbers belong in a commit. Do not write `Fix bug from #42` in the subject.

Bad (narrative body):
```
Add email validation

I noticed the API was accepting empty strings, so I went to look
at how the existing validators work. Tried using a regex first
but found we already had a validateEmail helper, so I used that
instead. Then I added a test.

Closes #42
```

Good (invariant body):
```
Reject POST /users with missing email

The wire contract requires email; the controller was forwarding
empty strings to persistence and triggering a unique-index error
on the second blank insert. Apply the existing validateEmail
helper at the controller boundary.

Closes #42
```

No emojis in commit subjects or bodies. No `feat:` or `fix:` prefixes unless the repo's existing convention requires them; look at recent commits first, and don't impose Conventional Commits where it isn't used.

### PR descriptions

The PR body is `docs/prs/<id>.md` (see the workflow section). The same rules apply to that document: invariants over narrative, no emojis, no bold formatting in the top-level Summary and "How it was tested" sections, UK English, professional tone. The per-cycle entries in that doc may use bold sub-headers because they follow a template, but that is the exception, not licence to bold elsewhere.

### GitHub issue text

When writing issues, apply the same rules. No emojis in titles or bodies. No "🎉 Feature request:" or "🐛 Bug:" prefixes; if the repo uses issue templates that include these, the template is wrong but not your problem to fix in this PR.

Issue titles are imperative ("Reject POST /users with missing email") or noun phrases ("Empty-email handling in user creation"), not questions ("Should we validate email?") and not narratives ("Email validation isn't working").

## Test conventions

- One test, one behaviour. The test name reads as a sentence describing the behaviour ("rejects POST /users when email is missing").
- Tests assert observable behaviour, not implementation details. No reaching into private state.
- Test files live next to or mirror the source files, following the conventions already established in the repo. Look first; don't invent a new layout.

## Definition of done

A change is done when:

1. All tests pass: the full suite, not a subset.
2. Linters and type checks pass: no `--no-verify`, no skip flags.
3. The PR doc `docs/prs/<id>.md` accurately describes what changed and why, across all cycles.
4. The latest review verdict in `docs/reviews/<id>.md` is `approved`, or the author has explicitly decided to ship over `request changes` and documented the reasoning.

## What lives where

| Path | Contents |
|---|---|
| `docs/plans/<slug>.md` | Feature plans, written from plan-mode conversation |
| `docs/bugs/<id>.md` | Bug investigations (repro, RCA, fix outline), written by `/dyalog:bugfix` |
| `docs/prs/<id>.md` | Living PR notes, built across red/green cycles |
| `docs/reviews/<id>.md` | Append-only review log, written by `/dyalog:crev` |
| `.claude/commands/dyalog/` | The two project slash commands (`bugfix`, `crev`) |
| `.claude/skills/` | Model-triggered skills loaded automatically by Claude |
| `.claude/hooks/` | System-level guardrails, protected from agent edits |
| `.claude/statusline/` | Branch / context / auto-compact indicator |
