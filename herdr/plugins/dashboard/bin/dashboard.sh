#!/usr/bin/env bash
# Дашборд: задачи спринта из Jira и PR из Bitbucket в fzf.
#
#   dashboard.sh ui jira|prs   — интерактивная панель: задачи или PR
#   dashboard.sh status        — обновить кэш и вывести счётчики (tab_bar_right)
#   dashboard.sh fetch [jira|prs] — только обновить кэш
#
# requires JIRA_API_TOKEN, BITBUCKET_URL, BITBUCKET_TOKEN in ~/.env.d
# Сервер Jira берётся из конфига jira-cli, как в jira-table из zsh/jira.zsh.
# DASHBOARD_JIRA_JQL переопределяет выборку задач спринта,
# DASHBOARD_PREGROOMING_JQL — задач на прегруминг.
# Репозитории для секций «все PR» — в файле repos в config-dir плагина
# (herdr plugin config-dir vpetrukhin.dashboard): строка PROJECT/slug, # — комментарий.
# Имена рабочих репозиториев в публичный репозиторий не кладём.
set -e

# tab_bar_right запускает команду через /bin/sh -lc, там нет brew в PATH
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# сервер herdr мог стартовать без ~/.env.d
if [ -z "${JIRA_API_TOKEN:-}" ] || [ -z "${BITBUCKET_URL:-}" ] || [ -z "${BITBUCKET_TOKEN:-}" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.env.d/10-work.sh"
fi

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-dashboard"
INTERVAL="${DASHBOARD_INTERVAL:-1800}"
JQL="${DASHBOARD_JIRA_JQL:-assignee = currentUser() AND sprint in openSprints() AND statusCategory != Done ORDER BY updated DESC}"
PREGROOMING_JQL="${DASHBOARD_PREGROOMING_JQL:-assignee = currentUser() AND labels = pre_grooming AND statusCategory != Done ORDER BY updated DESC}"
BB_API="$BITBUCKET_URL/rest/api/1.0"
REPOS_FILE="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/vpetrukhin.dashboard}/repos"

jira_server() {
  awk '/^server:/ { print $2 }' "$HOME/.config/.jira/.config.yml"
}

jira_get() {
  curl -sfG -H "Authorization: Bearer $JIRA_API_TOKEN" "$@"
}

bb_get() {
  curl -sfG -H "Authorization: Bearer $BITBUCKET_TOKEN" "$@"
}

# save <файл> — stdin в кэш атомарно, чтобы list не прочитал половину файла
save() {
  cat >"$CACHE/$1.tmp" && jq -e . "$CACHE/$1.tmp" >/dev/null && mv "$CACHE/$1.tmp" "$CACHE/$1"
}

# locked <секция> — fetch_<секция> под блокировкой. В subshell: trap снимает
# блокировку в конце каждой загрузки, даже из loop
locked() (
  set -o pipefail
  mkdir -p "$CACHE"
  lock="$CACHE/lock-$1"
  # status из tab_bar_right и циклы обеих панелей могут грузить одновременно
  find "$lock" -maxdepth 0 -mmin +2 -exec rmdir {} \; 2>/dev/null || true
  if ! mkdir "$lock" 2>/dev/null; then
    # грузит другой процесс: дождаться его и взять его результат
    i=0
    while [ -d "$lock" ] && [ $i -lt 60 ]; do
      sleep 0.5
      i=$((i + 1))
    done
    return 0
  fi
  trap 'rmdir "$lock" 2>/dev/null' EXIT
  "fetch_$1"
)

# jira_search <jql> — задачи с полями для списка и превью
jira_search() {
  jira_get "$(jira_server)/rest/api/2/search" \
    --data-urlencode "jql=$1" \
    --data-urlencode "fields=summary,status,priority,issuetype,description" \
    --data-urlencode "maxResults=100"
}

fetch_jira() {
  local server sprint pregrooming
  server="$(jira_server)"
  sprint="$(jira_search "$JQL")"
  pregrooming="$(jira_search "$PREGROOMING_JQL")"
  jq -n --arg server "$server" --argjson s "$sprint" --argjson p "$pregrooming" \
    '{server: $server, issues: $s.issues, pregrooming: $p.issues}' | save jira.json
}

fetch_prs() {
  # мои открытые PR + статус сборки последнего коммита
  local author builds='{}' c stats
  author="$(bb_get "$BB_API/dashboard/pull-requests" -d state=OPEN -d role=AUTHOR -d limit=100)"
  for c in $(jq -r '.values[].fromRef.latestCommit' <<<"$author"); do
    stats="$(bb_get "$BITBUCKET_URL/rest/build-status/1.0/commits/stats/$c")" || stats='{}'
    builds="$(jq -c --arg c "$c" --argjson s "$stats" '. + {($c): $s}' <<<"$builds")"
  done
  jq --argjson b "$builds" '.values | map(. + {build: $b[.fromRef.latestCommit]})' <<<"$author" | save prs-author.json

  # PR, где я ревьюер и ещё не апрувнул
  bb_get "$BB_API/dashboard/pull-requests" -d state=OPEN -d role=REVIEWER -d participantStatus=UNAPPROVED -d limit=100 |
    jq '.values' | save prs-review.json

  # все открытые PR по репозиториям из конфига; недоступный репозиторий пропускаем
  local line prs
  : >"$CACHE/prs-repos.ndjson"
  if [ -f "$REPOS_FILE" ]; then
    while read -r line || [ -n "$line" ]; do
      line="${line%%#*}"
      line="${line//[[:space:]]/}"
      [ -n "$line" ] || continue
      prs="$(bb_get "$BB_API/projects/${line%%/*}/repos/${line#*/}/pull-requests" -d state=OPEN -d limit=100)" || continue
      jq -c --arg repo "$line" '{repo: $repo, prs: .values}' <<<"$prs" >>"$CACHE/prs-repos.ndjson"
    done <"$REPOS_FILE"
  fi
  jq -s . "$CACHE/prs-repos.ndjson" | save prs-repos.json
}

# fetch [jira|prs] — без аргумента обе секции
fetch() {
  case ${1:-} in
  jira | prs) locked "$1" ;;
  *)
    local rc=0
    locked jira || rc=1
    locked prs || rc=1
    return $rc
    ;;
  esac
}

