#!/usr/bin/env bash
#
# Перенос private/ на другую машину архивом (например по AirDrop).
#
# На старой машине:  ./install/private-archive.sh pack
#   кладёт private/ в ~/Desktop/private-<дата>.tgz
# На новой машине:   ./install/private-archive.sh unpack ~/Downloads/private-<дата>.tgz
#   распаковывает в $DOTFILES/private. Если private/ уже есть, он переносится
#   в ~/private.bak-<дата> — вне репозитория, иначе бэкап не попадёт под
#   .gitignore и может уехать в публичный git.
#
# tar сохраняет права, поэтому scripts/*.sh остаются исполняемыми.

cd "$(dirname "$0")/.."
DOTFILES=$(pwd -P)

set -e

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit 1
}

usage="usage: $0 pack | unpack <archive.tgz>"
stamp=$(date +%Y%m%d-%H%M%S)

case "$1" in
  pack)
    [ -d "$DOTFILES/private" ] || fail "нет $DOTFILES/private"
    archive="$HOME/Desktop/private-$stamp.tgz"
    # COPYFILE_DISABLE — без ._* файлов с macOS-атрибутами
    COPYFILE_DISABLE=1 tar czf "$archive" -C "$DOTFILES" private
    success "$archive"
    info "передай по AirDrop, на новой машине: ./install/private-archive.sh unpack <путь>"
    info "после передачи удали архив: внутри рабочие хосты и ssh config"
    ;;
  unpack)
    archive=$2
    [ -f "$archive" ] || fail "$usage"
    tar tzf "$archive" | grep -qv '^private/' && fail "в архиве есть файлы вне private/"
    if [ -e "$DOTFILES/private" ]; then
      mv "$DOTFILES/private" "$HOME/private.bak-$stamp"
      info "старый private/ -> ~/private.bak-$stamp"
    fi
    tar xzf "$archive" -C "$DOTFILES"
    success "private/ в $DOTFILES"
    info "дальше: ./install/bootstrap.sh, потом удали $archive"
    ;;
  *)
    fail "$usage"
    ;;
esac
echo ''
