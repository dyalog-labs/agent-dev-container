---
name: crev
description: Code review workflow for a specific issue/PR in this repo. Use when asked to run a crev-style review, review issue implementations, or review tests-first for an issue (e.g., "crev 301", "review issue 309").
---

# Code Review for Issue (crev)

## Inputs

- Require an issue/PR number. If missing, ask for it.
- If the argument is a path to a document under the `docs/` folder, treat it as a design or plan review
  - Given `/crev docs/plans/new-feature.md`, write your review to `docs/reviews/new-feature.md`. Inform the user that you're treating this as a design review.
- Determine review stage: tests-only vs implementation.
  - If `docs/reviews/<ISSUE>.md` exists, treat that as the first (tests-only) review already completed and perform the implementation review.
  - If it does not exist and the user does not specify a stage, ask which stage to review.

## Process

1. Gather context.
   - Read `docs/prs/<ISSUE>.md`.
   - Fetch the GitHub issue <ISSUE> using `gh`
   - Read any referenced design docs (for example `docs/plans/*.md` or `docs/bugs/*.md`).

2. APL semantics verification (tests).
   - For tests with APL expressions, use the `dyalog-script` skill to validate expected values.
   - Check edge cases: empty arrays, scalars, and high-rank arrays.
   - Note any intentional deviations from Dyalog compatibility; flag undocumented deviations.

3. Implementation review (skip for tests-only stage).
   - Verify architectural conformity with relevant design docs.
   - Code quality: file organization, API consistency, naming clarity, comments, error handling.
   - Comment hygiene: verify code comments do not mention GitHub issue/PR IDs directly. Keep issue IDs in PR docs, review docs, and commit messages, not source comments.
   - Comment style: flag comments that narrate the implementation journey, prior attempts, or obvious mechanics. Prefer direct, concise comments that explain non-obvious intent, invariants, or constraints. No emojis or em-dashes.

4. Bug fix special case.
   - Verify any stated repro directly.
   - Confirm the fix addresses root cause, not a workaround.
   - Ensure tests demonstrate the bug and protect against regressions.

5. Run all tests (skip for tests-only stage).

   - If running is skipped, record as "not run" with reason.
   - Under TDD, new tests may fail in tests-only stage.

6. Write the review file.
   - Create/update `docs/reviews/<ISSUE>.md` using this template:

```markdown
# Review: Issue #<ISSUE> - [Brief Title]

## Summary

[One paragraph overview of findings]

## Findings

### [Severity]: [Finding Title]

[Description of the issue and recommendation]

Location: [file:line or general area]

### ...

## Verification

- Tests: [pass/fail/not run]

## Recommendation

[Approve / Approve with minor changes / Request changes]
```

Severity levels:
- Critical: must fix before merge (correctness issues, regressions)
- Major: should fix before merge (significant gaps, API issues)
- Minor: nice to fix (style, documentation, minor improvements)
- Note: observations that do not require changes

If no issues are found, state that explicitly in Summary and Findings.
