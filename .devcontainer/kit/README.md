# agent-dev-container kit

A small, opinionated configuration that drops into any project to give Claude Code:

- Hooks that block the common foot-guns (force-push, `--no-verify`, `git add` wildcards, edits to `.env`, `.git/`, and the kit's own safety files) and that stop reading secret files such as `.env` and private keys.
- An audit log of every tool call.
- A status line showing the git branch, context-window usage, and headroom before auto-compact.
- Skills for searching Dyalog APL documentation and executing APL snippets.
- Two slash commands, `/dyalog:bugfix` and `/dyalog:crev`, for the two situations where structured input beats conversation: bug investigation and code review.
- Project conventions (`CLAUDE.md`) and a day-to-day workflow document (`PROCESS.md`).

The intended workflow is plan-mode-driven, TDD, with reviews at every stage. The slash commands cover the steps where the template earns its keep; everything else is ordinary conversation.

**Version:** see [`VERSION`](VERSION). **Changelog:** [`CHANGELOG.md`](CHANGELOG.md). **Licence:** MIT.

## Quick start

After installation in your project, start Claude Code in the project root:

```
claude
```

Begin a feature with shift-tab to enter plan mode, state what you want, and let Claude propose a plan. Save it to `docs/plans/<slug>.md` when you are happy with it. See `PROCESS.md` for the full walkthrough.

For bugs: `/dyalog:bugfix <issue-number>` produces a verified repro, root-cause analysis, and fix outline.

At any review point: `/dyalog:crev <issue-number>` or `/dyalog:crev docs/plans/<slug>.md`.

## Cheat sheets

Four printable one-page references sit at the kit root:

- [`pipeline-cheatsheet.html`](pipeline-cheatsheet.html): the plan-to-merge workflow at a glance, the visual companion to `PROCESS.md`. Hosted artifact: https://claude.ai/code/artifact/d1f2b87b-a145-4a8a-9465-986498059639
- [`claude-code-commands.html`](claude-code-commands.html): Claude Code's built-in slash commands, keyboard shortcuts, and input modes. Hosted artifact: https://claude.ai/code/artifact/98f69443-5bd1-4744-b980-e537c5dbf688
- [`pro-tips-cheatsheet.html`](pro-tips-cheatsheet.html): the pro tips from the Coding with Agents workshop, distilled onto one page. Hosted artifact: https://claude.ai/code/artifact/1eb7a9ee-0f08-4efc-897a-0c86a3b7469a
- [`anatomy-of-a-skill.html`](anatomy-of-a-skill.html): how a Claude Code skill is built (folder layout, SKILL.md anatomy, progressive disclosure). Hosted artifact: https://claude.ai/code/artifact/238feb03-0fc9-49b9-ae65-9da7b99336e7

The hosted artifacts are visible only to members of the Dyalog organisation. Anyone without org access should open the in-repo `.html` file instead, then print or save as PDF for a handout.

`PROCESS.md` itself is also published as a hosted page in the same house style (the full workflow document, not a one-page summary), visible to the Dyalog organisation: https://claude.ai/code/artifact/d1b031a8-cbc4-4aea-8b29-1077cfdd5ab6. It has no in-repo `.html`; the Markdown `PROCESS.md` is the source of truth, and the hosted page is refreshed by hand when the document changes.

## What's in the box

```
.
├── CLAUDE.md                              project memory: conventions, branch naming, writing style, definition of done
├── PROCESS.md                             how to take a feature from idea to merged PR using the kit
├── pipeline-cheatsheet.html               printable one-page summary of the PROCESS.md workflow
├── claude-code-commands.html              printable reference: Claude Code built-in commands and shortcuts
├── pro-tips-cheatsheet.html               printable one-page distillation of the workshop pro tips
├── anatomy-of-a-skill.html                printable reference: how a Claude Code skill is built
├── CHANGELOG.md                           release notes
├── VERSION                                semver version of this kit
├── LICENSE                                MIT
└── .claude/
    ├── README.md                          settings.json reference (attribution, LSP, statusline, hooks)
    ├── settings.json                      project-level Claude Code config
    ├── commands/
    │   ├── README.md                      what the slash commands do, and what is not a slash command
    │   └── dyalog/
    │       ├── bugfix.md                  /dyalog:bugfix, investigates a bug (repro, RCA, fix outline; NO code)
    │       └── crev.md                    /dyalog:crev, structured review at any stage; writes docs/reviews/<id>.md
    ├── skills/                            model-triggered skills (loaded automatically by Claude)
    │   ├── dyalog-docsearch/SKILL.md      search the local Dyalog docs corpus via `docsearch`
    │   └── dyalog-script/SKILL.md         execute APL code via `dyalogscript`
    ├── hooks/
    │   ├── README.md                      what each hook does
    │   ├── block-dangerous-bash.sh        deny-list: force-push, --no-verify, test bypass flags, git add wildcards, writes to protected paths, reads of secret files, etc.
    │   ├── protect-paths.sh               deny-list (writes): .env, .git/, .claude/ safety files, .mcp.json, credential dirs, CLAUDE.local.md
    │   ├── protect-reads.sh               deny-list (reads): .env, credential dirs, private keys, CLAUDE.local.md
    │   └── audit-log.sh                   non-blocking record of every tool call
    └── statusline/
        └── statusline.sh                  branch | context usage | auto-compact headroom
```

## Adopting the kit on an existing project

Copy `CLAUDE.md`, `PROCESS.md`, and `.claude/` into your project root. Make the hook and statusline scripts executable:

```
chmod +x .claude/hooks/*.sh .claude/statusline/*.sh
```

Merge this kit's `.gitignore` entries into your project's `.gitignore`. You will need `jq`, `git`, and `gh` available locally. Restart Claude Code.

Inside the agent-dev-container, the helper `install-kit-here` performs the copy and the chmod for you; see `.devcontainer/README.md`.

## Customising for your team

- **Rename the `/dyalog:` namespace.** Move `.claude/commands/dyalog/` to `.claude/commands/<your-prefix>/` and run a project-wide find-and-replace from `/dyalog:` to `/<your-prefix>:`.
- **Writing-style rules in `CLAUDE.md`** to match your team's conventions.
- **LSP plugins** in `.claude/settings.json` to match the languages you work in.
- **Severity rubric** in `.claude/commands/dyalog/crev.md` to tighten or relax the review gate.
- **Auto-compact threshold** in `.claude/statusline/statusline.sh` if your model's auto-compact point differs from the default 95%.

Forks own their own version. Updates from upstream are cherry-picked manually; there is no automatic upgrade path.

## Versioning

The kit follows [Semantic Versioning](https://semver.org/). The current version is in [`VERSION`](VERSION); release history is in [`CHANGELOG.md`](CHANGELOG.md). While the kit is `0.x`, expect breaking changes between minor versions.

Projects bootstrapped from this kit via `install-kit-here` carry a `KIT_VERSION` file recording the source version. Cherry-picked updates should bump it.

## Reporting issues, contributing

Issues and PRs welcome at https://github.com/dyalog-labs/agent-dev-container/issues.

When filing an issue, include the contents of `VERSION` (or `KIT_VERSION` if you bootstrapped via the dev container).
