# AGENTS.md

Инструкции для ИИ-агентов, работающих в этом репозитории.

## Что это

Личные dotfiles для рабочего macOS-сетапа. Кода нет — только конфиги
(zsh, neovim, tmux, alacritty, yazi, herdr, git) и bash-скрипты установки.
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
| `nvm/`         | дефолтная версия node, `default-packages`, `init.zsh` |
| `herdr/`       | `config.toml` (терминальный мультиплексор для агентов) |
| `git/`         | глобальный gitignore → `~/.config/git/ignore`    |
| `hunk/`        | `config.toml` (терминальный просмотрщик диффов)   |
| `claude/`      | `settings.json` и свои скиллы Claude Code         |
| `private/`     | конфиги с рабочими внутренностями, **в gitignore** |
| `install/`     | bootstrap + `Brewfile` с пакетами                |

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

### private/

Репозиторий **публичный**, поэтому конфиги с рабочими внутренностями (внутренние
хосты, ключи проектов Jira, имена рабочих репозиториев, пути к личному волту)
лежат в `private/` — он целиком в `.gitignore`.

Устроен как остальной репозиторий: `private/links.prop` (глубина 2, bootstrap
его находит) и дальше своя структура по инструментам — `private/claude/skills/…`,
`private/claude/agents/…`. Симлинки в `$HOME` bootstrap ставит наравне с
публичными, разницы в работе нет.

Цена — **бэкапа нет**: git этих файлов не видит. Если содержимое нужно
сохранять, заводи под него отдельный приватный репозиторий и клонируй его
сюда, а не полагайся на `private/`.

Секреты (токены, пароли) не место и здесь — они по-прежнему только в `~/.env.d/`.

## Соглашения

- **Секреты и машинозависимые значения — только в `~/.env.d/`**, он вне репозитория.
  Слои грузятся по алфавиту циклом в `zsh/rc.zsh`:
  `00-core.sh` (`$DOTFILES`, нужен до `aliases.zsh`), `10-work.sh` (рабочие токены,
  внутренние хосты, `WORK_EMAIL`), `20-personal.sh` (личные ключи, `ORANGEPI_*`).
  Новый класс переменных = новый файл с префиксом, `rc.zsh` трогать не надо.
  Рядом с использованием оставляй комментарий `# requires XXX in ~/.env.d`.
  Никогда не коммить токены, пароли, внутренние хосты и рабочие адреса.
- **Lua**: форматирование по `nvim/stylua.toml` — 2 пробела, ширина 120.
- **Shell**: bash с `#!/usr/bin/env bash`, `set -e`, функции-хелперы
  `info/user/success/fail` для вывода в `bootstrap.sh`.
- **Комментарии** пишем по-русски, как в существующих файлах.
- **Коммиты** — по Conventional Commits, оформляем через локальный скилл `git-commit`:
  `<type>(<scope>): <описание>`. Заголовок английский, в императиве, строчными,
  до 72 символов; тело — по-русски и только когда есть что объяснить.
  - scope — директория инструмента: `nvm`, `zsh`, `nvim`, `herdr`, `tmux`, `install`.
    Правка сразу по нескольким — scope можно опустить.
  - из типов тут реально нужны `feat` (новый конфиг или возможность),
    `fix` (сломанное поведение), `refactor` (перенос без смены поведения),
    `docs` (AGENTS.md, README), `chore` (мелочь).
  - пример: `feat(nvm): move nvm config into dotfiles, default to node 24`.
  - один логический блок на коммит: не смешивай правку конфига с обновлением
    скиллов или зависимостей.
  - история до `592d442` — в старом формате (`add lazyvim`), её не переписываем.

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
- Глобальный gitignore линкуется в `~/.config/git/ignore`, а **не** в `~/.gitignore`:
  `core.excludesfile` нигде не задан, и git по умолчанию читает именно XDG-путь —
  симлинк на `~/.gitignore` не применялся вообще. Не «чинить» обратно.
- В `install/Brewfile` намеренно нет секций `vscode` и `go` из `brew bundle dump`:
  VS Code в сетапе не используется, а `go install`-пакеты требуют go-тулчейна,
  который через brew не ставится. При новом дампе их надо вырезать снова.
- `alacritty` больше не установлен (перешли на `ghostty`), но конфиг
  `alacritty/` в репозитории остался.
- В `zsh/rc.zsh` есть абсолютные пути `/Users/vasyapetrukhin/...` (yandex-cloud, LM Studio).
- Из `~/.config/hunk` версионируется только `config.toml`. `state.json` рядом —
  рантайм самого hunk (`lastSeenCliVersion`), в репозиторий не тащим.
- Из `~/.config/herdr` версионируется только `config.toml` и свои плагины.
  Остальное — рантайм-состояние самого herdr (`session.json`, `sessions/`,
  `plugins.json` с абсолютными путями, логи, сокеты), в репозиторий не тащим.
- В `herdr/config.toml` есть биндинги на плагины `herdr-file-viewer` и
  `persiyanov.reviewr`, которые сейчас не установлены (`herdr plugin list`) —
  это не опечатка, а неактивные горячие клавиши.

## nvm

Версионируется три файла:

