# aliases
alias tl="tmux ls"
alias ta="tmux attach -t"
alias eddot="nvim ~/dotfiles"
alias edenv="nvim ~/.env.sh"

alias reloaddot="~/dotfiles/install/bootstrap.sh"

# TODO: move email to env to env
alias copyWorkPass="keepassxc-cli clip ~/workPass.kdbx v.petrukhin@banki.ru"

# jira cli
alias jira-my='jira issue list -a $(jira me)'
alias jira-sprint='jira issue list --jql "project in (EXCHANGE, MG) AND assignee = currentUser() AND sprint in openSprints() AND status != Closed" --order-by priority'

# orangepi
# TODO: move username and ip to env
alias my-orangepi="ssh -i ./orangepi 'carav@192.168.1.150'"

# utils
function convert-to-webp() {
  for file in ./convert/*.png; do
    cwebp -m 6 -q 100 -mt -progress "$file" -o "${file%.png}.webp"
  done
}

# dev-stand: локальные стенды nodejs-проектов (порт → чекаут → ветка)
alias ds-ls='node ~/.claude/skills/dev-stand/scripts/dev-stand.js ls'
alias ds-who='node ~/.claude/skills/dev-stand/scripts/dev-stand.js who'
alias ds-up='node ~/.claude/skills/dev-stand/scripts/dev-stand.js up'

