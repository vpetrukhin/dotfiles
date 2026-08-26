# aliases
alias tl="tmux ls"
alias ta="tmux attach -t"
alias eddot="nvim ~/dotfiles"
alias edenv="nvim ~/.env.sh"

alias reloaddot="~/dotfiles/install/bootstrap.sh"

# requires WORK_EMAIL in ~/.env.sh
alias copyWorkPass='keepassxc-cli clip ~/workPass.kdbx "$WORK_EMAIL"'

# jira cli
alias jira-my='jira issue list -a $(jira me)'
alias jira-sprint='jira issue list --jql "project in (EXCHANGE, MG) AND assignee = currentUser() AND sprint in openSprints() AND status != Closed" --order-by priority'

# orangepi
# requires ORANGEPI_USER and ORANGEPI_HOST in ~/.env.sh
alias my-orangepi='ssh -i ./orangepi "$ORANGEPI_USER@$ORANGEPI_HOST"'

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

