#!/usr/bin/env bash
# Валидность версионируемых JSON. Только файлы под git: private/ и runtime
# (lazy-lock.json и подобное) в список не попадают.
# Файл с комментариями — не строгий JSON; если такой появится, его нужно явно
# исключить из проверки, а не ослаблять jq.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v jq >/dev/null 2>&1; then
  echo "не найден jq — проверка JSON невозможна (brew install jq)" >&2
  exit 1
fi

json_files=()
while IFS= read -r -d '' f; do
  json_files+=("$f")
done < <(git ls-files -z -- '*.json')
if [ "${#json_files[@]}" -eq 0 ]; then
  echo "в git нет ни одного *.json" >&2
  exit 1
fi
for f in "${json_files[@]}"; do
  jq -e . "$f" >/dev/null
  echo "ok json: $f"
done
