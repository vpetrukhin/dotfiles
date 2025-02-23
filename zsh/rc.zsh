source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && \. "/usr/local/opt/nvm/etc/bash_completion"

export ZSH="$HOME/.oh-my-zsh"
export EDITOR=nvim

# Themes
ZSH_THEME=frisk
# ZSH_THEME="robbyrussell"

source_if_exists $HOME/.env.sh

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile

source_if_exists $DOTFILES/zsh/aliases.zsh

source $ZSH/oh-my-zsh.sh
source ~/.nvm/nvm.sh

export PATH=/opt/homebrew/bin:$PATH
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:${PATH}
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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
