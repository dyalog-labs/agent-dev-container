# How we work

This is the practical guide to taking a new feature from an idea in your head to a merged PR. It assumes you've read `CLAUDE.md` for the conventions. This document fills in what to actually do.

The pipeline is deliberately structured. Each command does one thing, then stops for a human review. If a step feels like friction, that is the step working as intended.

This isn't the only way to work with Claude Code. Once you gain experience you will want to tweak this process to suit your specific circumstances better. We've deliberately not automated as much as you could do. This encourages you to understand the process first, and then you have the freedom to automate steps that feel repetitive. 

The guiding principle is to only work from reviewed, approved, fully versioned artefacts, never from freeform "prompting". The Human should (almost) never contribute intelligence via prompts. Instead of asking Claude to "do something" you ask Claude to make a _plan_ to do something, and then to implement this plan. This has several beneficial effects: firstly, the plan can be carefully scrutinised by humans and other LLMs alike. The plan can be versioned in git, and evolve, rolled back, tweaked -- much harder to do with prompts. The plan is then partitioned into smaller work units that the agent can fit into its context window. 

## The shape of the work

Every feature follows the same path:

1. Start from an idea, end with a written plan.
2. Turn the plan into GitHub issues.
3. Pick an issue, work it as a sequence of TDD red/green cycles.
4. Each cycle is reviewed before moving on.
5. When the issue is fully implemented, open a PR.
6. Address review feedback. Merge.

The same path covers bug work. See "Bug work" near the end of this document.

## From idea to plan

You have an idea. Maybe it came from a customer ticket, a product conversation, or a thing that has been annoying you in the code. Open Claude Code in the project root, make sure you are on `main` with a clean working tree. Enter plan mode (shift-tab) and state in your own words what you want to achieve. Note: this is the start of a conversation.

```
Plan the introduction of a new API endpoint <X>. It should...
```

Claude will explore the codebase using read-only tools and come up with a detailed plan for your request. 

**Read the plan.** Not skim. Read.

The single most expensive mistake at this stage is approving a plan that has the wrong shape. A wrong line of code costs minutes to fix; a wrong plan costs the next two hours. Look for:

- **Out-of-scope is honest.** If "user-facing notifications" is listed but the work breakdown includes "wire up email templates", out-of-scope is lying.
- **Work breakdown items are testable outcomes**, not task labels. "Add validation" is a task; "POST /users rejects requests with missing email" is an outcome.
- **Each item is independently shippable.** If item 4 only makes sense after items 2 and 3, the breakdown is too coarse.
- **The open questions are real**, not performative. If Claude has marked something as an open question that the issue already answers, push back. If you can think of an open question Claude missed, add it.

At this moment, push back on anything off-looking. Challenge assumptions. Ask for clarifications or added detail. Make Claude rework the plan.

Now, in a separate agent terminal, in a separate context, ask Claude to review the plan, using the `/dyalog:crev` command. Review its findings, and either paste back the review results to the planner, or if it's approved, go back to the reviewer and ask it to write its plan to its forever home. Drop out of plan mode and say

```
Save the plan to docs/plans/<slug>.md and remove the temporary file
```

Agentic plan review is optional but recommended. There is no downstream command that gates on the plan having been reviewed. For small or obvious changes, it's reasonable to skip. For anything you'd want a colleague to look at, run it.

## From plan to issues

Our work schedule is driven by GitHub "Epics" and "Issues". An "Epic" is just a GitHub issue that groups other issues that are related. If it helps, think of an Epic as the programmer's interpretation of a user story. It's the todo-list for the feature we're working on. Epics and issues refer back to the plan document, and should be concrete. The plan document + Epic + issue should provide sufficient context for the Agent (or, indeed, the Human) to work from. 

Once the plan is in good shape, run:

```
Convert docs/plans/<slug>.md to GitHub Epics and linked sub-issues each referencing the plan document explicitly for context.
```

- A GitHub Epic (opr Epics) is created from the plan document
- Each work-breakdown item becomes a child issue with acceptance criteria.

The Epic(s) and child issues are visible in your repo on GitHub. Take a moment to look at them there, the rendered version often reads differently from the source.

## Pick an issue, start the cycle

Pick the first child issue. Note its number. In Claude Code:

```
Proceed <issue-number>
```

`Proceed` is the only command you run between reviews. Claude knows how to figure out the current state of the work and runs the right phase: writing the test surface (RED), revising the test surface after a review, implementing the surface (GREEN), or revising the implementation after a review. Every invocation does exactly one step and then stops for review.

The first run, on a clean main branch with no existing work for this issue, creates a feature branch `<id>-<slug>` and opens the **RED phase**:

1. Reads the issue and the source documents under `docs/plans/`
2. Writes tests that define the behaviour that the plan and issue defines. Each test must be independent of the others, no shared state, no ordering.
3. Runs the surface to confirm every test fails for the right reason (assertion failure or "not implemented", not import errors or syntax mistakes).
4. Creates `docs/prs/<id>.md` with the RED cycle entry: the test surface, a coverage table mapping criteria to tests, and an anticipated implementation order.
5. Commits the tests.
6. Stops.

Now we need to review the tests, both Human and Agent. 

