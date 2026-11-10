#!/usr/bin/env bash
# Открывает дашборд: новая вкладка с задачами слева и PR справа.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"

left="$("$HERDR" plugin pane open --plugin vpetrukhin.dashboard --entrypoint jira \
  --placement tab --cwd "$HOME" --focus |
  jq -r '[.. | objects | .pane_id? // empty][0]')"

"$HERDR" plugin pane open --plugin vpetrukhin.dashboard --entrypoint prs \
  --placement split --target-pane "$left" --direction right --cwd "$HOME" --no-focus >/dev/null
