#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES=$(pwd -P)

# ln -s parent child

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

link_file () {
  local src=$1 dst=$2

  local overwrite=
  local backup=
  local skip=
  local action=

  if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      # ignoring exit 1 from readlink in case where file already exists
      # shellcheck disable=SC2155
      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action  < /dev/tty

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

prop () {
   PROP_KEY=$1
   PROP_FILE=$2
   PROP_VALUE=$(eval echo "$(cat $PROP_FILE | grep "$PROP_KEY" | cut -d'=' -f2)")
   echo $PROP_VALUE
}

install_dotfiles () {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  find -H "$DOTFILES" -maxdepth 2 -name 'links.prop' -not -path '*.git*' | while read linkfile
  do
    cat "$linkfile" | while read line
    do
        local src dst dir
        src=$(eval echo "$line" | cut -d '=' -f 1)
        dst=$(eval echo "$line" | cut -d '=' -f 2)
        dir=$(dirname $dst)

        mkdir -p "$dir"
        link_file "$src" "$dst"
    done
  done
}

create_env_files () {
    mkdir -p "$HOME/.env.d"

    # 00-core грузится первым, из него берётся $DOTFILES
    if test -f "$HOME/.env.d/00-core.sh"; then
        success "$HOME/.env.d/00-core.sh already exists, skipping"
    else
        echo "# core: нужно до aliases.zsh" > "$HOME/.env.d/00-core.sh"
        echo "export DOTFILES=$DOTFILES" >> "$HOME/.env.d/00-core.sh"
        success 'created ~/.env.d/00-core.sh'
    fi

    # заготовки под остальные слои
    for layer in 10-work 20-personal; do
        if test -f "$HOME/.env.d/$layer.sh"; then
            success "$HOME/.env.d/$layer.sh already exists, skipping"
        else
            echo "# $layer" > "$HOME/.env.d/$layer.sh"
            success "created ~/.env.d/$layer.sh"
        fi
    done

    chmod 600 "$HOME"/.env.d/*.sh

    if test -f "$HOME/.env.sh"; then
        user "~/.env.sh больше не подключается — перенеси содержимое в ~/.env.d/ и удали его"
    fi
}

create_nvm_derectory () {
    if test -d "$HOME/.nvm"; then
        success "Directory .nvm already exists, skipping"
    else
        mkdir ~/.nvm 
        success 'created ~/.nvm'
    fi
}

install_dotfiles
create_env_files
create_nvm_derectory

echo ''
echo ''
success 'All installed!'
