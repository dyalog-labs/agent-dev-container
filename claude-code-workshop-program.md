# Claude Code: Safe & Effective Use, One-Day Workshop

**Audience:** Experienced software developers, new to AI coding agents
**Environment:** VS Code + Dev Container (Anthropic reference container or fork)
**Duration:** ~7 hours net of breaks
**Outcome:** Every attendee leaves able to drive Claude Code through a disciplined plan → issue → TDD loop using ordinary conversation and two structured slash commands (`/dyalog:bugfix`, `/dyalog:crev`), with hooks and permissions configured to fail safely.

---

## Pre-workshop (sent 3 to 5 days before)

Non-negotiable. If people walk in with no setup, the day is lost.

- Install Docker Desktop and VS Code with the Dev Containers extension.
- Clone the agent-dev-container repo: `git clone https://github.com/dyalog-labs/agent-dev-container.git` (contains the `.devcontainer/`, sample app, prebuilt CLAUDE.md, slash commands, and hooks).
- Open in VS Code → "Reopen in Container" → confirm `claude --version` works.
- Sign in to Claude Code once on the host, *outside* the container, so credentials are ready to mount.
- A "Setup complete" message in the workshop Slack channel by the day before.

Have a fallback: a Codespaces config in the same repo for anyone whose Docker setup is broken.

---

## 09:00 to 09:15  Welcome & framing (15 min)

- The day in one sentence: *learn the features, then learn a process that constrains you to use them well.*
- House rules: pair up; no chat with the model that you wouldn't put in a PR comment.
- Quick poll: who has used Copilot? Cursor? Claude Code? Sets your calibration.

---

## Part 1, Features and capabilities (09:15 to 12:30)

Goal: a shared mental model of what Claude Code is and what each piece does. Demo-heavy, short hands-on between demos.

### 09:15 to 09:45  The shape of Claude Code (30 min)

- It's a terminal agent: REPL + tools (Read, Edit, Write, Bash, Glob, Grep, Task).
- Why a dev container: layered safety, in-process permissions are not OS-level isolation. The container is your blast radius.
- Walk through the `.devcontainer/` they already opened: non-root user, mounted workspace only, network firewall (`init-firewall.sh`), why `--dangerously-skip-permissions` is acceptable *inside* this container and dangerous outside it.
- Distinguish three things people will conflate all day:
  - **Container isolation**, OS-level, Docker's job.
  - **Permission modes**, Claude Code's allow/ask/deny rules.
  - **Bash sandbox**, bubblewrap-based, applies to Bash tool only.

**Hands-on (5 min):** Open Claude, ask it to read a file, observe the permission prompt. Toggle through modes.

### 09:45 to 10:15  Permission modes & plan mode (30 min)

- The four modes: plan, default (ask), auto/acceptEdits, bypassPermissions. When each is appropriate.
- **Plan mode is not just "don't write yet."** It spawns a read-only Plan subagent that researches the codebase, then returns a proposal you approve. Show this in the UI, it makes the "subagents keep context clean" point concrete later.
- Demo: same task in default mode vs plan mode. Show the difference in output structure.

**Hands-on (10 min):** Each pair runs the same prompt, *"add input validation to the `/users` POST endpoint"*, once in default, once in plan mode. Discuss the difference.

### 10:15 to 10:30  Break

### 10:30 to 11:00  CLAUDE.md and context (30 min)

- Project memory: `CLAUDE.md` (committed) vs `CLAUDE.local.md` (gitignored) vs `~/.claude/CLAUDE.md` (user-global).
- What belongs there: stable conventions, build/test commands, "do not touch" lists, definitions of done. *Not* one-off task notes.
- Context drift in long sessions, why short CLAUDE.md files beat long ones.
- Walk through the workshop repo's CLAUDE.md as a worked example.

**Hands-on (10 min):** Add one project convention to CLAUDE.md, prove Claude follows it on the next turn.

### 11:00 to 11:30  Slash commands and skills (30 min)

- **Slash commands:** explicit, repeatable entry points. A `.md` file in `.claude/commands/`. Single-file, terminal autocomplete, great for *workflows you invoke deliberately*.
- **Skills:** auto-discovered playbooks (directory with `SKILL.md` + supporting files). Claude picks them up when the description matches the task. Great for *expertise you want applied automatically*.
- Decision rule: invoke deliberately → slash command. Apply automatically when relevant → skill.
- Demo both with one trivial example each from the workshop repo.

### 11:30 to 12:00  Subagents and hooks (30 min)

Treat both at the conceptual level, no live authoring.

- **Subagents:** workers with isolated context. Built-in (Plan, Explore, general-purpose) are invoked automatically. Custom ones live in `.claude/agents/` (this kit ships none; the surviving slash commands handle structured review inline). Right answer when work is *noisy, bounded, easy to summarize* (test runs, doc lookups, codebase exploration). Wrong answer when work is tightly coupled to the main thread.
- **Hooks: the one deterministic guardrail.** PreToolUse, PostToolUse, etc. Shell scripts that fire every time. Prompts are suggestions, hooks are guarantees.
- Demo a `PreToolUse` hook that blocks edits to `.env` or any path matching a deny-list. Try to make Claude edit `.env`. Watch it fail.
- Mention MCP in one sentence: "external services as tools, GitHub, Linear, Slack, etc. We'll use the GitHub one in Part 2."

### 12:00 to 12:30  Quick recap + Q&A (30 min)

Whiteboard the layers: container → permissions → plan mode → CLAUDE.md → slash commands/skills → subagents → hooks. People should be able to point at each layer and say what it's for.