- `nvm/default-alias` → `~/.nvm/alias/default` — **дефолтная версия node**.
  Сейчас там `24`: nvm резолвит это в самую свежую установленную v24.x
  (на текущей машине — v24.18.1), патч не пинится и внешний кэш алиасов не нужен.
  Менять можно и руками в файле, и через `nvm alias default <версия>`:
  nvm пишет алиас через `tee`, симлинк не рвётся и правка приезжает в репозиторий.
  Оборотная сторона — `nvm unalias default` симлинк **удалит**, тогда нужен
  `./install/bootstrap.sh`.
- `nvm/default-packages` → `~/.nvm/default-packages` — пакеты, которые ставятся
  глобально при каждом `nvm install <версия>` (сейчас — LSP-серверы для nvim).
- `nvm/init.zsh` — загрузка `nvm.sh`, completion и хук `load-nvmrc`
  (автопереключение по `.nvmrc` при `cd`, возврат на default при выходе).

`init.zsh` подключается из `rc.zsh` **после всех `export PATH=...`** — это
принципиально. `nvm.sh` при загрузке сам активирует default и кладёт свой bin
в начало PATH; если после этого дописать PATH руками (как было раньше),
node из nvm перекрывается системным и `nvm current` показывает `system`.
Не переноси `source_if_exists $DOTFILES/nvm/init.zsh` выше по файлу.

`nvm.sh` ищется по списку: git-клон в `$NVM_DIR`, затем brew
(`/opt/homebrew`, `/usr/local`) — берётся первый живой.

Проверка: `zsh -i -c 'which node; nvm current; nvm version default'`.

## Herdr

`herdr/config.toml` → `~/.config/herdr/config.toml`, применяется без рестарта:
`herdr server reload-config` (проверка синтаксиса — `herdr config check`).

Свои плагины лежат в `herdr/plugins/<имя>/herdr-plugin.toml` и подключаются
локальной ссылкой прямо в репозиторий — реестр плагинов (`plugins.json`) не
версионируется, поэтому на новой машине их надо слинковать руками:

```bash
herdr plugin link "$DOTFILES/herdr/plugins/lazygit"
herdr plugin link "$DOTFILES/herdr/plugins/hunk"
herdr plugin link "$DOTFILES/herdr/plugins/nvim"
```

После этого `plugin_root` указывает в репозиторий, и правки манифеста
подхватываются на месте. Каждый плагин самодостаточен, поэтому
`bin/resolve-dir.sh` (каталог активной панели из `HERDR_PLUGIN_CONTEXT_JSON`)
лежит в обоих копией — общего `plugin_root` у них нет.

Про биндинги в `[[keys.command]]`:

- типы — `shell` (фоном), `pane` (временная панель), `popup` (модальный терминал),
  `plugin_action`. Отдельного типа «открыть во вкладке» нет — вкладку даёт
  только плагин через `placement = "tab"`, ради этого и заведены
  `plugins/lazygit`, `plugins/hunk` и `plugins/nvim`.
- дефолтные сочетания herdr занимают почти все `prefix+<буква>`
  (`prefix+g` — goto, `prefix+shift+g` — new_worktree и т.д.). Полный список
  закомментирован в эталонном конфиге внутри бинарника; конфликт `herdr config check`
  **не** покажет — кастомный биндинг молча перекроет встроенный.
- **`alt+…` не использовать**: в текущем терминале (Ghostty на macOS, без
  `macos-option-as-alt`) option-аккорды до herdr не доходят — `prefix+alt+h`
  не давал вообще ничего. Свободные `prefix+shift+<буква>` работают надёжно.
- сработавшие биндинги видно в `herdr plugin log list` — если записи нет,
  нажатие не дошло до herdr, и дело не в плагине.

## Claude Code

Версионируется в `claude/`:

- `claude/settings.json` → `~/.claude/settings.json` — модель, `effortLevel`,
  тема, statusLine, включённые плагины.
- `claude/skills/<имя>` → `~/.claude/skills/<имя>` — по симлинку на каждый скилл
  отдельно, а не на всю директорию: рядом в `~/.claude/skills` лежат чужие
  симлинки (`herdr`, `hunk-review` → `~/.agents/skills`, `biz-agent-kit` →
  рабочий репозиторий), их трогать нельзя.

Скиллы с рабочими внутренностями лежат в `private/claude/` (см. ниже).
Не версионируется вообще: `settings.local.json` (он в глобальном gitignore)
и рантайм-состояние — `history.jsonl`, `projects/`, `sessions/`, `plugins/`,
`shell-snapshots/`, логи.

Осторожно: Claude Code сам перезаписывает `settings.json` (например при смене
темы или модели через `/config`). Если он запишет файл через «создать временный
+ переименовать», симлинк заменится обычным файлом и правки перестанут попадать
в репозиторий. После правок через UI проверяй `ls -l ~/.claude/settings.json`.

## Проверка изменений

Автотестов нет, проверяем руками:

- shell: `bash -n install/bootstrap.sh`, `zsh -n zsh/rc.zsh zsh/aliases.zsh`
- lua: `stylua --check nvim/` (если stylua установлен)
- tmux: `tmux source-file tmux/tmux.conf`
- herdr: `herdr server reload-config` (подхватит `config.toml` в живом сервере)
- симлинки: `ls -l ~/.zshrc ~/.tmux.conf ~/.config/nvim ~/.config/herdr/config.toml`
  `~/.claude/settings.json`
- скиллы Claude Code: `jq -e . ~/.claude/settings.json` и `/doctor` в живой сессии

Правки в `~/.zshrc` подхватываются в новом шелле или после `source ~/.zshrc`.
