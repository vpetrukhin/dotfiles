# AGENTS.md

Инструкции для ИИ-агентов, работающих в этом репозитории.

## Что это

Личные dotfiles для рабочего macOS-сетапа. Кода нет — только конфиги
(zsh, neovim, tmux, alacritty, yazi, git) и bash-скрипты установки.
Сборки, тестов и CI нет.

## Структура

Каждая директория верхнего уровня — один инструмент:

| Директория     | Что настраивает                                  |
| -------------- | ------------------------------------------------ |
| `zsh/`         | `rc.zsh` → `~/.zshrc`, `aliases.zsh` (алиасы и функции) |
| `nvim/`        | конфиг на базе LazyVim-starter (Lua)             |
| `nvim_minimal/`| минимальный отдельный конфиг для быстрых правок  |
| `tmux/`        | `tmux.conf`                                      |
| `alacritty/`   | `alacritty.toml`                                 |
| `yazi/`        | `yazi.toml`                                      |
| `git/`         | глобальный `~/.gitignore`                        |
| `install/`     | bootstrap + установка brew-пакетов               |

## Механизм установки (главное, что нужно понять)

`install/bootstrap.sh` не хардкодит пути. Он ищет файлы `links.prop`
(`find -maxdepth 2`) и для каждой строки создаёт симлинк:

```
$DOTFILES/<путь-в-репо>=$HOME/<путь-назначения>
```

Слева источник в репозитории, справа — цель в `$HOME`. Переменные
раскрываются через `eval`, поэтому `$DOTFILES` и `$HOME` работают.
`$DOTFILES` живёт в `~/.env.sh`, который bootstrap создаёт при первом запуске.

Скрипт идемпотентен: если симлинк уже указывает куда надо — шаг пропускается,
иначе он **интерактивно** спрашивает skip/overwrite/backup (читает из `/dev/tty`).
Не запускай его в неинтерактивном режиме, не предупредив пользователя.

Запуск: `./install/bootstrap.sh` (или алиас `reloaddot`).

### Добавление нового конфига

1. Создай директорию с файлом конфига.
2. Добавь рядом `links.prop` со строкой `src=dst` (глубина не больше 2 —
   иначе `find` его не увидит).
3. Прогони `./install/bootstrap.sh`.

## Соглашения

- **Секреты и машинозависимые значения — только в `~/.env.sh`**, он вне репозитория.
  В `aliases.zsh` уже так сделано для `WORK_EMAIL`, `ORANGEPI_USER`, `ORANGEPI_HOST`.
  Рядом с использованием оставляй комментарий `# requires XXX in ~/.env.sh`.
  Никогда не коммить токены, пароли, внутренние хосты и рабочие адреса.
- **Lua**: форматирование по `nvim/stylua.toml` — 2 пробела, ширина 120.
- **Shell**: bash с `#!/usr/bin/env bash`, `set -e`, функции-хелперы
  `info/user/success/fail` для вывода в `bootstrap.sh`.
- **Комментарии** пишем по-русски, как в существующих файлах.
- Коммиты — короткие в императиве, строчными: `add lazyvim`, `remove avante config`,
  `move work email and orangepi host to env`.

## Neovim

Конфиг — LazyVim starter, поэтому:

- Правки идут в `nvim/lua/config/*.lua` (options, keymaps, autocmds) и
  в новые файлы `nvim/lua/plugins/*.lua` — они подхватываются lazy.nvim автоматически.
- `nvim/lua/plugins/example.lua` — заглушка апстрима с `if true then return {} end`.
  Это не мёртвый код, не удалять и не «исправлять».
- `nvim/README.md` и `nvim/LICENSE` — из апстрим-стартера, не трогать.
- Список LazyVim-extras живёт в `nvim/lazyvim.json`; редактировать его лучше
  через `:LazyExtras`, а не руками.
- `nvim/lazy-lock.json` в `.gitignore` — версии плагинов намеренно не фиксируются.

## Известные особенности (не «баги», не чинить без просьбы)

- У `nvim/` **нет** `links.prop`: `~/.config/nvim` был слинкован вручную,
  bootstrap его не обслуживает.
- `zsh/rc.zsh` дописывает строку `brew shellenv` в `~/.zprofile` при каждом
  старте шелла, поэтому файл со временем разрастается.
- В `zsh/rc.zsh` есть абсолютные пути `/Users/vasyapetrukhin/...` (yandex-cloud, LM Studio).

## Проверка изменений

Автотестов нет, проверяем руками:

- shell: `bash -n install/bootstrap.sh`, `zsh -n zsh/rc.zsh zsh/aliases.zsh`
- lua: `stylua --check nvim/` (если stylua установлен)
- tmux: `tmux source-file tmux/tmux.conf`
- симлинки: `ls -l ~/.zshrc ~/.tmux.conf ~/.config/nvim`

Правки в `~/.zshrc` подхватываются в новом шелле или после `source ~/.zshrc`.
