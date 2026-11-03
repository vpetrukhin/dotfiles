# dotfiles

Личные конфиги для macOS (Apple Silicon): zsh, Neovim, Ghostty, Git, Herdr, pi и другие инструменты. Часть настроек привязана к моим путям и аккаунтам — перед установкой на чужой машине проверь `git/config`, `zsh/rc.zsh` и `links.prop`.

## Настройка на новой машине

1. **Клонируй репозиторий.** Для первоначальной настройки достаточно HTTPS; дальше команды выполняются из корня репозитория:

   ```bash
   git clone https://github.com/vpetrukhin/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Установи Homebrew и пакеты.** Если Homebrew уже установлен, пропусти первую команду. `Brewfile` устанавливает и CLI, и приложения, включая `zsh`, `nvm`, Ghostty, Neovim и Herdr:

   ```bash
   ./install/install-brew.sh
   ./install/install-brew-package.sh
   ```

   Homebrew установит zsh, но не сделает его shell по умолчанию: без переключения macOS продолжит запускать системный `/bin/zsh`. Скрипт найдёт zsh из Homebrew, при необходимости добавит его в `/etc/shells` (понадобится `sudo`) и вызовет `chsh`:

   ```bash
   ./install/switch-zsh.sh
   ```

   Открой новый терминал и проверь `echo "$SHELL"`: ожидается `/opt/homebrew/bin/zsh` на Apple Silicon. Для интерактивного zsh также нужен Oh My Zsh в `~/.oh-my-zsh`: `zsh/rc.zsh` подключает его без проверки. Установи его до переключения на этот конфиг. Если установщик изменит `~/.zshrc`, на следующем шаге сохрани файл через вариант backup.

3. **При переносе со старой машины восстанови локальные данные** (необязательно). `~/.env.d` содержит секреты и не хранится в git; `private/` содержит рабочие конфиги и тоже не версионируется. На старой машине создай архивы, на новой распакуй их **до** установки симлинков:

   ```bash
   ./install/env-archive.sh pack
   ./install/private-archive.sh pack
   # Перенеси архивы на новую машину, затем там:
   ./install/env-archive.sh unpack ~/Downloads/env.d-<дата>.tgz.enc
   ./install/private-archive.sh unpack ~/Downloads/private-<дата>.tgz
   ```

   Архив `env.d` зашифрован; пароль передавай отдельно. Архив `private` **не зашифрован** — передавай безопасным способом и удали оба архива после переноса. Если данные не переносишь, следующий шаг создаст пустые шаблоны `~/.env.d/{00-core,10-work,20-personal}.sh`; заполни нужные переменные вручную (например, `NPM_TOKEN` для npm). Не клади секреты в репозиторий.

4. **Создай симлинки:**

   ```bash
   ./install/bootstrap.sh
   ```

   Скрипт берёт пары источник/назначение из `*/links.prop`, создаёт отсутствующие каталоги и файлы `~/.env.d`, а для уже существующих целей спрашивает `skip`, `overwrite` или `backup`. Запускай в интерактивном терминале; перед `overwrite` проверь, что старый конфиг не нужен. Повторный запуск пропускает уже правильные симлинки. Если репозиторий лежит не в `~/dotfiles`, путь в `~/.env.d/00-core.sh` скрипт определит сам.

5. **Установи инструменты через mise и открой новый терминал.** Node и npm-CLI (TypeScript, LSP-серверы, pi, todoist) описаны в `mise/config.toml`; шаг 4 уже поставил на него симлинк `~/.config/mise/config.toml`:

   ```bash
   mise install
   zsh -i -c 'which node; node -v; mise current'
   ```

   `node` должен быть из `~/.local/share/mise/installs/node/…`. Версия в проектах переключается по `.nvmrc` — mise включён как idiomatic version file. nvm больше не используется и оставлен только для отката: `nvm/` и пакет из `Brewfile` не удаляй, подробности — в AGENTS.md.

6. **Донастрой отдельные инструменты при необходимости.** Полный конфиг `nvim/` и минимальный `nvim_minimal/` подключаются через bootstrap. Локальные плагины Herdr не регистрируются через симлинки конфига — подключи их отдельно:

   ```bash
   herdr plugin link "$DOTFILES/herdr/plugins/lazygit"
   herdr plugin link "$DOTFILES/herdr/plugins/hunk"
   herdr plugin link "$DOTFILES/herdr/plugins/nvim"
   herdr config check
   ```

   Проверь симлинки и открой новый zsh:

   ```bash
   ls -l ~/.zshrc ~/.config/nvim ~/.config/ghostty/config ~/.config/git/config ~/.config/herdr/config.toml
   zsh -i -c 'echo "$DOTFILES"; node -v; mise current'
   ```

   Либо проверь всё сразу диагностикой из корня репозитория: `mise run doctor`.

## Перенос произвольной папки

`install/folder-archive.sh` упаковывает одну папку в `.tgz` вместе с её именем и распаковывает её в указанный каталог. Существующую папку не перезаписывает:

```bash
./install/folder-archive.sh pack ~/Documents/example ~/Desktop/example.tgz
# Перенеси архив на другую машину
./install/folder-archive.sh unpack ~/Downloads/example.tgz ~/Documents
```

Архив **не зашифрован**: для секретов из `~/.env.d` используй `install/env-archive.sh`, а `private/` переноси безопасным способом. Распаковывай только архивы из доверенного источника.

## Обновление

После изменения `links.prop` повторно запусти `./install/bootstrap.sh`. Для добавления пакета обнови `install/Brewfile` (перед коммитом проверь дифф: `brew bundle dump` может добавить лишние секции):

```bash
brew install <package>
brew bundle dump --force --file=install/Brewfile
```

Глобальные CLI обновляются через mise, а не `npm install -g`: `mise upgrade` (список — `mise/config.toml`).

## Проверки

В корне репозитория есть проектный `mise.toml` с задачами; инструментов он не задаёт и глобальный конфиг не заменяет. Задачи сами переходят в корень репозитория, откуда бы их ни вызвали:

```bash
mise run check      # bash -n/zsh -n для shell-конфигов, jq -e для JSON, git diff --check
mise run doctor     # симлинки по links.prop, обязательные команды, пути node/npm/pi
```

`check` ничего не устанавливает и не меняет файлы; `private/` и runtime-каталоги не сканируются. `doctor` — только диагностика: найденные расхождения исправляются вручную (`./install/bootstrap.sh`), `[warn]` про необязательные команды — не регрессия. Первый запуск задач может потребовать `mise trust mise.toml` (доверяем только этому конфигу).

Подробнее об устройстве конфигов и ограничениях — в [AGENTS.md](AGENTS.md).