# Строки для fzf: kind \t id \t url \t текст. Видно только текст (--with-nth=4).
# list jira|prs — ненужные секции читают /dev/null, их ветку jq не вычисляет
list() {
  local section=$1 jira=/dev/null author=/dev/null review=/dev/null repos=/dev/null f
  case $section in
  jira) jira="$CACHE/jira.json" ;;
  prs)
    author="$CACHE/prs-author.json"
    review="$CACHE/prs-review.json"
    repos="$CACHE/prs-repos.json"
    ;;
  esac
  for f in "$jira" "$author" "$review" "$repos"; do
    if [ ! -e "$f" ]; then
      printf 'hdr\t-\t-\t\033[2mзагрузка…\033[0m\n'
      return 0
    fi
  done
  jq -rn --arg section "$section" \
    --slurpfile jira "$jira" \
    --slurpfile author "$author" \
    --slurpfile review "$review" \
    --slurpfile repos "$repos" '
    def c($code): "\u001b[\($code)m\(.)\u001b[0m";
    def pad($w): . + " " * ([$w - length, 0] | max);
    def width(f): (map(f | length) | max) // 0;
    def hdr($title; $n): "hdr\t-\t-\t" + ("── \($title) (\($n)) " | c("1;35"));
    def group($title; $n): "hdr\t-\t-\t" + ("▸ \($title) (\($n))" | c("1;34"));
    def pr_id: "\(.toRef.repository.project.key)/\(.toRef.repository.slug)/\(.id)";
    def pr_name: "\(.toRef.repository.slug)#\(.id)";
    def approvals: "✓\([.reviewers[] | select(.status == "APPROVED")] | length)/\(.reviewers | length)";
    def needs_work: [.reviewers[] | select(.status == "NEEDS_WORK")] | length;

    if $section == "jira" then
    # Спринт: сначала «в работе», потом новые, внутри — по статусу.
    # Прегруминг: без задач, которые уже видны в спринте
    ($jira[0].server) as $server
    | ($jira[0].issues | sort_by(
        (if .fields.status.statusCategory.key == "indeterminate" then 0 else 1 end),
        .fields.status.name)) as $issues
    | ([$issues[].key]) as $sprint_keys
    | (($jira[0].pregrooming // []) | map(select(.key as $k | $sprint_keys | index($k) | not))) as $pre
    | ($issues + $pre | width(.key)) as $wk
    | ($issues + $pre | width(.fields.status.name)) as $ws
    | def row: (if .fields.status.statusCategory.key == "indeterminate" then "33" else "34" end) as $color
        | "jira\t\(.key)\t\($server)/browse/\(.key)\t  "
          + (.key | pad($wk + 2) | c("1"))
          + (.fields.status.name | pad($ws + 2) | c($color))
          + .fields.summary;
      hdr("Спринт"; $issues | length),
      ($issues[] | row),
      hdr("Прегруминг"; $pre | length),
      ($pre[] | row)
    else
    # Мои PR
    (($author[0]) as $prs
    | ($prs | width(pr_name)) as $wn
    | hdr("Мои PR"; $prs | length),
      ($prs[] |
        (.build // {}) as $b
        | (if ($b.failed // 0) > 0 then "✗ build" | c("31")
           elif ($b.inProgress // 0) > 0 then "● build" | c("33")
           elif ($b.successful // 0) > 0 then "✓ build" | c("32")
           else "– build" | c("2") end) as $build
        | (if needs_work > 0 then " ✗\(needs_work)" | c("31") else "" end) as $nw
        | "pr\t\(pr_id)\t\(.links.self[0].href)\t  "
          + (pr_name | pad($wn + 2) | c("1"))
          + (approvals | c("32")) + $nw + "  "
          + ("💬\(.properties.commentCount // 0)" | pad(5)) + "  "
          + $build + "  " + .title)),

    # Ждут моего ревью
    ($review[0]) as $prs
    | ($prs | width(pr_name)) as $wn
    | ($prs | width(.author.user.displayName)) as $wa
    | hdr("Ждут ревью"; $prs | length),
      ($prs[] |
        "pr\t\(pr_id)\t\(.links.self[0].href)\t  "
          + (pr_name | pad($wn + 2) | c("1"))
          + (.author.user.displayName | pad($wa + 2) | c("36"))
          + (approvals | c("32")) + "  " + .title),

    # Все открытые PR по репозиториям из конфига
    ($repos[0]) as $groups
    | ([$groups[].prs[]] | width("#\(.id)")) as $wi
    | ([$groups[].prs[]] | width(.author.user.displayName)) as $wa
    | (if ($groups | length) > 0 then hdr("Все PR"; [$groups[].prs[]] | length) else empty end),
      ($groups[]
        | group(.repo | split("/") | last; .prs | length),
          (.prs[] |
            "pr\t\(pr_id)\t\(.links.self[0].href)\t  "
              + ("#\(.id)" | pad($wi + 2) | c("1"))
              + (.author.user.displayName | pad($wa + 2) | c("36"))
              + (approvals | c("32")) + "  " + .title))
    end
  '
}

preview() {
  local kind=$1 id=$2
  case $kind in
  jira)
    jq -r --arg key "$id" '
      first((.issues + (.pregrooming // []))[] | select(.key == $key))
      | "\u001b[1m\(.key)\u001b[0m  \(.fields.summary)",
        "\(.fields.issuetype.name) · \(.fields.status.name) · \(.fields.priority.name // "—")",
        "",
        (.fields.description // "без описания")' "$CACHE/jira.json"
    ;;
  pr)
    local repos="$CACHE/prs-repos.json"
    [ -f "$repos" ] || repos=/dev/null
    # мой PR есть и в «Мои PR», и в списке репозитория: берём первый, там есть build
    jq -rn --arg id "$id" --slurpfile a "$CACHE/prs-author.json" --slurpfile r "$CACHE/prs-review.json" --slurpfile g "$repos" '
      first(($a[0] + $r[0] + [($g[0] // [])[].prs[]])[]
        | select("\(.toRef.repository.project.key)/\(.toRef.repository.slug)/\(.id)" == $id))
      | "\u001b[1m\(.toRef.repository.slug)#\(.id)\u001b[0m  \(.title)",
        "\(.fromRef.displayId) → \(.toRef.displayId)",
        "автор: \(.author.user.displayName)",
        "merge: \(.properties.mergeResult.outcome // "—") · комментарии: \(.properties.commentCount // 0) · задачи: \(.properties.openTaskCount // 0)",
        (if .build then "build: ✓\(.build.successful) ✗\(.build.failed) ●\(.build.inProgress)" else empty end),
        "",
        "ревьюеры:",
        (.reviewers[] | "  " + (if .status == "APPROVED" then "✓" elif .status == "NEEDS_WORK" then "✗" else "·" end) + " " + .user.displayName),
        "",
        (.description // "без описания")'
    ;;
  esac
}

# split_pr <PROJ/repo/ID> — разложить id PR в переменные proj, repo, pr
split_pr() {
  IFS=/ read -r proj repo pr <<<"$1"
}

# diff PR в hunk: Bitbucket отдаёт пути как src:// и dst://, приводим к a/ и b/
diff_pr() {
  local proj repo pr tmp
  split_pr "$1"
  tmp="$(mktemp -t dashboard-diff).patch"
  bb_get "$BB_API/projects/$proj/repos/$repo/pull-requests/$pr.diff" |
    sed -E 's#^diff --git src://(.*) dst://#diff --git a/\1 b/#; s#^--- src://#--- a/#; s#^\+\+\+ dst://#+++ b/#' >"$tmp"
  hunk patch "$tmp" || true
  rm -f "$tmp"
}

approve_pr() {
  local proj repo pr answer
  split_pr "$1"
  printf 'Апрувнуть %s/%s#%s? [y/N] ' "$proj" "$repo" "$pr"
  read -r answer </dev/tty
  [ "$answer" = y ] || return 0
  curl -sf -X POST -H "Authorization: Bearer $BITBUCKET_TOKEN" \
    "$BB_API/projects/$proj/repos/$repo/pull-requests/$pr/approve" >/dev/null &&
    echo "готово" || echo "не получилось"
  sleep 1
}

pause() {
  printf '\nEnter — назад '
  read -r _ </dev/tty
}

# loop <секция> <порт fzf> — обновлять данные, пока fzf жив
loop() {
  local section=$1 port=$2
  while :; do
    fetch "$section" >/dev/null 2>&1 || true
    curl -sf -X POST "localhost:$port" -d "reload('$SELF' list $section)" >/dev/null || exit 0
    # между обновлениями раз в 10 с проверяем, жив ли fzf, чтобы не висеть
    # полчаса после закрытия вкладки
    local waited=0
    while [ $waited -lt "$INTERVAL" ]; do
      sleep 10
      waited=$((waited + 10))
      curl -sf "localhost:$port" >/dev/null || exit 0
    done
  done
}

# ui jira|prs — у каждой панели свой fzf, свои клавиши и свой цикл обновления
ui() {
  local section=$1 header binds
  local refresh="reload('$SELF' fetch $section >/dev/null 2>&1; '$SELF' list $section)"
  case $section in
  jira)
    header='enter открыть · ctrl-t статус · ctrl-v задача · ctrl-y ключ · ctrl-r обновить'
    binds=(
      --bind="ctrl-t:execute('$SELF' act move {1} {2} {3})+$refresh"
      --bind="ctrl-v:execute('$SELF' act view {1} {2} {3})"
    )
    ;;
  prs)
    header='enter открыть · ctrl-d diff · ctrl-a апрув · ctrl-y ссылка · ctrl-r обновить'
    binds=(
      --bind="ctrl-d:execute('$SELF' act diff {1} {2} {3})"
      --bind="ctrl-a:execute('$SELF' act approve {1} {2} {3})+$refresh"
    )
    ;;
  *)
    echo "usage: $(basename "$0") ui jira|prs" >&2
    exit 1
    ;;
  esac
  exec fzf --ansi --no-sort --layout=reverse --delimiter='\t' --with-nth=4 \
    --listen --prompt="$section> " --info=inline-right --cycle --header="$header" \
    --preview="'$SELF' preview {1} {2}" --preview-window='down,40%,wrap' \
    --bind="start:reload('$SELF' list $section)+execute-silent('$SELF' loop $section \$FZF_PORT >/dev/null 2>&1 &)" \
    --bind="enter:execute-silent('$SELF' act open {1} {2} {3})" \
    --bind="ctrl-y:execute-silent('$SELF' act copy {1} {2} {3})" \
    --bind="ctrl-r:$refresh" \
    "${binds[@]}"
}

# act <действие> <kind> <id> <url> — действие над строкой; заголовки секций игнорируются
act() {
  local action=$1 kind=$2 id=$3 url=$4
  case "$action:$kind" in
  open:jira | open:pr) open "$url" ;;
  copy:jira) printf '%s' "$id" | pbcopy ;;
  copy:pr) printf '%s' "$url" | pbcopy ;;
  diff:pr) diff_pr "$id" ;;
  approve:pr) approve_pr "$id" ;;
  move:jira) jira issue move "$id" || pause ;;
  view:jira) jira issue view --comments 5 "$id" || pause ;;
  esac
}

status() {
  fetch >/dev/null 2>&1 || true
  [ -f "$CACHE/jira.json" ] || exit 0
  local sprint pre mine review failed
  sprint="$(jq '.issues | length' "$CACHE/jira.json")"
  pre="$(jq '[.issues[].key] as $s | [(.pregrooming // [])[] | select(.key as $k | $s | index($k) | not)] | length' "$CACHE/jira.json")"
  mine="$(jq 'length' "$CACHE/prs-author.json")"
  review="$(jq 'length' "$CACHE/prs-review.json")"
  failed="$(jq '[.[] | select((.build.failed // 0) > 0)] | length' "$CACHE/prs-author.json")"
  printf 'sprint %s · pre %s · pr %s%s · review %s\n' "$sprint" "$pre" "$mine" "$([ "$failed" -gt 0 ] && printf ' (✗%s)' "$failed")" "$review"
}

cmd=${1:-}
shift || true
case $cmd in
status) status ;;
ui | fetch | list | preview | loop | act) "$cmd" "$@" ;;
*)
  echo "usage: $(basename "$0") ui jira|prs | status | fetch [jira|prs]" >&2
  exit 1
  ;;
esac
