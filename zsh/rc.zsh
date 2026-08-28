source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

export ZSH="$HOME/.oh-my-zsh"
export EDITOR=nvim

# Themes
ZSH_THEME=frisk
# ZSH_THEME="robbyrussell"

# секреты и машинозависимые значения — слоями в ~/.env.d (00-core, 10-work, 20-personal)
for env_file in $HOME/.env.d/*.sh(N); do
    source_if_exists $env_file
done
unset env_file

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile

source_if_exists $DOTFILES/zsh/aliases.zsh

source $ZSH/oh-my-zsh.sh

export PATH=/opt/homebrew/bin:$PATH
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:${PATH}

# nvm — строго после export PATH, иначе node из nvm перекроется системным
source_if_exists $DOTFILES/nvm/init.zsh

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/vasyapetrukhin/.lmstudio/bin"

# The next line updates PATH for CLI.
if [ -f '/Users/vasyapetrukhin/yandex-cloud/path.bash.inc' ]; then source '/Users/vasyapetrukhin/yandex-cloud/path.bash.inc'; fi

# The next line enables shell command completion for yc.
if [ -f '/Users/vasyapetrukhin/yandex-cloud/completion.zsh.inc' ]; then source '/Users/vasyapetrukhin/yandex-cloud/completion.zsh.inc'; fi
