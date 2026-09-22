#!/bin/sh
input=$(cat)

# Compact a window size for display: 1000000 -> 1M, 200000 -> 200k. Keeps one
# decimal only when the value isn't a round multiple (1500000 -> 1.5M).
fmt_short() {
  awk -v n="$1" 'BEGIN{
    if (n >= 1000000) printf "%gM", n/1000000
    else if (n >= 1000) printf "%gk", n/1000
    else printf "%d", n
  }'
}

# Color for a usage percentage: green < 50, yellow 50-80, red >= 80
pct_color() {
  awk -v p="$1" 'BEGIN{ if (p>=80) print "\033[31m"; else if (p>=50) print "\033[33m"; else print "\033[32m" }'
}

# Format an epoch (seconds) with a strftime pattern. BSD/macOS `date -r` first;
# on GNU that flag expects a file, so it fails and we fall back to `date -d @`.
fmt_epoch() {
  date -r "$1" +"$2" 2>/dev/null || date -d "@$1" +"$2" 2>/dev/null
}

# --- Account detection (shared script, behaves per-account) ---
# Find the active account file. When launched with CLAUDE_CONFIG_DIR (e.g. the
# work `ccw` alias) it lives inside that dir; the personal default lives at
# $HOME/.claude.json. First existing file wins.
acct_file=""
for f in "${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}" "$HOME/.claude.json" "$HOME/.claude/.claude.json"; do
  [ -n "$f" ] && [ -f "$f" ] && { acct_file="$f"; break; }
done

org_type=""
org_name=""
if [ -n "$acct_file" ]; then
  org_type=$(jq -r '.oauthAccount.organizationType // empty' "$acct_file" 2>/dev/null)
  org_name=$(jq -r '.oauthAccount.organizationName // empty' "$acct_file" 2>/dev/null)
fi

# Enterprise/work badge (bold cyan text). Pro/personal -> no badge.
acct_str=""
case "$org_type" in
  *enterprise*)
    acct_str="\033[1;36mWORK:${org_name:-acct}\033[0m "
    ;;
esac

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)
dir=$(basename "$cwd")

model=$(echo "$input" | jq -r '.model.display_name // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
# Window size only. The raw token count is redundant with used_percentage; the
# window itself isn't, since it says whether a given percent is of 200k or 1M.
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

fmt_window=""
[ -n "$window_size" ] && fmt_window=$(fmt_short "$window_size")

# Git branch (skip optional locks)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

# Build context string. The percentage carries the same green/yellow/red
# thresholds as the 5h/wk windows above; the window size stays dim since it's
# detail, not status. Note the %% -- ctx_str is spliced into the printf
# *format*, like limit_str, so a literal percent must be escaped.
ctx_str=""
if [ -n "$used" ]; then
  c=$(pct_color "$used")
  ctx_str=" ${c}ctx:${used}%%\033[0m"
  [ -n "$fmt_window" ] && ctx_str="${ctx_str} \033[90m(${fmt_window})\033[0m"
fi

# Build git string
git_str=""
if [ -n "$branch" ]; then
  git_str=" on ${branch}"
fi

# Build model string
model_str=""
if [ -n "$model" ]; then
  model_str=" [${model}]"
fi

# Build session cost string (API-equivalent cost of this session).
# On a subscription (Plus/Pro) this figure never bills you -- the real
# constraints are the 5h/wk rate limits below -- so thresholds are relaxed and
# only flag a genuinely huge session. When billing is real (enterprise org or a
# bare ANTHROPIC_API_KEY), tighten them so an expensive session stands out.
#   personal: green < $15, yellow $15-40, red >= $40
#   work:     green < $5,  yellow $5-15,  red >= $15
real_billing=0
case "$org_type" in *enterprise*) real_billing=1 ;; esac
[ -n "$ANTHROPIC_API_KEY" ] && real_billing=1

cost_str=""
cost_color="\033[32m"
if [ -n "$cost" ]; then
  cost_str=$(printf " \$%.2f" "$cost")
  cost_color=$(awk -v c="$cost" -v rb="$real_billing" 'BEGIN{
    if (rb) { hi=15; mid=5 } else { hi=40; mid=15 }
    if (c>=hi) print "\033[31m"; else if (c>=mid) print "\033[33m"; else print "\033[32m"
  }')
fi

# Build rate-limit string (5h session + 7d weekly usage %), each followed by
# when that window resets: clock time for the 5h window (always <5h out), date
# for the weekly one. Reset markers stay uncolored -- they report a schedule,
# not a status. Fields only present for subscription accounts after the first
# API response; usage % and resets_at may each be independently absent.
limit_str=""
if [ -n "$five_h" ]; then
  c=$(pct_color "$five_h")
  r=""
  [ -n "$five_h_reset" ] && r=$(fmt_epoch "$five_h_reset" "%H:%M")
  limit_str="${limit_str} ${c}5h:$(printf '%.0f' "$five_h")%%\033[0m${r:+ ($r)}"
fi
if [ -n "$week" ]; then
  c=$(pct_color "$week")
  r=""
  [ -n "$week_reset" ] && r=$(fmt_epoch "$week_reset" "%b %-d")
  limit_str="${limit_str} ${c}wk:$(printf '%.0f' "$week")%%\033[0m${r:+ ($r)}"
fi

printf "${acct_str}\033[33m%s\033[0m\033[32m%s\033[0m\033[35m%s\033[0m${cost_color}%s\033[0m${ctx_str}${limit_str}" \
  "$dir" "$git_str" "$model_str" "$cost_str"
