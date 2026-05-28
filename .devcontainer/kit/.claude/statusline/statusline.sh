#!/usr/bin/env bash
#
# Workshop status line.
#
# Three pieces of information, in fixed order:
#   1. Current git branch (or "no-branch" / "no-git")
#   2. Context window usage (percentage + raw tokens, colour-coded)
#   3. Headroom before auto-compact triggers
#
# Auto-compact is undocumented but consistently observed to trigger at
# ~95% of the context window. AUTO_COMPACT_THRESHOLD below is editable
# if Anthropic changes this.
#
# Reads the Claude Code statusline JSON from stdin. Outputs a single line.
# Errors are silent, a broken statusline must never block Claude Code.

set -u   # NOT set -e, we want to keep going if a field is missing.

# Tunable: auto-compact threshold, percent of context window.
AUTO_COMPACT_THRESHOLD=95

# Tunable: ANSI colours. Comment out the value to drop colour for that field.
C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'

# ─── Read input ───────────────────────────────────────────────────────────

input=$(cat)

# If jq isn't installed, render a minimal line and exit cleanly.
if ! command -v jq >/dev/null 2>&1; then
  echo "(install jq for a working status line)"
  exit 0
fi

# All field reads use `// empty` or `// 0` so missing fields don't abort.
cwd=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
used_pct_raw=$(jq -r '.context_window.used_percentage // 0' <<<"$input")
ctx_size=$(jq -r '.context_window.context_window_size // 200000' <<<"$input")
current_usage_present=$(jq -r '.context_window.current_usage // empty' <<<"$input")
input_toks=$(jq -r '.context_window.current_usage.input_tokens // 0' <<<"$input")
cache_creation=$(jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' <<<"$input")
cache_read=$(jq -r '.context_window.current_usage.cache_read_input_tokens // 0' <<<"$input")

# ─── Branch ──────────────────────────────────────────────────────────────

branch_segment=""
if [[ -n "$cwd" ]] && [[ -d "$cwd" ]]; then
  # --no-optional-locks avoids contending with concurrent git operations.
  if git -C "$cwd" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || true)
    if [[ -n "$branch" ]]; then
      branch_segment="${C_CYAN}${branch}${C_RESET}"
    else
      # Detached HEAD: show the short SHA so the user knows what they're on.
      sha=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null || echo "?")
      branch_segment="${C_DIM}detached@${sha}${C_RESET}"
    fi
  else
    branch_segment="${C_DIM}no-git${C_RESET}"
  fi
else
  branch_segment="${C_DIM}no-cwd${C_RESET}"
fi

# ─── Context usage ───────────────────────────────────────────────────────

# `used_percentage` is a float in some versions; strip the decimal.
used_pct=${used_pct_raw%.*}
[[ -z "$used_pct" ]] && used_pct=0

# Compute used tokens for the display. used_percentage is input-only, matching
# the documented formula: input + cache_creation + cache_read.
if [[ -n "$current_usage_present" ]]; then
  used_toks=$((input_toks + cache_creation + cache_read))
else
  # Before the first API call (or just after /compact), current_usage is null.
  used_toks=0
fi

# Format used tokens compactly: "12.3k" / "184k".
fmt_tokens() {
  local n=$1
  if (( n < 1000 )); then
    printf '%d' "$n"
  elif (( n < 10000 )); then
    # one decimal place, e.g. 1.2k
    printf '%d.%dk' $((n / 1000)) $(((n % 1000) / 100))
  else
    printf '%dk' $((n / 1000))
  fi
}

used_fmt=$(fmt_tokens "$used_toks")
total_fmt=$(fmt_tokens "$ctx_size")

# Colour by usage band.
if   (( used_pct < 50 )); then ctx_colour=$C_GREEN
elif (( used_pct < 80 )); then ctx_colour=$C_YELLOW
else                           ctx_colour=$C_RED
fi

ctx_segment="${ctx_colour}ctx ${used_pct}% (${used_fmt}/${total_fmt})${C_RESET}"

# ─── Auto-compact headroom ───────────────────────────────────────────────

# Headroom = threshold - used_pct. Below zero means auto-compact is overdue
# and likely fires on the next turn.
headroom=$((AUTO_COMPACT_THRESHOLD - used_pct))

if   (( headroom > 30 )); then ac_colour=$C_DIM
elif (( headroom > 10 )); then ac_colour=$C_YELLOW
else                           ac_colour=$C_RED
fi

if (( headroom < 0 )); then
  ac_segment="${C_RED}auto-compact imminent${C_RESET}"
else
  ac_segment="${ac_colour}${headroom}% to auto-compact${C_RESET}"
fi

# ─── Compose ─────────────────────────────────────────────────────────────

sep="${C_DIM} │ ${C_RESET}"
printf '%s%s%s%s%s\n' "$branch_segment" "$sep" "$ctx_segment" "$sep" "$ac_segment"
