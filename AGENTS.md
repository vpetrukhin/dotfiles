# AGENTS.md

Инструкции для ИИ-агентов, работающих в этом репозитории.

## Что это

Личные dotfiles для рабочего macOS-сетапа. Кода нет — только конфиги
(zsh, neovim, ghostty, yazi, herdr, git) и bash-скрипты установки.
Сборки, тестов и CI нет.

## Структура

Каждая директория верхнего уровня — один инструмент:

| Директория     | Что настраивает                                  |
| -------------- | ------------------------------------------------ |
| `zsh/`         | `rc.zsh` → `~/.zshrc`, `zprofile` → `~/.zprofile`, `aliases.zsh` (алиасы и функции) |
| `nvim/`        | конфиг на базе LazyVim-starter (Lua)             |
| `nvim_minimal/`| минимальный отдельный конфиг для быстрых правок  |
| `ghostty/`     | `config` (эмулятор терминала)                    |
| `yazi/`        | `yazi.toml`                                      |
| `mise/`        | `config.toml` → `~/.config/mise/config.toml` (node и глобальные npm-инструменты) |
| `nvm/`         | legacy nvm: `default-alias`, `default-packages`, `init.zsh` (не подключён, оставлен для отката) |
| `herdr/`       | `config.toml` (терминальный мультиплексор для агентов) |
| `pi/`          | `settings.json`, `keybindings.json` → `~/.pi/agent/` (coding-агент pi) |
| `git/`         | `config` и глобальный gitignore → `~/.config/git/` |
| `gh/`          | `config.yml` → `~/.config/gh/config.yml` (GitHub CLI, алиасы) |
| `npm/`         | `npmrc` → `~/.npmrc` (токен — из `$NPM_TOKEN`)     |
| `hunk/`        | `config.toml` (терминальный просмотрщик диффов)   |
| `claude/`      | `settings.json` и скиллы только для Claude Code    |
| `agents/`      | скиллы, общие для всех агентов (Claude Code, pi)  |
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
`private/claude/agents/…`, `private/ssh/config` → `~/.ssh/config` (только
конфиг, ключи — в KeePassXC). Симлинки в `$HOME` bootstrap ставит наравне с
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
  - scope — директория инструмента: `mise`, `nvm`, `zsh`, `nvim`, `herdr`, `install`.
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

- `nvim/links.prop` подключает полный конфиг к `~/.config/nvim` через bootstrap.
  Путь источника заканчивается на `/`, чтобы совпадать со старым ручным
  симлинком: bootstrap сравнивает пути буквально.
- Глобальный gitignore линкуется в `~/.config/git/ignore`, а **не** в `~/.gitignore`:
  `core.excludesfile` нигде не задан, и git по умолчанию читает именно XDG-путь —
  симлинк на `~/.gitignore` не применялся вообще. Не «чинить» обратно.
- Глобальный git-конфиг тоже по XDG-пути: `git/config` → `~/.config/git/config`.
  Файла `~/.gitconfig` быть не должно — git читает его позже и он перебьёт
  версионируемый. Личный `user.email` задан прямо в `git/config`, а для
  `~/Development/bankiru/` его перебивает `[includeIf "gitdir:..."]` из
  `~/.config/git/work`. Этот файл не версионируется: его пишет `zsh/rc.zsh`
  из `$WORK_EMAIL` (git не читает переменные окружения). Нет `WORK_EMAIL` —
  нет файла, и в рабочих репозиториях уйдёт личный email.
- `keepassxc-cli` отдельной формулы в Homebrew не имеет и в `Brewfile` отдельной
  строкой не появится: его ставит каска `keepassxc` как Binary-артефакт —
  `/opt/homebrew/bin/keepassxc-cli` это симлинк внутрь `KeePassXC.app`. Не добавлять
  `brew "keepassxc-cli"` и не «чинить» симлинк. Комментарии в `Brewfile` тоже
  бессмысленны — `brew bundle dump --force` перезаписывает их своими.
