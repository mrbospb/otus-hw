# Description
PAM module.
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.
# How-to
Один из способов реализовать задание это выполнить при подключении пользователя скрипт, в котором мы сами опишем необходимые условия.

Копируем скрипт `hate_mondays.sh` в `/usr/local/bin/`
```
#!/bin/bash

ADMIN_TEMPLATE=".*admin.*"

if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
    if [[ $(id -Gn $PAM_USER) =~ $ADMIN_TEMPLATE ]]; then
        exit 0
    else
        exit 1
    fi
fi

```
Делаем скрипт исполняемым
```
chmod +x /usr/local/bin/hate_mondays.sh
```

В `/etc/pam.d/sshd` добавляем строку:
```
account    required     pam_exec.so /usr/local/bin/hate_mondays.sh
```
Тем самым мы добавили модуль pam_exec и указали скрипт в качестве условий проверки. Если ни одна группа, в которой состоит пользователь, не будет удовлетворять шаблону `ADMIN_TEMPLATE=".*admin.*"`, то вход будет разрешен только по будням.

# Check
Создадим группу admin
```
groupadd admin
```
Добавим пользователя devops в новую группу
```
usermod -aG admin devops
```
Попробуем войти под пользователями devops и vagrant. На буднях вход должен быть успешным.

Для проверки логина в выходные установить необходимые дату и время, например:
```
systemctl stop chronyd.service
date --set="Jan  14 22:41:36 UTC 2023"
```
На выходных сможет залогиниться только devops.
