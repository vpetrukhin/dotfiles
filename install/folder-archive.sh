#!/usr/bin/env bash
# Упаковать каталог в .tgz или распаковать его в каталог назначения.
# Архив не шифруется: для секретов используй install/env-archive.sh.

set -e -o pipefail

usage() {
  echo "Использование: $0 pack <каталог> <архив.tgz> | unpack <архив.tgz> <каталог назначения>" >&2
  exit 1
}

[ "$#" -eq 3 ] || usage

case "$1" in
  pack)
    source_dir=${2%/}
    archive=$3
    [ -d "$source_dir" ] && [ ! -L "$source_dir" ] || { echo "Нет каталога: $2" >&2; exit 1; }
    [ ! -e "$archive" ] && [ ! -L "$archive" ] || { echo "Архив уже существует: $archive" >&2; exit 1; }
    parent=$(cd "$(dirname "$source_dir")" && pwd -P)
    name=$(basename "$source_dir")
    # Не оставляем частичный архив при ошибке tar.
    tmp=$(mktemp "${archive}.tmp.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    COPYFILE_DISABLE=1 tar czf "$tmp" -C "$parent" "$name"
    mv "$tmp" "$archive"
    trap - EXIT
    echo "Упаковано: $archive"
    ;;
  unpack)
    archive=$2
    destination=$3
    [ -f "$archive" ] || { echo "Нет архива: $archive" >&2; exit 1; }
    [ -d "$destination" ] || { echo "Нет каталога назначения: $destination" >&2; exit 1; }
    # Принимаем только архив одного каталога, без абсолютных путей и выхода через ..
    name=
    while IFS= read -r entry; do
      entry=${entry#./}
      case "$entry" in
        ''|/*|..|../*|*/../*|*/..|.) echo "Небезопасный путь в архиве: $entry" >&2; exit 1 ;;
      esac
      root=${entry%%/*}
      if [ -z "$name" ]; then name=$root; fi
      [ "$root" = "$name" ] || { echo 'В архиве больше одного каталога' >&2; exit 1; }
    done < <(tar tzf "$archive")
    [ -n "$name" ] || { echo 'Пустой архив' >&2; exit 1; }
    [ ! -e "$destination/$name" ] && [ ! -L "$destination/$name" ] || {
      echo "Каталог уже существует: $destination/$name" >&2; exit 1;
    }
    tmp=$(mktemp -d "$destination/.folder-archive.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT
    tar xzf "$archive" -C "$tmp"
    [ -d "$tmp/$name" ] && [ ! -L "$tmp/$name" ] || { echo 'В архиве нет каталога' >&2; exit 1; }
    mv "$tmp/$name" "$destination/$name"
    rmdir "$tmp"
    trap - EXIT
    echo "Распаковано: $destination/$name"
    ;;
  *) usage ;;
esac
