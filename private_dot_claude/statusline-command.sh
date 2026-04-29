#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)
dir=$(basename "$cwd")

model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Format numbers with comma separators
fmt_tokens=""
fmt_window=""
if [ -n "$input_tokens" ] && [ -n "$window_size" ]; then
  fmt_tokens=$(printf "%d" "$input_tokens" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
  fmt_window=$(printf "%d" "$window_size"  | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
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

printf "\033[33m%s\033[0m\033[32m%s\033[0m\033[35m%s\033[0m\033[90m%s\033[0m" \
  "$dir" "$git_str" "$model_str" "$ctx_str"
