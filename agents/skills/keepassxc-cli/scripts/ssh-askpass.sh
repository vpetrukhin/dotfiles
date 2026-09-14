#!/bin/sh
# SSH_ASKPASS-хелпер для скилла keepassxc-cli.
#
# ssh-add запрашивает парольную фразу ключа на tty, которого у неинтерактивного
# шелла нет. С SSH_ASKPASS_REQUIRE=force ssh-add вместо tty вызывает этот скрипт и
# читает фразу с его stdout. Фразу передаём в переменной KP_PASSPHRASE — она должна
# жить ровно один вызов команды, не экспортироваться в шелл сессии.
#
# Использование:
#   KP_PASSPHRASE="$phrase" SSH_ASKPASS=/путь/к/ssh-askpass.sh SSH_ASKPASS_REQUIRE=force \
#     ssh-add -t 3600 -
#
# Аргумент ssh-add (текст приглашения) игнорируется намеренно: скрипт всегда отдаёт
# одно и то же значение и ничего не печатает в stderr, чтобы фраза не утекла в логи.

printf '%s' "$KP_PASSPHRASE"