- В `install/Brewfile` намеренно нет секций `vscode` и `go` из `brew bundle dump`:
  VS Code в сетапе не используется, а `go install`-пакеты требуют go-тулчейна,
  который через brew не ставится. При новом дампе их надо вырезать снова.
- Ghostty на macOS читает и `~/.config/ghostty/config` (сюда bootstrap ставит
  симлинк из репозитория), и `~/Library/Application Support/com.mitchellh.ghostty/config`
  — второй грузится позже и переопределяет первый. Старый локальный конфиг
  (`config.ghostty`) удалён, его настройки перенесены в репозиторий. Не заводить
  его заново: он молча перебьёт то, что ставит bootstrap.
- В конфиге ghostty намеренно не задан `term`: у ghostty свой terminfo
  `xterm-ghostty`. Если на удалённом хосте его нет, ставить его надо там
  (`infocmp -x | ssh host -- tic -x -`), а не откатывать `term` локально.
- В `zsh/rc.zsh` есть абсолютные пути `/Users/vasyapetrukhin/...` (yandex-cloud, LM Studio).
- Из `~/.config/gh` версионируется только `config.yml`. `hosts.yml` (аккаунт,
  при `--insecure-storage` ещё и токен) не тащим. `gh config set` пишет
  в файл по тому же пути, симлинк не рвётся.
- В `npm/npmrc` токен npmjs не хранится: там `${NPM_TOKEN?}`, значение — в
  `~/.env.d/20-personal.sh`. `?` обязателен: без него npm падает на любой
  команде, если переменная не задана. `npm login` и `npm config set` пишут
  прямо в `~/.npmrc`, то есть в репозиторий, и затрут подстановку реальным
  токеном — после них проверяй `git diff npm/`.
- Скилл `todoist-cli` в репозиторий не кладём: его ставит и обновляет сам
  `td` (`td skill install <агент>`, `td skill update`), копия бы устарела.
- Из `~/.config/hunk` версионируется только `config.toml`. `state.json` рядом —
  рантайм самого hunk (`lastSeenCliVersion`), в репозиторий не тащим.
- Из `~/.config/herdr` версионируется только `config.toml` и свои плагины.
  Остальное — рантайм-состояние самого herdr (`session.json`, `sessions/`,
  `plugins.json` с абсолютными путями, логи, сокеты), в репозиторий не тащим.
- В `herdr/config.toml` есть биндинги на плагины `herdr-file-viewer` и
  `persiyanov.reviewr`, которые сейчас не установлены (`herdr plugin list`) —
  это не опечатка, а неактивные горячие клавиши.

## Node (mise)

Основной менеджер node — mise (`brew "mise"`). nvm оставлен только для отката,
см. раздел ниже.

Версионируется один файл: `mise/config.toml` → `~/.config/mise/config.toml`
(глобальный конфиг mise).

- `[tools]` — `node = "24.22"` (та же ветка v24, что была дефолтом в nvm, но
  зафиксирована на исправленной по TLS линии, см. ниже) и CLI,
  которые раньше ставились глобально через `nvm/default-packages`, теперь
  отдельными инструментами npm-бэкенда: `npm:typescript`,
  `npm:typescript-language-server`, `npm:vscode-langservers-extracted`,
  `npm:@earendil-works/pi-coding-agent`, `npm:@doist/todoist-cli`. Все — `latest`.
  Отдельный `npm:`-инструмент, а не `npm install -g`, нужен потому, что глобальные
  пакеты живут внутри конкретной версии node и пропадают при её смене, а
  npm-бэкенд даёт каждому CLI свой shim. Новый такой CLI добавляется строкой
  `"npm:<пакет>" = "latest"` и потом `mise install`.
- `[settings] idiomatic_version_file_enable_tools = ["node"]` — mise читает
  `.nvmrc` в проектах (замена хука `load-nvmrc` из `nvm/init.zsh`).

