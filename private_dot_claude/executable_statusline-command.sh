#!/bin/sh
input=$(cat)

# Portable thousands separator (BSD/macOS awk safe)
fmt_num() {
  printf "%d" "$1" | awk '{
    n=$0; s=""; len=length(n)
    for (i=1; i<=len; i++) {
      s = s substr(n,i,1)
      r = len - i
      if (r > 0 && r % 3 == 0) s = s ","
    }
    print s
  }'
}

# Color for a usage percentage: green < 50, yellow 50-80, red >= 80
pct_color() {
  awk -v p="$1" 'BEGIN{ if (p>=80) print "\033[31m"; else if (p>=50) print "\033[33m"; else print "\033[32m" }'
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
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Format numbers with comma separators
fmt_tokens=""
fmt_window=""
if [ -n "$input_tokens" ] && [ -n "$window_size" ]; then
  fmt_tokens=$(fmt_num "$input_tokens")
  fmt_window=$(fmt_num "$window_size")
fi

# Git branch (skip optional locks)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

# Build context string
ctx_str=""
if [ -n "$used" ] && [ -n "$fmt_tokens" ]; then
  ctx_str=" ctx:${used}% (${fmt_tokens} / ${fmt_window})"
elif [ -n "$used" ]; then
  ctx_str=" ctx:${used}%"
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

# Build rate-limit string (5h session + 7d weekly usage %).
# Fields only present for subscription accounts after the first API response;
# each may be independently absent.
limit_str=""
if [ -n "$five_h" ]; then
  c=$(pct_color "$five_h")
  limit_str="${limit_str} ${c}5h:$(printf '%.0f' "$five_h")%%\033[0m"
fi
if [ -n "$week" ]; then
  c=$(pct_color "$week")
  limit_str="${limit_str} ${c}wk:$(printf '%.0f' "$week")%%\033[0m"
fi

printf "${acct_str}\033[33m%s\033[0m\033[32m%s\033[0m\033[35m%s\033[0m${cost_color}%s\033[0m\033[90m%s\033[0m${limit_str}" \
  "$dir" "$git_str" "$model_str" "$cost_str" "$ctx_str"
