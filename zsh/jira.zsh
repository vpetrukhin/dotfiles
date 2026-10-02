# jira-cli: https://github.com/ankitpokhrel/jira-cli
alias jira-view='jira issue view --comments 5'
alias jv='jira-view'
# jira-open — открыть задачу в браузере
alias jira-open='jira open'
alias jo='jira-open'
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

# jira-table — таблица KEY / SPRINT / STATUS / SUMMARY по JQL.
# jira-cli колонку спринта не умеет, поэтому напрямую через REST API.
# Сервер берётся из конфига jira-cli, токен — JIRA_API_TOKEN (requires JIRA_API_TOKEN in ~/.env.d)
function jira-table() {
  local jql=$1 server
  server=$(awk '/^server:/ { print $2 }' ~/.config/.jira/.config.yml 2>/dev/null)
  if [[ -z $server || -z $JIRA_API_TOKEN ]]; then
    print -u2 "jira-table: нет server в конфиге jira-cli или JIRA_API_TOKEN"
    return 1
  fi
  # customfield_10330 — Sprint; старый Jira Server отдаёт его строкой вида "...Sprint@1a[id=1,...,name=MG 150,...]"
  curl -sfG -H "Authorization: Bearer $JIRA_API_TOKEN" "$server/rest/api/2/search" \
    --data-urlencode "jql=$jql" \
    --data-urlencode "fields=summary,status,customfield_10330" \
    --data-urlencode "maxResults=200" |
    jq -r --arg server "$server" '
      def pad($w): . + " " * ($w - length);
      # OSC 8: кликабельная ссылка в терминале; паддинг снаружи, чтобы escape-коды не ломали выравнивание
      def link($url; $text): "\u001b]8;;\($url)\u001b\\\($text)\u001b]8;;\u001b\\";
      [.issues[] | {
        key,
        sprint: ((.fields.customfield_10330 // []) | last // "" | capture("name=(?<n>[^,]*)").n // "—"),
        status: .fields.status.name,
        summary: .fields.summary
      }] as $rows
      | ($rows | map(.key | length) | max) as $wk
      | ($rows | map(.sprint | length) | max) as $ws
      | ($rows | map(.status | length) | max) as $wst
      | $rows[]
      | link("\($server)/browse/\(.key)"; .key) + " " * ($wk - (.key | length) + 2)
        + (.sprint | pad($ws + 2)) + (.status | pad($wst + 2)) + .summary'
}

_JIRA_PREGROOM_JQL='project in (EXCHANGE, MG) AND labels = pre_grooming AND status not in (Closed, Resolved)'
alias jira-pregroom='jira-table "$_JIRA_PREGROOM_JQL ORDER BY priority DESC"'
alias jira-pregroom-my='jira-table "$_JIRA_PREGROOM_JQL AND assignee = currentUser() ORDER BY priority DESC"'
