#!/usr/bin/env bash
# Синтаксис shell-конфигов репозитория: bash -n для *.sh, zsh -n для *.zsh и zprofile.
# private/ не версионируется, .git и runtime-каталоги не наши — не трогаем.
# Запускается из корня репозитория (mise run check:shell), но работает и напрямую.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

bash_files=()
while IFS= read -r -d '' f; do
  bash_files+=("$f")
done < <(find . \( -name .git -o -name private -o -name node_modules -o -name .cache -o -name .venv -o -name sessions -o -name logs \) -prune -o -type f -name '*.sh' -print0)
if [ "${#bash_files[@]}" -eq 0 ]; then
  echo "не найдено ни одного *.sh" >&2
  exit 1
fi
for f in "${bash_files[@]}"; do
  bash -n "$f"
  echo "ok bash: ${f#./}"
done

if ! command -v zsh >/dev/null 2>&1; then
  echo "не найден zsh — проверка zsh-конфигов невозможна" >&2
  exit 1
fi
zsh_files=()
while IFS= read -r -d '' f; do
  zsh_files+=("$f")
done < <(find . \( -name .git -o -name private -o -name node_modules -o -name .cache -o -name .venv -o -name sessions -o -name logs \) -prune -o -type f \( -name '*.zsh' -o -name 'zprofile' \) -print0)
if [ "${#zsh_files[@]}" -eq 0 ]; then
  echo "не найдено ни одного zsh-конфига" >&2
  exit 1
fi
for f in "${zsh_files[@]}"; do
  zsh -n "$f"
  echo "ok zsh: ${f#./}"
done