Почему `24.22`, а не `24`: Plannotator (расширение pi) предупреждает, что Node
старше 22.23.4 / 24.22.1 / 26.12.1 не содержит октябрьских TLS-фиксов 2026
(скомпрометированный CA); источник — `runtime-tls.ts` в пакете расширения.
Мажорный `node = "24"` резолвится в самую свежую **установленную** 24.x и
ничего не гарантирует, а `24.22` фиксирует дефолт на исправленной линии. Патч
не пинится: в ветке берётся самая свежая установленная 24.22.x. Проект со своим
`.nvmrc` (в `happyopt-new` — `24.18.1`) всё равно перекроет дефолт и вернёт
предупреждение — тогда правится `.nvmrc` в самом проекте, а не этот конфиг.
Точный пин (`node = "24.22.1"`) возможен только после
`mise install node@24.22.1`: сейчас эта версия не установлена, и пин на
неустановленную версию сломал бы `node` вне проектов с `.nvmrc`.

В `zsh/rc.zsh` mise подключается через `eval "$(mise activate zsh)"` **после
всех `export PATH=...`** — это принципиально: activate добавляет каталоги инструментов в
начало PATH, иначе node и npm-инструменты из mise перекрываются системными и
brew. Не переноси этот блок выше по файлу. Загрузка `~/.env.d` остаётся в начале
файла, как была.

Установка объявленных инструментов: `mise install` (из любого каталога, конфиг
глобальный). Проверка: `zsh -i -c 'which node; node -v; mise current'` — node
должен быть из `~/.local/share/mise/installs/node/...`.

Не версионируется: рантайм и кэши mise (`~/.local/share/mise`,
`~/.local/state/mise`). `~/.config/mise/config.toml` — симлинк из репозитория,
другие файлы рядом (если появятся) в git не тащим.

В корне репозитория лежит отдельный проектный `mise.toml` — только задачи
проверки (см. «Проверка изменений»), инструментов он не задаёт и глобальный
конфиг не заменяет.

Свежие релизы `mise upgrade` может не подтянуть: действует `minimum_release_age`
(по умолчанию 24 ч), в выводе будет `WARN ... ignored by minimum_release_age`.
Если версия нужна раньше, ставим явно — `mise install npm:<пакет>@<версия>`
(явный пин ограничение обходит), декларацию при этом можно оставить `latest`.
Так обновлён pi с 1.4.0 до 1.5.0.

## nvm (legacy)

nvm больше не грузится из `rc.zsh` (строка со `source_if_exists
$DOTFILES/nvm/init.zsh` закомментирована) и node не активирует: его заменил mise.
Файлы, brew-пакет `nvm` и алиас `default` сохранены как состояние для отката, не
удалять. Откат: раскомментировать `source` в `rc.zsh` и убрать блок с
`mise activate`, иначе оба менеджера будут бороться за PATH.

Версионируются три файла (нужны для отката):

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

`init.zsh` (когда его включат обратно) подключается из `rc.zsh` **после всех
`export PATH=...`** — это принципиально. `nvm.sh` при загрузке сам активирует
default и кладёт свой bin
в начало PATH; если после этого дописать PATH руками (как было раньше),
node из nvm перекрывается системным и `nvm current` показывает `system`.
Не переноси `source_if_exists $DOTFILES/nvm/init.zsh` выше по файлу.

`nvm.sh` ищется по списку: git-клон в `$NVM_DIR`, затем brew
(`/opt/homebrew`, `/usr/local`) — берётся первый живой.

Проверка при откате: `zsh -i -c 'which node; nvm current; nvm version default'`.
Сейчас эта проверка ожидаемо покажет node из mise, а не из nvm.

## Herdr

`herdr/config.toml` → `~/.config/herdr/config.toml`, применяется без рестарта:
`herdr server reload-config` (проверка синтаксиса — `herdr config check`).

