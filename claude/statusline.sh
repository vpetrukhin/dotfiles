#!/usr/bin/env bash
# statusline Claude Code: каталог | модель | Git: репо@ветка | Context: N% used
# на вход — JSON сессии в stdin

input=$(cat)
current_dir=$(jq -r '.workspace.current_dir' <<<"$input")
model=$(jq -r '.model.display_name' <<<"$input")
used=$(jq -r '.context_window.used_percentage // empty' <<<"$input")

cd "$current_dir" 2>/dev/null
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
git_worktree=$(git rev-parse --show-toplevel 2>/dev/null)

git_info=""
[ -n "$git_branch" ] && [ -n "$git_worktree" ] && git_info=" | Git: $(basename "$git_worktree")@$git_branch"

context_info=""
[ -n "$used" ] && context_info=" | Context: ${used}% used"

echo "$current_dir | $model$git_info$context_info"