In the review agent window, run `/clear` and then `/dyalog:crev <id>`. This will produce a detailed review in `docs/reviews/<id>.md`. Examine this, in conjunction with the `docs/prs/<id>.md` document that the implementer agent should have created. You can edit the `docs/reviews/<id>.md` if you want to make further comments. 

Tell the implementer agent either `Approved; proceed` (if it was), or `Read the review at docs/reviews/<id>.md and address its findings`. Repeat until approved.

When you say `Approved; proceed` Claude will now do the implementation until the approved tests turn green. Apply exactly the same review process, except this time, retain the context (no `/clear`) from the test reviews. 

### Reading a review

Every review classifies its findings into three tiers:

- **Blockers** are issues that prevent the next pipeline step from being correct. They are the only tier that determines `request changes`. Any blocker means the verdict is `request changes`; no blockers means `approved`, regardless of how many concerns or observations the reviewer raised.
- **Concerns** are issues worth addressing but not blocking. The author may address or dismiss them with reasoning. They appear in the review for tracking but don't gate the verdict.
- **Observations** are things worth knowing about: pre-existing structural debt, broader-codebase patterns, follow-up ideas. Verdict-neutral. They become candidates for follow-up issues.

A review that returns `approved` with five concerns and three observations isn't a soft pass; it's a deliberate signal that the work is correct enough to proceed *and* there are things worth thinking about. Read the concerns. Address what's worth addressing. Open follow-up issues for the observations you care about.

A review that returns `request changes` always has at least one blocker. Address the blockers first; the concerns can wait for the re-review.

### PR etc. 

Once the work unit is completed, we need to ensure that everything is committed, pushed, and a PR is opened upstream. Ask Claude:

```
Run the full test suite. If it passes, push the branch and open a pull request that summarises the cycles in docs/prs/<id>.md.
```

It will report back the PR link. The PR is not merged automatically. Once it's been reviewed, merged, and any CI is green, return to Claude:

```
PR merged. Pull from upstream and remove my local branch which is now merged.
```

## Bug work

For bugs, the pipeline is the same shape with a different start. You have a GitHub issue describing a bug. Start with:

```
/dyalog:bugfix <issue-number>
```

Claude reproduces the bug (actually reproduces it; not "describes how to reproduce"), investigates the code path, and writes `docs/bugs/<id>.md` containing the verified repro, the root-cause analysis, a proposed fix outline, and a regression-test specification.

Read it. Push back on any "facts" that look like guesses. Resolve the "Open questions" by editing the doc or by adding comments to the GitHub issue. If Claude could not reproduce the bug, do not let it move on. The RCA is built on the repro, and a fabricated repro produces a fabricated fix.

Once the RCA is solid, run `/dyalog:crev <id>` as normal. The reviewer has extra duties for bug work: it will re-run the repro to verify it still fails on the unfixed code, check that each "What we know" fact points at a real file/line/commit, and verify the regression test in the diff matches the one the RCA proposed.

## When the pipeline gets in your way

It will, sometimes. Three situations come up:

**A trivial typo fix.** Someone asks you to change "colour" to "color" in a comment, or rename a variable. Going through planning and issues for a one-line change is theatre. For changes under ten lines that have no behavioural impact, a direct edit and a commit is fine. The hooks still apply.

**An urgent production fix.** The pipeline is built for sustained work, not for incidents. In an incident, the rule is: fix it, ship it, write the post-mortem afterwards. Run `/dyalog:bugfix` *after* the fix is live, as the post-mortem artefact. The repro and RCA still matter; they do not gate the merge.

**An exploratory spike.** You don't know what you're going to build yet. The pipeline assumes a plan exists. Do the spike on a throwaway branch, *outside* the pipeline. When you know what you want to build, throw the spike away and go through the proper planning phase. Do not try to retrofit a plan around code that already exists, the plan will be a justification, not a design.

In every case other than these, use the pipeline. The friction is the point.

## What you should not do

- Do not skip the code review step. Not even for "I can see the test is fine." The reviewer catches things you do not, and the cumulative effect of skipping reviews is a codebase where reviews stop happening.
- Do not run `git commit` yourself during the cycle. The commands commit their own work, in the right format, with the right metadata. 
- Do not edit prior cycle entries in the PR doc. They are append-only. If a cycle's reasoning turned out to be wrong, the next cycle entry says so.
- Do not push `--force`. The hook blocks it. 
- Do not edit `.claude/hooks/`, `.claude/statusline/`, or `.claude/settings.json` from inside Claude Code. The hook blocks it. These are edited by humans, out-of-band, with full intent.

## What this gets you

A consistent pipeline gets you three things that matter:

- **Reviewable history.** Every PR has a doc that walks through the author's reasoning cycle by cycle. The reviewer reads it. The author of the next PR on the same code reads it six months later and understands why the code looks the way it does.
- **An adversarial second opinion at every stage**, costing nothing more than a `/dyalog:crev` invocation. The reviewer is not your friend. It is the colleague who notices the thing you missed, and unlike a human colleague, it is always available and never tired.
- **A working definition of "done"** that does not depend on anyone's mood. Done is: all tests pass, linters pass, the PR doc is honest, the latest review is `approved`. If those four things are true, the work is done. If any are false, it is not.

The cost is friction. You will sometimes write three commands to do what felt like one task. You will sometimes have a `request changes` verdict on code you were certain was correct. This is the discipline working.