Осторожно: herdr и его плагины сами пишут в `config.toml` (смена темы или
сайдбара через UI, блоки вроде `# >>> herdr-radar theme block`) и уже как-то
заменили симлинк обычным файлом — правки молча перестали попадать в репозиторий.
После таких изменений проверяй `ls -l ~/.config/herdr/config.toml`. Если там
обычный файл — сначала перенеси его отличия в репозиторий (`diff`), потом
верни симлинк через `./install/bootstrap.sh`. Заодно смотри, куда herdr
вставил новую таблицу: `[ui.sidebar.agents]` посреди `[ui]` забирает себе все
ключи ниже, и `herdr config check` ругается на `unknown config key`.

Свои плагины лежат в `herdr/plugins/<имя>/herdr-plugin.toml` и подключаются
локальной ссылкой прямо в репозиторий — реестр плагинов (`plugins.json`) не
версионируется, поэтому на новой машине их надо слинковать руками:

```bash
herdr plugin link "$DOTFILES/herdr/plugins/lazygit"
herdr plugin link "$DOTFILES/herdr/plugins/hunk"
herdr plugin link "$DOTFILES/herdr/plugins/nvim"
herdr plugin link "$DOTFILES/herdr/plugins/dashboard"
```

После этого `plugin_root` указывает в репозиторий, и правки манифеста
подхватываются на месте. Каждый плагин самодостаточен, поэтому
`bin/resolve-dir.sh` (каталог активной панели из `HERDR_PLUGIN_CONTEXT_JSON`)
лежит в обоих копией — общего `plugin_root` у них нет.

Про биндинги в `[[keys.command]]`:

- типы — `shell` (фоном), `pane` (временная панель), `popup` (модальный терминал),
  `plugin_action`. Отдельного типа «открыть во вкладке» нет — вкладку даёт
  только плагин через `placement = "tab"`, ради этого и заведены
  `plugins/lazygit`, `plugins/hunk`, `plugins/nvim` и `plugins/dashboard`.
- дефолтные сочетания herdr занимают почти все `prefix+<буква>`
  (`prefix+g` — goto, `prefix+shift+g` — new_worktree и т.д.). Полный список
  закомментирован в эталонном конфиге внутри бинарника; конфликт `herdr config check`
  **не** покажет — кастомный биндинг молча перекроет встроенный.
- **`alt+…` не использовать**: в текущем терминале (Ghostty на macOS, без
  `macos-option-as-alt`) option-аккорды до herdr не доходят — `prefix+alt+h`
  не давал вообще ничего. Свободные `prefix+shift+<буква>` работают надёжно.
- сработавшие биндинги видно в `herdr plugin log list` — если записи нет,
  нажатие не дошло до herdr, и дело не в плагине.

Плагин `dashboard` (`prefix+shift+b`) — вкладка из двух панелей с fzf: слева
задачи открытого спринта из Jira и ниже мои задачи с лейблом
`pre_grooming` (без уже попавших в спринт), справа мои PR и PR, ждущие моего апрува, из
Bitbucket. Вкладку собирает `bin/open.sh`: панель `jira` с `placement = "tab"`,
к ней сплитом справа панель `prs`. Действия — в шапке каждого fzf (открыть,
`jira issue move`, diff PR в `hunk patch`, апрув с подтверждением). Внизу
панели PR — все открытые PR, сгруппированные по репозиториям. Список
репозиториев не версионируется (имена рабочих репозиториев): файл `repos` в
`herdr plugin config-dir vpetrukhin.dashboard`, строка `PROJECT/slug`, `#` —
комментарий; читается при каждой загрузке, перезапуск не нужен. Данные
кэшируются в `~/.cache/herdr-dashboard`, у каждой панели свой цикл обновления
раз в 30 минут (`DASHBOARD_INTERVAL`, с); после закрытия вкладки цикл
завершается в течение 10 с.
Тот же скрипт с аргументом `status` выводит счётчики в `[ui] tab_bar_right`:
herdr запускает его через `/bin/sh -lc` без zsh-окружения, поэтому скрипт сам
дописывает brew в PATH и подгружает `~/.env.d/10-work.sh`. В скрипте нет хостов
и ключей проектов: сервер Jira берётся из конфига jira-cli, Bitbucket — из
`$BITBUCKET_URL`, выборки задач можно переопределить через `DASHBOARD_JIRA_JQL` (спринт) и
`DASHBOARD_PREGROOMING_JQL` (прегруминг).

