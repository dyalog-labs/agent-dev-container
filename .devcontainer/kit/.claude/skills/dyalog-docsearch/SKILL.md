---
name: dyalog-docsearch
description: Search the local Dyalog documentation corpus with the `docsearch` CLI. Use when the user asks for Dyalog documentation, language-reference lookup, symbol semantics, or explicitly mentions `docsearch`.
---

# Dyalog Docsearch

Use this skill for local Dyalog manual lookups. Prefer it over web search when the question is about Dyalog syntax, system functions, namespaces, control structures, or reference-manual wording and the local corpus is sufficient.

## Workflow

1. Search for likely matches with `docsearch -s 'query' -l N`.
2. Read the best hit with `docsearch -r ROWID`.
3. If needed, fetch a few nearby hits and compare before answering.
4. Summarize the manual entry in your own words unless the user asked for a short excerpt.

## Commands

Basic search:

```bash
docsearch -s '⎕FIX' -l 5
```

Long or shell-sensitive query via stdin:

```bash
printf '%s' 'namespace reference evaluation' | docsearch -s - -l 5
```

Fetch a document by rowid:

```bash
docsearch -r 313
```

## Observed CLI behavior

- `docsearch -s ...` returns one hit per line as `<rowid> <title>`.
- `docsearch -r ROWID` prints the full document with a Markdown-style heading and body text.
- No output from `-s` means no hits.
- The default database path is `~/.bundle-docs/dyalog-docs.db`; don't pass `-d` unless the user specifies a different corpus.
- The default result limit is 10; omit `-l` unless you want fewer results.
- If the database is missing, tell the user to run `bundle-docs update` to build it from upstream. In the agent-dev-container the database is pre-populated, so a missing database is unexpected and worth investigating before suggesting a rebuild.

## Working style

- Search by the exact glyph or symbol first for system functions and control words, for example `⎕FIX`, `⎕FX`, `:If`, `namespace reference`.
- If the first search is broad, refine with a shorter, more literal query rather than a longer natural-language sentence.
- When the user asks how something behaves, read the full rowid entry before answering.
- Stay on the CLI. Do not query or open the SQLite database directly; always use the `docsearch` command.

## Examples

User asks: "Look up `⎕FIX` in the Dyalog docs."
- Run `docsearch -s '⎕FIX' -l 5`
- Open the best row with `docsearch -r <rowid>`
- Answer from the fetched entry

User asks: "How does namespace reference evaluation work in Dyalog?"
- Run `printf '%s' 'namespace reference evaluation' | docsearch -s - -l 5`
- Read the best row with `docsearch -r <rowid>`
- Summarize the evaluation steps
