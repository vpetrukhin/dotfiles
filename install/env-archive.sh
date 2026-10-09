#!/usr/bin/env bash
#
# Перенос ~/.env.d на другую машину зашифрованным архивом (например по AirDrop).
#
# На старой машине:  ./install/env-archive.sh pack
#   шифрует ~/.env.d в ~/Desktop/env.d-<дата>.tgz.enc, пароль спросит openssl
# На новой машине:   ./install/env-archive.sh unpack ~/Downloads/env.d-<дата>.tgz.enc
#   расшифровывает в ~/.env.d. Если ~/.env.d уже есть, он переносится
#   в ~/.env.d.bak-<дата>.
#
# В ~/.env.d токены и пароли, поэтому архив без шифрования не создаётся.
# Пароль передавай не тем же каналом, что и архив.

set -e -o pipefail

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

usage="usage: $0 pack | unpack <archive.tgz.enc>"
stamp=$(date +%Y%m%d-%H%M%S)
env_dir="$HOME/.env.d"
cipher=(-aes-256-cbc -pbkdf2 -iter 200000)

case "$1" in
  pack)
    [ -d "$env_dir" ] || fail "нет $env_dir"
    archive="$HOME/Desktop/env.d-$stamp.tgz.enc"
    # COPYFILE_DISABLE — без ._* файлов с macOS-атрибутами
    COPYFILE_DISABLE=1 tar czf - -C "$HOME" .env.d \
      | openssl enc "${cipher[@]}" -salt -out "$archive" \
      || { rm -f "$archive"; fail "не удалось зашифровать"; }
    success "$archive"
    info "передай по AirDrop, на новой машине: ./install/env-archive.sh unpack <путь>"
    info "после передачи удали архив на обеих машинах"
    ;;
  unpack)
    archive=$2
    [ -f "$archive" ] || fail "$usage"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    # сначала расшифровка во временный каталог: при неверном пароле
    # текущий ~/.env.d остаётся на месте
    openssl enc -d "${cipher[@]}" -in "$archive" | tar xzf - -C "$tmp" \
      || fail "не удалось расшифровать — неверный пароль?"
    [ -d "$tmp/.env.d" ] || fail "в архиве нет .env.d"
    if [ -e "$env_dir" ]; then
      mv "$env_dir" "$env_dir.bak-$stamp"
      info "старый ~/.env.d -> ~/.env.d.bak-$stamp"
    fi
    mv "$tmp/.env.d" "$env_dir"
    chmod 700 "$env_dir"
    chmod 600 "$env_dir"/*
    success "$env_dir"
    info "дальше: открой новый шелл, потом удали $archive"
    ;;
  *)
    fail "$usage"
    ;;
esac
echo ''