Ссылки в панелях (и обычные URL, и OSC 8, как в `jira-table` из `zsh/jira.zsh`)
открываются по **ctrl+клику**, а не по cmd+клику: herdr захватывает мышь
(`mouse_capture = true` по умолчанию), и в захваченных событиях cmd от обычного
клика не отличается. Это не поломка — выключать `mouse_capture` ради cmd+клика
не надо, пропадёт мышиный UI herdr.

## Claude Code

Версионируется в `claude/`:

- `claude/settings.json` → `~/.claude/settings.json` — модель, `effortLevel`,
  тема, statusLine, `outputStyle`, включённые плагины.
- `claude/statusline.sh` → `~/.claude/statusline.sh` — сам statusLine; в
  `settings.json` только путь к нему. Проверка без живой сессии:
  `echo '{"workspace":{"current_dir":"'$PWD'"},"model":{"display_name":"X"}}' | ~/.claude/statusline.sh`.
- `claude/output-styles/<имя>.md` → `~/.claude/output-styles/<имя>.md` — свои
  output styles. Сейчас один — `caveman` (сжатые ответы), он же прописан в
  `outputStyle` в `settings.json`, то есть включён по умолчанию во всех сессиях.
  Переключение на ходу — `/output-style`.
  Правила стиля скопированы из скилла `caveman` (`.agents/skills/caveman`) —
  апдейты скилла в стиль сами не приезжают, синхронизировать руками.
- `claude/skills/<имя>` → `~/.claude/skills/<имя>` — по симлинку на каждый скилл
  отдельно, а не на всю директорию: рядом в `~/.claude/skills` лежат чужие
  скиллы — симлинки (`herdr`, `hunk-review` → `~/.agents/skills`) и копии
  командных скиллов, которые ставит `npm run install-skills` из рабочего
  репозитория `~/Development/bankiru/claude` (манифест —
  `~/.claude/banki-team-config/installed.json`), их трогать нельзя.

Скиллы с рабочими внутренностями лежат в `private/claude/` (см. ниже).
Не версионируется вообще: `settings.local.json` (он в глобальном gitignore)
и рантайм-состояние — `history.jsonl`, `projects/`, `sessions/`, `plugins/`,
`shell-snapshots/`, логи.

Осторожно: Claude Code сам перезаписывает `settings.json` (например при смене
темы или модели через `/config`). Если он запишет файл через «создать временный
+ переименовать», симлинк заменится обычным файлом и правки перестанут попадать
в репозиторий. После правок через UI проверяй `ls -l ~/.claude/settings.json`.

## pi

Из `~/.pi/agent/` версионируются только `settings.json` (провайдер, модель,
список `packages`) и `keybindings.json`. Остальное — рантайм и секреты
(`auth.json`, `models-store.json`, `sessions/`, `mcp-*.json`), в репозиторий
не тащим.

pi сам пишет в `settings.json` (например `lastChangelogVersion` после обновления),
но через `writeFileSync` по тому же пути, а не через переименование —
симлинк не рвётся, а правка просто приезжает в репозиторий диффом.
Блокировку `proper-lockfile` ставит рядом с симлинком, это не мусор.

