# How we work

This is the practical guide to taking a new feature from an idea in your head to a merged PR. It assumes you've read `CLAUDE.md` for the conventions. This document fills in what to actually do.

For a one-page visual summary of the pipeline, see the cheat sheet published at https://claude.ai/code/artifact/d1f2b87b-a145-4a8a-9465-986498059639 (visible only to members of the Dyalog organisation). The same page is in the repo at `pipeline-cheatsheet.html`.

The pipeline is deliberately structured. Each command does one thing, then stops for a human review. If a step feels like friction, it is usually doing its job: creating a deliberate pause for a human to look before the work moves on.

This isn't the only way to work with Claude Code. Once you gain experience you will want to tweak this process to suit your specific circumstances better. We've deliberately not automated as much as you could do. This encourages you to understand the process first, and then you have the freedom to automate steps that feel repetitive. 

The guiding principle is to work from reviewed, approved, versioned artefacts rather than from freeform "prompting". Your judgement still drives everything; the point is to capture it in a plan others can read and revisit, rather than in a prompt that scrolls out of sight. So instead of asking Claude to "do something", you ask it to draft a _plan_ to do it, shape that plan until you are happy with it, and only then have it implement. This has several beneficial effects: the plan can be scrutinised carefully, by humans and other LLMs alike; it can be versioned in git, so it can evolve, be rolled back, be tweaked, all much harder to do with prompts; and it can be partitioned into smaller work units that fit comfortably in the agent's context window. 

## Process

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

- **Out-of-scope is honest.** If "user-facing notifications" is listed as out of scope but the work breakdown includes "wire up email templates", the two contradict each other, and one of them is wrong.
- **Work breakdown items are testable outcomes**, not task labels. "Add validation" is a task; "POST /users rejects requests with missing email" is an outcome.
- **Each item is independently shippable.** If item dependencies are complex, the breakdown may be too coarse.
- **The open questions are real**, not for show. If Claude has marked something as an open question that the issue already answers, push back. If you can think of an open question Claude missed, add it.

At this moment, push back on anything off-looking. Challenge assumptions. Ask for clarifications or added detail. Make Claude rework the plan. Be ruthless!

Now, in a separate agent terminal, in a separate context, ask Claude to review the plan, using the `/dyalog:crev` command. Review its findings, and either paste the review results back to the planner for revision, or, once it's approved, go back to the planner and have it write the plan to its forever home. Drop out of plan mode and say

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

- A GitHub Epic (or Epics) is created from the plan document
- Each work-breakdown item becomes a child issue with acceptance criteria.

The Epic(s) and child issues are visible in your repo on GitHub. Take a moment to look at them there, the rendered version often reads differently from the source.

## Pick an issue, start the cycle

Pick the first child issue. Note its number. In Claude Code:

```
Proceed <issue-number>
```

`Proceed` is the only prompt you run between reviews. Claude knows how to figure out the current state of the work and runs the right phase: writing the test surface (RED), revising the test surface after a review, implementing the surface (GREEN), or revising the implementation after a review. Every invocation does exactly one step and then stops for review.

The first run, on a clean main branch with no existing work for this issue, creates a feature branch `<id>-<slug>` and opens the **RED phase**:

1. Reads the issue and the source documents under `docs/plans/`
2. Writes tests that define the behaviour that the plan and issue defines. Each test must be independent of the others, no shared state, no ordering.
3. Runs the surface to confirm every test fails for the right reason (assertion failure or "not implemented", not import errors or syntax mistakes).
4. Creates `docs/prs/<id>.md` with the RED cycle entry: the test surface, a coverage table mapping criteria to tests, and an anticipated implementation order.
5. Stops. The tests are not committed yet; they are committed only once the review approves them.

Now we need to review the tests, both Human and Agent. 

In the review agent window, run `/clear` and then `/dyalog:crev <id>`. This will produce a detailed review in `docs/reviews/<id>.md`. Examine this, in conjunction with the `docs/prs/<id>.md` document that the implementer agent should have created. You can edit the `docs/reviews/<id>.md` if you want to make further comments. 

Tell the implementer agent either `Approved; proceed` (if it was), or `Read the review at docs/reviews/<id>.md and address its findings`. Repeat until approved.

When you say `Approved; proceed` Claude commits the approved tests, then implements until they turn green. Apply exactly the same review process, except this time, retain the context (no `/clear`) from the test reviews. 

### Reading a review

`/dyalog:crev` classifies each finding by severity:

- **Critical**: must fix before merge. Correctness issues, regressions.
- **Major**: should fix before merge. Significant gaps, API issues.
- **Minor**: nice to fix. Style, documentation, small improvements.
- **Note**: observations that require no change. Pre-existing structural debt, broader-codebase patterns, follow-up ideas.

