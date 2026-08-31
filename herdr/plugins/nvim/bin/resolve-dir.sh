#!/usr/bin/env bash
# Определяет cwd для новой вкладки: каталог активной панели, иначе каталог воркспейса.
set -euo pipefail

# 1. явный аргумент
if [ -n "${1:-}" ]; then
  printf '%s\n' "$1"
  exit 0
fi

# 2. контекст плагина от herdr
if [ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ] && command -v jq >/dev/null 2>&1; then
  DIR="$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" \
    | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null || true)"
  if [ -n "$DIR" ]; then
    printf '%s\n' "$DIR"
    exit 0
  fi
fi

# 3. запасной вариант
pwd