---

## 12:30 to 13:30  Lunch

---

## Part 2, A repeatable process (13:30 to 16:00)

Goal: drive one feature end-to-end through a constrained pipeline. No freestyle prompting.

### 13:30 to 13:45  The pitch (15 min)

- Why "no freestyle prompting." The expensive mistake isn't bad code, it's the model writing 200 lines that solve the wrong problem.
- The pipeline you'll use today, written on the whiteboard and not deviated from:
  1. Plan mode: state the feature, let Claude propose a plan in `docs/plans/<slug>.md`. You read it. You edit it.
  2. `/dyalog:crev docs/plans/<slug>.md` for a structured second opinion on the plan.
  3. Ask Claude to convert the approved plan into a GitHub epic and child issues.
  4. For each issue: ask Claude to "Proceed with issue N" (writes RED), then `/dyalog:crev N`. If approved, ask Claude to proceed again (writes GREEN), then `/dyalog:crev N` again. Repeat until a GREEN cycle is approved.
  5. Ask Claude to run the full suite, push, and open a PR.
- Two slash commands and a lot of conversation. The slash commands exist where structured input pays off (bug investigation, review). The rest is plan-mode and chat.

### 13:45 to 14:30  Planning and issue generation (45 min)

- Demo plan mode against the workshop sample app. Shift-tab, state the goal in two sentences, watch Claude explore the codebase and write a plan. Drop out of plan mode and ask Claude to save the plan to `docs/plans/<slug>.md`.
- **Mandatory review stop.** They read it. They edit it. They do not skip this. In a separate agent terminal, run `/dyalog:crev docs/plans/<slug>.md` for an adversarial second opinion. Paste back any blockers and ask Claude to revise.
- Once the plan is good, ask Claude to "convert the plan at `docs/plans/<slug>.md` into a GitHub epic and child issues, each referencing the plan document for context." `gh` does the heavy lifting under the hood.

**Hands-on:** Each pair plans the same feature against the workshop sample app. Compare plans across pairs. Notice the variance, that's why the review stop exists.

### 14:30 to 14:45  Break

### 14:45 to 15:45  TDD loop with mandatory stops (60 min)

- Pick the first child issue. Ask Claude: "Proceed with issue N." Claude creates the feature branch, writes the failing test surface (RED phase), creates `docs/prs/<N>.md` with the cycle entry, commits, and stops. Verify every test fails for the right reason.
- **Stop.** In a fresh review terminal (`/clear` then `/dyalog:crev N`). The reviewer writes `docs/reviews/<N>.md`. Read the verdict and the comments. Is the test surface testing the right things?
- If approved, ask Claude to "Proceed" again. Now in GREEN phase, it implements the surface one test at a time with minimum change per test. No refactors, no scope creep.
- **Stop.** `/dyalog:crev N` again. Read the diff and the verdict.
- If the verdict is `request changes`, ask Claude to address the blockers, then re-run `/dyalog:crev N`. Repeat until a GREEN cycle is approved.
- When the cycle is approved, ask Claude: "Run the full suite, then push the branch and open a pull request summarising `docs/prs/<N>.md`."

**Hands-on:** Each pair works one issue from their plan through the loop. Pairs swap "driver" between proceed steps and `/dyalog:crev` invocations.

The reviews are the workshop. If they're hurried through, the process collapses to "AI writes code, I press enter." Set the expectation explicitly.

### 15:45 to 16:00  Retro on the process (15 min)

- What felt slow? What felt unsafe? What would they change?
- Where did the model try to scope-creep? Where did the hooks save them?

---

## 16:00 to 16:15  Break

---

## Hackathon, 16:15 to 17:30 (75 min)

Three pre-baked tracks against the workshop sample app. Each pair picks one:

1. **Bug bash**, three failing tests in the repo, fix them using the pipeline.
2. **New feature**, small but real, with acceptance criteria provided.
3. **Safety challenge**, try to make Claude do something destructive; the hooks should stop it. Report what you tried and whether it worked. (This one is the most educational; budget at least one pair for it.)

Last 10 minutes: each pair shows one thing, a diff, a near-miss, a hook that fired. Two minutes each, hard limit.

---

## 17:30  Close

- Pointers to docs they'll actually use: the Claude Code docs map, the dev container reference, the hooks reference.
- The agent-dev-container repo stays as their starter template, fork it for their own projects.
- One ask: try the pipeline on a real task within the next week and report back.

---

## Cuts if you run over

In priority order, drop these first:
1. Skills detail (just mention them, skip the demo)
2. The retro at 15:45
3. The third hackathon track
4. Subagents, demo only, no hands-on (already light)

## What to pre-build in the workshop repo

- `.devcontainer/` based on Anthropic's reference, tested on macOS and Windows/WSL2. This repo's `.devcontainer/` is the working version.
- `CLAUDE.md` with a worked example. This repo's `.devcontainer/kit/CLAUDE.md` is the working version.
- `.claude/commands/dyalog/`: `bugfix.md` and `crev.md`. This repo's `.devcontainer/kit/.claude/commands/dyalog/` is the working version.
- `.claude/hooks/`: PreToolUse hooks blocking edits to `.env`, `.git/`, and any path in a deny-list; PreToolUse hook on Bash blocking force-push, `--no-verify`, `git add` wildcards, etc.
- `sample-app/`, a small Node or Python service with a couple of intentional bugs and a feature gap. Not yet in this repo; build before the workshop.
- `HACKATHON.md`, the three tracks with acceptance criteria. Not yet in this repo; build before the workshop.