The review ends with one of three recommendations:

- `Approve`: correct enough to proceed.
- `Approve with minor changes`: proceed once the small findings are dealt with, no re-review needed.
- `Request changes`: at least one finding blocks the next step. Address it, then re-run `/dyalog:crev` for a fresh verdict.

A Critical finding blocks: a review carrying one returns `Request changes`. Major findings should be resolved before merge, though the reviewer may downgrade to `Approve with minor changes` when it trusts the author to clean them up. Minor findings and Notes never gate the verdict.

An `Approve` carrying several Minor findings and Notes isn't a soft pass; it's a deliberate signal that the work is correct enough to proceed *and* there are things worth thinking about. Read them. Address what's worth addressing. Open follow-up issues for the observations you care about.

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

Claude reproduces the bug (actually reproduces it; not "describes how to reproduce"), writes failing regression tests that pin the behaviour, investigates the code path, and writes `docs/bugs/<id>.md` containing the verified repro, the root-cause analysis (which file, which function, why it fails), a proposed fix outline, and an "Also Impacts" section covering wider implications of the root cause. The regression tests are written but not committed with the bug document; they belong to the implementation cycle.

Read it. Push back on any "facts" that look like guesses. Resolve the "Open questions" by editing the doc or by adding comments to the GitHub issue. If Claude could not reproduce the bug, do not let it move on. The RCA is built on the repro, and a fabricated repro produces a fabricated fix.

Once the RCA is solid, run `/dyalog:crev <id>` as normal. The reviewer has extra duties for bug work: it verifies the stated repro directly (and rejects the review outright if it cannot reproduce), confirms the fix addresses the root cause rather than papering over the symptom, and checks that the tests both demonstrate the bug and guard against its regression.

## When the pipeline gets in your way

It will, sometimes. Three situations come up:

**A trivial typo fix.** Someone asks you to change "colour" to "color" in a comment, or rename a variable. Going through planning and issues for a one-line change is more process than the change is worth. For changes under ten lines that have no behavioural impact, a direct edit and a commit is fine. The hooks still apply.

**An urgent production fix.** The pipeline is built for sustained work, not for incidents. In an incident, the rule is: fix it, ship it, write the post-mortem afterwards. Note that `/dyalog:bugfix` reproduces against unfixed code (its repro and regression tests must fail on the current tree), so it cannot run as-is once the fix is live. Capture the post-mortem by pointing it at the pre-fix commit, or write the repro and RCA up by hand. Either way, the repro and RCA still matter; they do not gate the merge.

**An exploratory spike.** You don't know what you're going to build yet. The pipeline assumes a plan exists. Do the spike on a throwaway branch, *outside* the pipeline. When you know what you want to build, throw the spike away and go through the proper planning phase. Do not try to retrofit a plan around code that already exists, the plan will be a justification, not a design.

Outside these three situations, the pipeline is the sensible default. The friction it adds is the price of the reviewable history and the second opinion it buys you.

## What you should not do

- Do not skip the code review step, even when "I can see the test is fine." The reviewer regularly catches things you would not spot on your own, and the cumulative effect of skipping reviews is a codebase where reviews quietly stop happening.
- Do not run `git commit` yourself during the cycle. The commands commit their own work, in the right format, with the right metadata. 
- Do not edit prior cycle entries in the PR doc. They are append-only. If a cycle's reasoning turned out to be wrong, the next cycle entry says so.
- Do not push `--force`. The hook blocks it. 
- Do not edit `.claude/hooks/`, `.claude/statusline/`, or `.claude/settings.json` from inside Claude Code. The hook blocks it. These are edited by humans, out-of-band, with full intent.

## What this gets you

A consistent pipeline gets you three things that matter:

- **Reviewable history.** Every PR has a doc that walks through the author's reasoning cycle by cycle. The reviewer reads it. The author of the next PR on the same code reads it six months later and understands why the code looks the way it does.
- **A second opinion at every stage**, for the cost of a `/dyalog:crev` invocation. Think of the reviewer as a colleague reading with fresh eyes: it notices things you overlooked, it is always available, and it never gets tired. Being another model, it shares some of your blind spots, so treat it as a complement to your own judgement rather than a replacement for it. Used that way, it earns its keep.
- **A working definition of "done"** that does not depend on anyone's mood. Done is: all tests pass, linters pass, the PR doc is honest, the latest review verdict is `Approve` (or `Approve with minor changes`). If those four things are true, the work is done. If any are false, it is not.

The cost is friction. You will sometimes write three prompts to do what felt like one task, or get a `Request changes` verdict on code you were sure was correct. Early on, follow the pipeline as written: think of it as a head start rather than a straitjacket. As you learn where it helps and where it slows you down, adapt it to fit your work. That is the intended destination, not a departure from it.
