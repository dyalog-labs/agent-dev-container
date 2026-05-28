---
name: dyalog-script
description: This Skill executes APL code via the `dyalogscript` interpreter.
---

# Dyalog-Script

## Instructions

`dyalogscript` is an interpreter that can execute APL code from the commandline, without relying on a full, running Dyalog session.

### Quick evaluation (preferred for short snippets)

Pipe a one-liner via `echo`, or use a heredoc for a few lines:

```bash
# One-liner
echo "⎕←(+⌿÷≢)⍳100" | dyalogscript /dev/stdin

# Multi-line
dyalogscript /dev/stdin <<'EAPL'
⎕←(+⌿÷≢)⍳100
⎕←'hello world'
EAPL
```

### File-based execution (for longer scripts)

```bash
dyalogscript my_apl_program.apls
```

When using files: give them unique names, ensure a trailing newline, and remove ephemeral scripts after evaluation.

## Notes

1. You MUST use `⎕←` to print values to `stdout`, bare expressions produce no output.
2. Use `⋄` to separate multiple statements on a single line when piping via `echo`.

## Examples

User: Evaluate `(+⌿÷≢)⍳100` as Dyalog APL

```bash
$ echo "⎕←(+⌿÷≢)⍳100" | dyalogscript /dev/stdin
50.5
```

User: Show me strand assignment with depths

```bash
$ dyalogscript /dev/stdin <<'EAPL'
x y←'hello' (1 2 3)
⎕←x
⎕←y
⎕←≡x
⎕←≡y
EAPL
hello
1 2 3
1
1
```
