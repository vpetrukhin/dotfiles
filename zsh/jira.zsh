# jira-cli: https://github.com/ankitpokhrel/jira-cli
alias jira-view='jira issue view --comments 5'
alias jira-my='jira issue list -a $(jira me)'
alias jira-sprint='jira issue list --jql "project in (EXCHANGE, MG) AND assignee = currentUser() AND sprint in openSprints() AND status not in (Closed, Resolved)" --order-by priority'
alias jira-front='jira issue list --jql "project in (EXCHANGE, MG) AND labels = front AND sprint in openSprints() AND status not in (Closed, Resolved)" --order-by priority'

# jira-current — задача по номеру тикета в имени текущей git-ветки (feature/EXCHANGE-123-foo)
function jira-current() {
  local branch key
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    print -u2 "jira-current: не git-репозиторий"
    return 1
  }
  if [[ ${branch:u} =~ '(^|[^A-Z0-9])([A-Z]+-[0-9]+)([^A-Z0-9]|$)' ]]; then
    key=$match[2]
  fi
  if [[ -z $key ]]; then
    print -u2 "jira-current: в имени ветки '$branch' нет номера задачи"
    return 1
  fi
  jira issue view --comments 5 "$key" "$@"
}
