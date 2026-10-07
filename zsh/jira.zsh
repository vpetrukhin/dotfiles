# jira-cli: https://github.com/ankitpokhrel/jira-cli
alias jira-view='jira issue view --comments 5'
alias jv='jira-view'
# jira-open — открыть задачу в браузере
alias jira-open='jira open'
alias jo='jira-open'
# jira-move — перевести задачу в статус: jira-move EXCHANGE-123 "In Progress"; без статуса — интерактивный выбор
alias jira-move='jira issue move'
alias jm='jira-move'

# _jira_clip_key — номер задачи из буфера обмена.
# В буфере может быть ключ или ссылка на задачу (…/browse/EXCHANGE-123)
function _jira_clip_key() {
  local clip
  clip=$(pbpaste)
  if [[ ${clip:u} =~ '(^|[^A-Z0-9])([A-Z]+-[0-9]+)([^A-Z0-9]|$)' ]]; then
    print -r -- $match[2]
  else
    print -u2 "$1: в буфере нет номера задачи"
    return 1
  fi
}

# jira-move-clip — перевести в статус задачу из буфера: jira-move-clip "In Progress"
function jira-move-clip() {
  local key
  key=$(_jira_clip_key jira-move-clip) || return 1
  jira issue move "$key" "$@"
}
alias jmc='jira-move-clip'

# jira-open-clip — открыть в браузере задачу из буфера
function jira-open-clip() {
  local key
  key=$(_jira_clip_key jira-open-clip) || return 1
  jira open "$key" "$@"
}
alias joc='jira-open-clip'
alias jira-my='jira issue list -a $(jira me)'
alias jira-sprint='jira issue list --jql "project in (EXCHANGE, MG) AND assignee = currentUser() AND sprint in openSprints() AND status not in (Closed, Resolved)" --order-by priority'
alias jira-front='jira issue list --jql "project in (EXCHANGE, MG) AND labels = front AND sprint in openSprints() AND status not in (Closed, Resolved)" --order-by priority'

# _jira_branch_key — номер задачи из имени текущей git-ветки (feature/EXCHANGE-123-foo)
function _jira_branch_key() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    print -u2 "$1: не git-репозиторий"
    return 1
  }
  if [[ ${branch:u} =~ '(^|[^A-Z0-9])([A-Z]+-[0-9]+)([^A-Z0-9]|$)' ]]; then
    print -r -- $match[2]
  else
    print -u2 "$1: в имени ветки '$branch' нет номера задачи"
    return 1
  fi
}

# jira-current — задача по текущей ветке
function jira-current() {
  local key
  key=$(_jira_branch_key jira-current) || return 1
  jira issue view --comments 5 "$key" "$@"
}

# jira-move-branch — перевести в статус задачу по текущей ветке: jira-move-branch "In Progress"
function jira-move-branch() {
  local key
  key=$(_jira_branch_key jira-move-branch) || return 1
  jira issue move "$key" "$@"
}
alias jmb='jira-move-branch'

# jira-open-branch — открыть в браузере задачу по текущей ветке
function jira-open-branch() {
  local key
  key=$(_jira_branch_key jira-open-branch) || return 1
  jira open "$key" "$@"
}
alias job='jira-open-branch'

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
