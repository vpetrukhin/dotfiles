#!/usr/bin/env bash
set -e

# Создаёт daily-заметку в Obsidian workspace. Путь можно переопределить через DAILY_WORKSPACE.
workspace="${DAILY_WORKSPACE:-$HOME/workspaces/bankiru}"
daily_dir="$workspace/daily"
today="$(date '+%Y-%m-%d')"
target_date="${1:-$today}"

if [[ $# -gt 1 ]]; then
  echo "Использование: $(basename "$0") [YYYY-MM-DD]" >&2
  exit 1
fi

if ! date -j -f '%Y-%m-%d' "$target_date" '+%Y-%m-%d' >/dev/null 2>&1; then
  echo "Дата должна быть в формате YYYY-MM-DD: $target_date" >&2
  exit 1
fi

previous_date="$(date -j -v-1d -f '%Y-%m-%d' "$target_date" '+%Y-%m-%d')"
next_date="$(date -j -v+1d -f '%Y-%m-%d' "$target_date" '+%Y-%m-%d')"
target_file="$daily_dir/$target_date.md"

if [[ -e "$target_file" ]]; then
  echo "Заметка уже существует: $target_file" >&2
  exit 1
fi

mkdir -p "$daily_dir"

cat >"$target_file" <<EOF
# $target_date

## 🎯 Главная цель дня

## ✅ Задачи на сегодня

## 📝 Заметки

## 📊 Итоги дня

### Сделано

-

### Не сделано (перенести)

-

### Инсайты

- ***

  [[tasks/active|Все задачи]] | [[$previous_date|Вчера]] | [[$next_date|Завтра]]
EOF

echo "Создана заметка: $target_file"