pi ставится двумя путями: npm-инструментом mise (`npm:@earendil-works/pi-coding-agent`
— его видит новый интерактивный zsh) и self-update установкой самого pi
(`pi update`, релизы в `~/.pi/agent/install/`, лаунчер `~/.pi/agent/bin/pi`).
Версии могут разъезжаться; `mise run doctor` показывает оба пути и ошибкой это
не считает. Если pi запущен из mise, `pi update` сам себя не обновит (пакетом
владеет mise) — обновляй `mise upgrade`; managed-установка обновляется через
`pi update`. Не двумя способами сразу.

## Общие скиллы агентов (`agents/`)

Скиллы, не завязанные на конкретный harness, лежат в `agents/skills/<имя>/SKILL.md`
(формат [Agent Skills](https://agentskills.io/specification): frontmatter `name` +
`description`, рядом `scripts/`, `references/`). Сейчас там `keepassxc-cli`.

`agents/links.prop` линкует каждый такой скилл **в две точки сразу**:

```
$DOTFILES/agents/skills/<имя>=$HOME/.claude/skills/<имя>
$DOTFILES/agents/skills/<имя>=$HOME/.agents/skills/<имя>
```

- `~/.claude/skills/` — откуда читает Claude Code.
- `~/.agents/skills/` — общий каталог стандарта; оттуда читает `pi`
  (`@earendil-works/pi-coding-agent`, ставится как `npm:`-инструмент из
  `mise/config.toml`), а также
  туда кладут свои скиллы herdr и hunk. Настройки pi для этого править не надо —
  каталог в списке источников по умолчанию (`pi` → `docs/skills.md`, раздел Locations).

Две строки с одним источником bootstrap обрабатывает независимо, это не опечатка.

Скилл, полезный только в Claude Code (завязан на его тулы, сабагентов, `/`-команды),
оставляй в `claude/skills/` — дублировать его в `~/.agents/skills` смысла нет.

В `agents/` не должно быть внутренних хостов, ключей проектов и путей к личному волту:
каталог версионируется, репозиторий публичный. Рабочее — в `private/claude/skills/`.

Проверка, что pi видит скилл: `pi -p '/skill:keepassxc-cli'` или `pi` → `/skill:` и
поиск по списку. Имя скилла у pi матчить имя директории не обязано, но у нас совпадает.

## Проверка изменений

Автотестов нет. Базовые проверки — задачи проектного `mise.toml` (запускаются
из корня репозитория при любом cwd; один раз может понадобиться
`mise trust mise.toml`, `trust --all` не используем):

- `mise run check` — `check:shell` (`bash -n` для всех `*.sh`, `zsh -n` для
  `*.zsh` и `zprofile`), `check:json` (`jq -e` для всех `*.json` под git) и
  `git diff --check`. Ничего не устанавливает, файлы не меняет, `private/`
  и runtime-каталоги не сканирует. Файл с комментариями — не строгий JSON:
  если такой появится, его надо явно исключить из `check:json`, а не ослаблять `jq`.
- `mise run doctor` — сверяет симлинки со всеми `links.prop` (кроме `private/`),
  проверяет обязательные команды и фактические пути node/npm/pi. Только
  диагностика: не исправляет, `[fail]` → exit 1, `[warn]` — необязательные
  команды и известные особенности, то есть не регрессии. `$DOTFILES`/`$HOME`
  в `links.prop` раскрываются без `eval`.

Скрипты задач — `mise/check-shell.sh`, `mise/check-json.sh`, `mise/doctor.sh`.

Остальное — руками:

- lua: `stylua --check nvim/` (если stylua установлен)
- herdr: `herdr server reload-config` (подхватит `config.toml` в живом сервере)
- симлинки: `ls -l ~/.zshrc ~/.config/nvim ~/.config/herdr/config.toml`
  `~/.claude/settings.json` (или `mise run doctor`)
- скиллы Claude Code: `jq -e . ~/.claude/settings.json` и `/doctor` в живой сессии

Правки в `~/.zshrc` подхватываются в новом шелле или после `source ~/.zshrc`.
