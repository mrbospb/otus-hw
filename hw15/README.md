# Description
Настраиваем центральный сервер для сбора логов
# How-to
Склонировать репозиторий, поднять ВМ командой `vagrant up`
## Центральный лог сервер на rsyslog
Vagrant поднимет две машины на centos7: web и log
Установим один часовой пояс на обоих серверах
```
[root@log ~]# date
Thu Jan 19 20:07:08 UTC 2023
[root@log ~]# mv /etc/localtime /etc/localtime.bak
[root@log ~]# ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
[root@log ~]# systemctl restart chronyd
[root@log ~]# systemctl status chronyd
● chronyd.service - NTP client/server
   Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2023-01-19 23:07:24 MSK; 6s ago
     Docs: man:chronyd(8)
           man:chrony.conf(5)
  Process: 3542 ExecStartPost=/usr/libexec/chrony-helper update-daemon (code=exited, status=0/SUCCESS)
  Process: 3538 ExecStart=/usr/sbin/chronyd $OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 3540 (chronyd)
   CGroup: /system.slice/chronyd.service
           └─3540 /usr/sbin/chronyd

Jan 19 23:07:24 log systemd[1]: Starting NTP client/server...
Jan 19 23:07:24 log chronyd[3540]: chronyd version 3.2 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP...EBUG)
Jan 19 23:07:24 log chronyd[3540]: Frequency 10.502 +/- 5.820 ppm read from /var/lib/chrony/drift
Jan 19 23:07:24 log systemd[1]: Started NTP client/server.
Jan 19 23:07:31 log chronyd[3540]: Selected source 79.111.152.5
Hint: Some lines were ellipsized, use -l to show in full.
[root@log ~]# 
[root@log ~]# date
Thu Jan 19 23:07:36 MSK 2023
```
Установим nginx
```
[root@web ~]# yum install -y epel-release
[root@web ~]# yum install -y nginx
[root@web ~]# systemctl start nginx
[root@web ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 23:10:49 MSK; 2s ago
  Process: 3681 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3679 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3678 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3683 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3683 nginx: master process /usr/sbin/nginx
           └─3685 nginx: worker process
Jan 19 23:10:49 web systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 19 23:10:49 web nginx[3679]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 19 23:10:49 web nginx[3679]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 19 23:10:49 web systemd[1]: Started The nginx HTTP and reverse proxy server.

[root@web ~]# systemctl enable nginx
Created symlink from /etc/systemd/system/multi-user.target.wants/nginx.service to /usr/lib/systemd/system/nginx.service.

[root@web ~]# ss -tlpn | grep nginx
LISTEN     0      128          *:80                       *:*                   users:(("nginx",pid=3685,fd=6),("nginx",pid=3683,fd=6))
LISTEN     0      128         :::80                      :::*                   users:(("nginx",pid=3685,fd=7),("nginx",pid=3683,fd=7))
```
Настроим сервер логов

