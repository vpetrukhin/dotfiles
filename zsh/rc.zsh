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

# рабочий email для git в ~/Development/bankiru (см. includeIf в git/config).
# git не умеет читать env, поэтому кладём $WORK_EMAIL в файл; пишем только при изменении
# requires WORK_EMAIL in ~/.env.d
if [[ -n $WORK_EMAIL ]]; then
    git_work_config=$HOME/.config/git/work
    git_work_content=$'[user]\n\temail = '$WORK_EMAIL
    if [[ ! -r $git_work_config || "$(<$git_work_config)" != "$git_work_content" ]]; then
        print -r -- "$git_work_content" >| $git_work_config
    fi
    unset git_work_config git_work_content
fi

# login-шелл уже прочитал ~/.zprofile сам; повторный source задваивает PATH
[[ -o login ]] || source ~/.zprofile

# Дополнительные автодополнения Homebrew должны попасть в fpath до compinit из oh-my-zsh.
fpath=(/opt/homebrew/share/zsh-completions $fpath)
source $ZSH/oh-my-zsh.sh

# строго после oh-my-zsh: он определяет свои ls/ll/la и затирает наши
source_if_exists $DOTFILES/zsh/aliases.zsh
source_if_exists $DOTFILES/zsh/jira.zsh

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

# herdr-automatic-rename: live tab naming hook
# (N) — nullglob: без установленного плагина glob схлопывается в пустоту, а не ругается
for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
    source $_f; break
done
unset _f

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/vasyapetrukhin/.lmstudio/bin"

# The next line updates PATH for CLI.
if [ -f '/Users/vasyapetrukhin/yandex-cloud/path.bash.inc' ]; then source '/Users/vasyapetrukhin/yandex-cloud/path.bash.inc'; fi

# The next line enables shell command completion for yc.
if [ -f '/Users/vasyapetrukhin/yandex-cloud/completion.zsh.inc' ]; then source '/Users/vasyapetrukhin/yandex-cloud/completion.zsh.inc'; fi
