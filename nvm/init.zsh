# Загрузка nvm и автопереключение версии по .nvmrc.
#
# ВАЖНО: этот файл нужно подключать ПОСЛЕ всех `export PATH=...` в rc.zsh.
# При загрузке nvm.sh сам активирует алиас default и кладёт свой bin в начало
# PATH; если после этого дописать PATH руками, node из nvm перекроется
# системным (`nvm current` покажет `system`).

export NVM_DIR="$HOME/.nvm"

# сам nvm.sh может быть из git-клона в $NVM_DIR или из brew — берём первый живой
for nvm_sh in "$NVM_DIR/nvm.sh" /opt/homebrew/opt/nvm/nvm.sh /usr/local/opt/nvm/nvm.sh; do
    if [ -s "$nvm_sh" ]; then
        source "$nvm_sh"
        break
    fi
done
unset nvm_sh

for nvm_completion in "$NVM_DIR/bash_completion" /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm; do
    if [ -s "$nvm_completion" ]; then
        source "$nvm_completion"
        break
    fi
done
unset nvm_completion

# при cd в директорию с .nvmrc переключаемся на её версию,
# при выходе — обратно на default
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
