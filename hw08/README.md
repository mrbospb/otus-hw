# Log
## Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова
Создадим файл с конфигурацией сервиса
```
[root@hw08-server vagrant]# vi /etc/sysconfig/watchlog
[root@hw08-server vagrant]# cat /etc/sysconfig/watchlog
# Config file for custom watch service
# Put it into /etc/sysconfig
# File for watching and word for analize

WORD="ALERT"
LOG=/var/log/watchlog.log
```
Создадим файл для чтения
```
[root@hw08-server vagrant]# echo ALERT > /var/log/watchlog.log
[root@hw08-server vagrant]# cat /var/log/watchlog.log
ALERT
```
Создадим скрипт
```
[root@hw08-server vagrant]# vi /opt/watchlog.sh
[root@hw08-server vagrant]# cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
	logger "$DATE: GOTCHA!"
else
	exit 0
fi
```
Создадим сервис
```
[root@hw08-server vagrant]# vi /etc/systemd/system/watchlog.service
[root@hw08-server vagrant]# cat /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
Создадим таймер
```
[root@hw08-server vagrant]# vi /etc/systemd/system/watchlog.timer
[root@hw08-server vagrant]# cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```
Стартуем таймер и проверяем
```
[root@hw08-server vagrant]# systemctl daemon-reload
[root@hw08-server vagrant]# systemctl start watchlog.timer

[root@hw08-server vagrant]# systemctl status watchlog.timer
● watchlog.timer - Run watchlog script every 30 second
   Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: disabled)
   Active: active (waiting) since Wed 2022-09-14 14:02:06 UTC; 16min ago

Sep 14 14:02:06 hw08-server systemd[1]: Started Run watchlog script every 30 second.
Sep 14 14:02:06 hw08-server systemd[1]: Starting Run watchlog script every 30 second.
[root@hw08-server vagrant]# systemctl list-timers
NEXT                         LEFT     LAST                         PASSED       UNIT                         ACTIVATES
Wed 2022-09-14 14:18:29 UTC  5s left  Wed 2022-09-14 14:17:59 UTC  24s ago      watchlog.timer               watchlog.service
Thu 2022-09-15 12:41:59 UTC  22h left Wed 2022-09-14 12:41:59 UTC  1h 36min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.s

[root@hw08-server vagrant]# tail -f /var/log/messages
Sep 14 14:17:09 localhost systemd: Starting My watchlog service...
Sep 14 14:17:09 localhost root: Wed Sep 14 14:17:09 UTC 2022: GOTCHA!
Sep 14 14:17:09 localhost systemd: Started My watchlog service.
Sep 14 14:17:59 localhost systemd: Starting My watchlog service...
Sep 14 14:17:59 localhost root: Wed Sep 14 14:17:59 UTC 2022: GOTCHA!
Sep 14 14:17:59 localhost systemd: Started My watchlog service.
```
## Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл
Устанавливаем spawn-fcgi и необходимые для него пакеты
```
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
Раскомментируем строки с переменными
```
[root@hw08-server vagrant]# vi /etc/sysconfig/spawn-fcgi
[root@hw08-server vagrant]# cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```
Создадим юнит файл
```
[root@hw08-server vagrant]# vi /etc/systemd/system/spawn-fcgi.service
[root@hw08-server vagrant]# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```
Проверка
```
[root@hw08-server vagrant]# systemctl daemon-reload
[root@hw08-server vagrant]# systemctl start spawn-fcgi
[root@hw08-server vagrant]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2022-09-14 14:44:32 UTC; 608ms ago
 Main PID: 3604 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─3604 /usr/bin/php-cgi
           ├─3605 /usr/bin/php-cgi
           ├─3606 /usr/bin/php-cgi
           ...
           └─3636 /usr/bin/php-cgi

Sep 14 14:44:32 hw08-server systemd[1]: Started Spawn-fcgi startup service by Otus.
Sep 14 14:44:32 hw08-server systemd[1]: Starting Spawn-fcgi startup service by Otus...
```
## Дополнить unit-файл httpd возможностью запустить несколько инстансов сервера с разными конфигурационными файлами
Устанавливаем необходимые пакеты
```
yum install -y httpd
```
Создадим unit-файл c %i-подстановкой
```
[root@hw08-server vagrant]# vi /etc/systemd/system/httpd@.service
[root@hw08-server vagrant]# cat /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target

```
Копируем конфиг-1 и изменяем его
```
[root@hw08-server vagrant]# cp -a /etc/httpd /etc/httpd-1
[root@hw08-server vagrant]# vi /etc/sysconfig/httpd-1
...
OPTIONS=-f conf/httpd-1.conf
...
```
Копируем конфиги и изменяем их
```
[root@hw08-server vagrant]# cp -a /etc/httpd /etc/httpd-2
[root@hw08-server vagrant]# vi /etc/sysconfig/httpd-2
...
OPTIONS=-f conf/httpd-2.conf
...

[root@hw08-server vagrant]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-1.conf
[root@hw08-server vagrant]# vi /etc/httpd/conf/httpd-1.conf

PidFile /var/run/httpd-1.pid
Listen 8081
ErrorLog "logs/error_log-1"

[root@hw08-server vagrant]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-2.conf
[root@hw08-server vagrant]# vi /etc/httpd/conf/httpd-2.conf

PidFile /var/run/httpd-2.pid
Listen 8082
ErrorLog "logs/error_log-2"

```
Переводим SELinux в режим Permissive
```
[root@hw08-server vagrant]# setenforce Permissive
```
Запускаем сервисы и проверяем
```
[root@hw08-server vagrant]# systemctl start httpd@1
[root@hw08-server vagrant]# systemctl status httpd@1
● httpd@1.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2022-09-14 15:59:51 UTC; 7s ago
     Docs: man:httpd(8)
           man:apachectl(8)
  Process: 3687 ExecStop=/bin/kill -WINCH ${MAINPID} (code=exited, status=1/FAILURE)
 Main PID: 3707 (httpd)
   Status: "Processing requests..."
   CGroup: /system.slice/system-httpd.slice/httpd@1.service
           ├─3707 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND
           ├─3708 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND
           ├─3709 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND
           ├─3710 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND
           ├─3711 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND
           └─3712 /usr/sbin/httpd -f conf/httpd-1.conf -DFOREGROUND

Sep 14 15:59:51 hw08-server systemd[1]: Starting The Apache HTTP Server...
Sep 14 15:59:51 hw08-server httpd[3707]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Sep 14 15:59:51 hw08-server systemd[1]: Started The Apache HTTP Server.

[root@hw08-server vagrant]# systemctl start httpd@2
[root@hw08-server vagrant]# systemctl status httpd@2
● httpd@2.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2022-09-14 16:00:03 UTC; 3s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3721 (httpd)
   Status: "Processing requests..."
   CGroup: /system.slice/system-httpd.slice/httpd@2.service
           ├─3721 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND
           ├─3722 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND
           ├─3723 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND
           ├─3724 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND
           ├─3725 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND
           └─3726 /usr/sbin/httpd -f conf/httpd-2.conf -DFOREGROUND

Sep 14 16:00:03 hw08-server systemd[1]: Starting The Apache HTTP Server...
Sep 14 16:00:03 hw08-server httpd[3721]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Sep 14 16:00:03 hw08-server systemd[1]: Started The Apache HTTP Server.

[root@hw08-server vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8081                 :::*                   users:(("httpd",pid=3712,fd=4),("httpd",pid=3711,fd=4),("httpd",pid=3710,fd=4),("httpd",pid=3709,fd=4),("httpd",pid=3708,fd=4),("httpd",pid=3707,fd=4))
tcp    LISTEN     0      128      :::8082                 :::*                   users:(("httpd",pid=3726,fd=4),("httpd",pid=3725,fd=4),("httpd",pid=3724,fd=4),("httpd",pid=3723,fd=4),("httpd",pid=3722,fd=4),("httpd",pid=3721,fd=4))

```