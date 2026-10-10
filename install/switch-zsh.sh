#!/usr/bin/env bash

set -e

# После установки Homebrew его bin может ещё не быть в PATH текущего shell.
if command -v brew >/dev/null 2>&1; then
  brew_bin=$(command -v brew)
elif [ -x /opt/homebrew/bin/brew ]; then
  brew_bin=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  brew_bin=/usr/local/bin/brew
else
  echo 'Homebrew не найден: сначала установи пакеты из install/Brewfile' >&2
  exit 1
fi

zsh_bin="$("$brew_bin" --prefix)/bin/zsh"
if [ ! -x "$zsh_bin" ]; then
  echo "zsh не найден: $zsh_bin (установи его через brew bundle)" >&2
  exit 1
fi

# chsh разрешает выбирать только shell из /etc/shells.
if ! grep -Fxq "$zsh_bin" /etc/shells; then
  printf '%s\n' "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
fi

if [ "$SHELL" = "$zsh_bin" ]; then
  echo "Shell уже установлен: $zsh_bin"
else
  chsh -s "$zsh_bin"
  echo "Shell переключён на $zsh_bin. Открой новый терминал и проверь: echo \"\$SHELL\""
fi