Проверим наличие rsyslog
```
[root@log ~]# yum list rsyslog
Failed to set locale, defaulting to C
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.docker.ru
 * extras: mirror.docker.ru
 * updates: mirror.docker.ru
base                                                                                   | 3.6 kB  00:00:00     
extras                                                                                 | 2.9 kB  00:00:00     
updates                                                                                | 2.9 kB  00:00:00     
(1/4): base/7/x86_64/group_gz                                                          | 153 kB  00:00:00     
(2/4): extras/7/x86_64/primary_db                                                      | 249 kB  00:00:00     
(3/4): base/7/x86_64/primary_db                                                        | 6.1 MB  00:00:02     
(4/4): updates/7/x86_64/primary_db                                                     |  19 MB  00:00:04     
Installed Packages
rsyslog.x86_64                                   8.24.0-16.el7                                       @anaconda
Available Packages
rsyslog.x86_64                                   8.24.0-57.el7_9.3                                   updates 
```
Внесем изменения в /etc/rsyslog.conf
```
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
```
Перезапустим службу и проверим, что порты 514 прослушиваются
```
[root@log ~]# systemctl restart rsyslog
[root@log ~]# ss -tuln | grep 514
udp    UNCONN     0      0         *:514                   *:*
udp    UNCONN     0      0      [::]:514                [::]:*
tcp    LISTEN     0      25        *:514                   *:*
tcp    LISTEN     0      25     [::]:514                [::]:*
```
Настроим отправку логов на web-сервере. Отредактируем конфиг nginx. Находим в файле /etc/nginx/nginx.conf раздел с логами и приводим их к следующему виду:
```
error_log /var/log/nginx/error.log;
error_log syslog:server=192.168.56.5:514,tag=nginx_error debug;

access_log /var/log/nginx/access.log  main;
access_log syslog:server=192.168.56.5:514,tag=nginx_access,severity=info combined;
```
Перезапустим nginx
```
[root@web ~]# vi /etc/nginx/nginx.conf
[root@web ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web ~]# systemctl restart nginx
[root@web ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 23:35:46 MSK; 7s ago
  Process: 3931 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3929 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3928 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3933 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3933 nginx: master process /usr/sbin/nginx
           └─3934 nginx: worker process

Jan 19 23:35:46 web systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 19 23:35:46 web nginx[3929]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 19 23:35:46 web nginx[3929]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 19 23:35:46 web systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Смотрим логи на log-сервере
```
[root@log ~]# tail /var/log/rsyslog/web/nginx_error.log 
Jan 19 23:41:24 web nginx_error: 2023/01/19 23:41:24 [debug] 3934#3934: *5 recv: fd:3 0 of 1024
Jan 19 23:41:24 web nginx_error: 2023/01/19 23:41:24 [info] 3934#3934: *5 client 192.168.56.5 closed keepalive connection
Jan 19 23:41:24 web nginx_error: 2023/01/19 23:41:24 [debug] 3934#3934: *5 close http connection: 3
Jan 19 23:41:24 web nginx_error: 2023/01/19 23:41:24 [debug] 3934#3934: *5 event timer del: 3: 3011452
```
## Настройка аудита, следящего за изменением конфигов nginx
### Локальный сбор логов
Проверяем наличие утилиты audit
```
[root@web ~]# rpm -qa | grep audit
audit-2.8.1-3.el7.x86_64
audit-libs-2.8.1-3.el7.x86_64
```
Отредактируем /etc/audit/rules.d/audit.rules, добавим в конце:
```
[root@web ~]# vi /etc/audit/rules.d/audit.rules

-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
```
Перезапустим сервис auditd
```
[root@web ~]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```
Внесем изменения в nginx.conf и проверим, записалось ли это событие в audit
```
[root@web ~]# tail /var/log/audit/audit.log | grep nginx
type=SYSCALL msg=audit(1674162687.804:1000): arch=c000003e syscall=90 success=yes exit=0 a0=223f9d0 a1=81a4 a2=0 a3=24 items=1 ppid=3531 pid=4231 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=5 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
type=PATH msg=audit(1674162687.804:1000): item=0 name="/etc/nginx/nginx.conf" inode=100667079 dev=fd:00 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=SYSCALL msg=audit(1674162687.804:1001): arch=c000003e syscall=188 success=yes exit=0 a0=223f9d0 a1=7fdf7106fddf a2=224f450 a3=1c items=1 ppid=3531 pid=4231 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=5 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
```
### Удаленный сбор логов
Для отправки логов на удаленный сервер требуется добавить пакет audispd-plugins.

Изменим в файле /etc/audit/auditd.conf параметр name_format на HOSTNAME, чтобы в логах отображалось имя хоста.

В файле /etc/audisp/plugins.d/au-remote.conf поменяем параметр active на yes.

В файле /etc/audisp/audisp-remote.conf укажем адрес сервера log:`remote_server = 192.168.56.5` и перезапустим сервис.

На сервере log раскомментируем строку `tcp_listen_port = 60` в файле /etc/audit/auditd.conf и перезапустим сервис auditd.

Для проверки делаем файл nginx.conf на сервере web исполняемым и фиксируем новые записи в логе аудита на сервере log
```
[root@log ~]# tail -f /var/log/audit/audit.log 
node=web type=CWD msg=audit(1674164608.692:1023):  cwd="/root"
node=web type=PATH msg=audit(1674164608.692:1023): item=0 name="/etc/nginx/nginx.conf" inode=100667079 dev=fd:00 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1674164608.692:1023): proctitle=63686D6F64002B78002F6574632F6E67696E782F6E67696E782E636F6E66
```



