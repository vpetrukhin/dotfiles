#!/usr/bin/env bash
# Диагностика окружения dotfiles: симлинки из links.prop, доступность команд,
# фактические пути Node/CLI. Строго read-only: ничего не создаёт, не исправляет,
# не запускает серверы и не печатает содержимое конфигов и ~/.env.d.
# private/ не проверяется: он не версионируется и может содержать рабочее.

set -e
set -o pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

errors=0
warnings=0

section() { printf '\n%s\n' "$*"; }
ok() { printf '  [ok]   %s\n' "$*"; }
warn() {
  printf '  [warn] %s\n' "$*"
  warnings=$((warnings + 1))
}
fail() {
  printf '  [fail] %s\n' "$*"
  errors=$((errors + 1))
}

# пути печатаем относительно $HOME, чтобы не сыпать длинными абсолютными путями
short() {
  local p=$1
  case $p in
    "$HOME") printf '~' ;;
    "$HOME"/*) printf '~%s' "${p#"$HOME"}" ;;
    *) printf '%s' "$p" ;;
  esac
}

# Подстановка $DOTFILES/$HOME без eval: только эти две переменные и ~/ в начале.
expand_path() {
  local p=$1
  p=${p//'${DOTFILES}'/$ROOT}
  p=${p//'$DOTFILES'/$ROOT}
  p=${p//'${HOME}'/$HOME}
  p=${p//'$HOME'/$HOME}
  case $p in
    '~/'*) p="$HOME/${p#'~/'}" ;;
  esac
  printf '%s' "$p"
}

# завершающий / не меняет смысла пути: nvim/links.prop намеренно пишет source со /
normalize() {
  local p=$1
  while [ "${p%/}" != "$p" ]; do
    p=${p%/}
  done
  printf '%s' "$p"
}

check_link() {
  local src_raw=$1 dst_raw=$2
  local src dst target

  src=$(normalize "$(expand_path "$src_raw")")
  # завершающий / в цели ломает -L на macOS, поэтому нормализуем и её
  dst=$(normalize "$(expand_path "$dst_raw")")

  if [ ! -e "$src" ]; then
    fail "источник $(short "$src") отсутствует в репозитории"
    return
  fi

  if [ -L "$dst" ]; then
    target=$(readlink "$dst")
    case $target in
      /*) : ;;
      *) target="$(dirname "$dst")/$target" ;;
    esac
    if [ ! -e "$dst" ]; then
      fail "симлинк $(short "$dst") битый: $(short "$target") не существует"
    elif [ "$(normalize "$target")" = "$src" ]; then
      if [ "$target" = "$src" ]; then
        ok "$(short "$dst") -> $(short "$target")"
      else
        # например nvim: /path/nvim/ против /path/nvim — для bootstrap это разные строки
        ok "$(short "$dst") -> $(short "$target") (совпадает без учёта завершающего /)"
      fi
    else
      fail "симлинк $(short "$dst") ведёт на $(short "$target"), ожидался $(short "$src")"
    fi
  elif [ -e "$dst" ]; then
    fail "$(short "$dst") существует, но это не симлинк (обычный файл или каталог)"
  else
    fail "$(short "$dst") отсутствует (ожидался симлинк на $(short "$src"))"
  fi
}

section "симлинки по links.prop"
# private/ исключён: его цели — рабочие конфиги, а не предмет публичной диагностики.
while IFS= read -r prop; do
  rel=${prop#"$ROOT"/}
  printf '\n  %s\n' "$rel"
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in
      '' | '#'*) continue ;;
    esac
    case $line in
      *=*) : ;;
      *)
        warn "строка без '=' в $rel пропущена"
        continue
        ;;
    esac
    check_link "${line%%=*}" "${line#*=}"
  done <"$prop"
done < <(find "$ROOT" -maxdepth 2 -name links.prop -not -path '*/.git/*' -not -path "$ROOT/private/*" | sort)

show_path() {
  local c=$1 p
  p=$(type -P "$c" 2>/dev/null || true)
  [ -n "$p" ] || return 0
  printf '  %-30s %s\n' "$c" "$(short "$p")"
}

section "команды: обязательные"
for c in git mise jq zsh node npm; do
  if type -P "$c" >/dev/null 2>&1; then
    ok "$c"
  else
    fail "$c не найден в PATH"
  fi
done

section "команды: необязательные (warn = не регресс)"
# Отсутствие чего-то из списка не ломает конфиги: это либо отдельно ставимый
# инструмент, либо LSP под конкретный язык.
for c in nvim herdr pi tsc typescript-language-server \
  vscode-html-language-server vscode-css-language-server vscode-json-language-server \
  lua-language-server tailwindcss-language-server vue-language-server stylua brew; do
  if type -P "$c" >/dev/null 2>&1; then
    ok "$c"
  else
    warn "$c не найден в PATH (необязательный)"
  fi
done

section "фактические пути"
for c in mise node npm pi tsc typescript-language-server; do
  show_path "$c"
done

# node/npm по задумке идут из mise, а не из brew/nvm/системы.
for c in node npm; do
  p=$(type -P "$c" 2>/dev/null || true)
  if [ -n "$p" ]; then
    case $p in
      *'/mise/installs/'*) : ;;
      *) warn "$c взят не из mise ($(short "$p")): activate не загружен или PATH перекрыт" ;;
    esac
  fi
done

p=$(type -P pi 2>/dev/null || true)
if [ -n "$p" ]; then
  case $p in
    *'/mise/installs/'*) : ;;
    *) warn "pi взят не из mise ($(short "$p"))" ;;
  esac
fi
# У pi есть ещё self-update установка (~/.pi/agent/bin/pi). Две копии — не ошибка,
# но полезно видеть, расходятся ли они; версии не запускаем, только наличие.
managed_pi="$HOME/.pi/agent/bin/pi"
if [ -x "$managed_pi" ] && [ -n "$p" ] && [ "$p" != "$managed_pi" ]; then
  printf '  %s\n' "info: помимо PATH есть managed-установка $(short "$managed_pi")"
fi

printf '\nИтог: ошибок %d, предупреждений %d\n' "$errors" "$warnings"
if [ "$errors" -gt 0 ]; then
  echo 'Ошибки — расхождения симлинков или отсутствие обязательных команд; устраняются вручную (bootstrap/установка), doctor ничего не меняет.'
  exit 1
fi
echo 'Критичных расхождений нет; warn — необязательные команды и известные особенности.'
