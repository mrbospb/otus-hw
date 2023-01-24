# Description
Тренируем умение работать с SELinux
# How-to
Склонировать репозиторий, поднять ВМ командой `vagrant up`, зафиксировать ошибки запуска nginx на нестандартном порту - permission denied от SELinux
```shell
hw16: Jan 24 20:42:58 hw16 nginx[3967]: nginx: [emerg] bind() to [::]:8088 failed (13: Permission denied)
```
## Запуск nginx на нестандартном порту тремя способами
### Способ 1 - переключатели setsebool
Проверим конфигурацию nginx
```shell 
[root@hw16 vagrant]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
Проверим SELinux
```shell 
[root@hw16 vagrant]# getenforce
Enforcing
```
Найдем в аудите инфо о нашем порту
```shell
[root@hw16 vagrant]# cat /var/log/audit/audit.log | grep 8088
type=AVC msg=audit(1674592978.082:803): avc:  denied  { name_bind } for  pid=3967 comm="nginx" src=8088 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket
```
Анализируем с помощью audit2why
```shell
[root@hw16 vagrant]# cat /var/log/audit/audit.log | grep 8088 | audit2why
type=AVC msg=audit(1674592978.082:803): avc:  denied  { name_bind } for  pid=3967 comm="nginx" src=8088 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket

    Was caused by:
    The boolean nis_enabled was set incorrectly. 
    Description:
    Allow nis to enabled

    Allow access by executing:
    # setsebool -P nis_enabled 1
```
Включаем nis_enabled и перегружаем nginx. Проверяем, что nginx запущен
```shell
[root@hw16 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2023-01-24 20:47:22 UTC; 6s ago
```
Проверим порты nginx'a
```shell 
[root@hw16 vagrant]# ss -tlnp |grep nginx
LISTEN     0      128          *:80                       *:*                   users:(("nginx",pid=4065,fd=6),("nginx",pid=4063,fd=6))
LISTEN     0      128         :::8088                    :::*                   users:(("nginx",pid=4065,fd=7),("nginx",pid=4063,fd=7))
```
Сбросим параметр и проверим его статус
```shell 
[root@hw16 vagrant]# setsebool -P nis_enabled 0

[root@hw16 vagrant]# getsebool -a | grep nis_enabled
nis_enabled --> off
```

### Способ 2 - добавление нестандартного порта в имеющийся тип
Ищем тип для http-трафика
```shell 
semanage port -l | grep http
```
```shell
[root@hw16 vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
Добавим порт в тип http_port_t
```shell 
[root@hw16 vagrant]# semanage port -a -t http_port_t -p tcp 8088
```
Повторим поиск, видим наш порт 
```shell 
http_port_t                    tcp      8088, 80, 81, 443, 488, 8008, 8009, 8443, 9000
```
Перезапустим nginx и проверим, поднялся ли. Видим, что все ок
```shell 
[root@hw16 vagrant]# systemctl restart nginx

[root@hw16 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2023-01-24 20:55:33 UTC; 9s ago
```
Удалим нестандартный порт и убедимся, что nginx не запустится
```shell 
[root@hw16 vagrant]# semanage port -d -t http_port_t -p tcp 8088

[root@hw16 vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

[root@hw16 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2023-01-24 20:56:36 UTC; 16s ago
  Process: 4156 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4185 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 4184 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4158 (code=exited, status=0/SUCCESS)

Jan 24 20:56:36 hw16 systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 24 20:56:36 hw16 nginx[4185]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 24 20:56:36 hw16 nginx[4185]: nginx: [emerg] bind() to [::]:8088 failed (13: Permission denied)
Jan 24 20:56:36 hw16 nginx[4185]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jan 24 20:56:36 hw16 systemd[1]: nginx.service: control process exited, code=exited status=1
Jan 24 20:56:36 hw16 systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Jan 24 20:56:36 hw16 systemd[1]: Unit nginx.service entered failed state.
Jan 24 20:56:36 hw16 systemd[1]: nginx.service failed.

```
### Способ 3 - формирование и установка модуля SELinux
Скомпилируем модуль на основе лог файла аудита, в котором есть информация о запретах
```shell 
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
```
```shell 
[root@hw16 vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```
Применим модуль, перезапустим nginx, смотрим статус
```shell 
[root@hw16 vagrant]# semodule -i nginx.pp

[root@hw16 vagrant]# systemctl restart nginx

[root@hw16 vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2023-01-24 21:03:17 UTC; 5s ago
```

## Обеспечение работоспособности приложения при включенном SELinux
Клонируем [репозиторий](https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems) и поднимаем ВМ.

Подключаемся к client и пытаемся добавить dns зону.
```shell 
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
```
Проверим логи SELinux на клиенте
```shell 
[root@client vagrant]# cat /var/log/audit/audit.log | audit2why
[root@client vagrant]#
```
На клиенте пусто, проверим на сервере
```shell 
[root@ns01 vagrant]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1656910367.573:1927): avc:  denied  { create } for  pid=4214 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
Видим, что используется тип etc_t вместо named_t
Проверим каталог /etc/named
```shell 
[root@ns01 vagrant]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```
Конфиг файлы лежат в другом каталоге.
Чтобы понять, где они должны лежать, используем команду:
```shell 
semanage fcontext -l | grep named
```
```shell 
[root@ns01 vagrant]# semanage fcontext -l | grep named
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0
/etc/unbound(/.*)?                                 all files          system_u:object_r:named_conf_t:s0
```
Изменим тип контекста безопасности для /etc/named:
```shell 
[root@ns01 vagrant]# chcon -R -t named_zone_t /etc/named

[root@ns01 vagrant]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```
Попробуем внести изменения с клиента снова. Все работает.
```shell 
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
```
Проверяем и получаем успешный ответ
```shell 
[root@client vagrant]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.9 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51541
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.               3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 16 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 24 21:23:27 UTC 2023
;; MSG SIZE  rcvd: 96
```
Перезапустим хосты, повторим команду. Видим, что все настройки сохранились, команда проходит.

Возвращаем обратно настройки на DNS-сервере командой
```shell
[root@ns01 vagrant]# restorecon -v -R /etc/named
```

