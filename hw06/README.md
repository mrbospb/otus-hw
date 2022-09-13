# Description
Vagrantfile and scripts from hw05.
Vagrant creates 2 VM's (server and client) with NFS folder `/srv/nfs/upload/`
# How-to
Use `vagrant up` to start VM's
# Log
## Собрать свой пакет
### Заходим на server
`bo@vivobo:~/otus/otus-hw/hw06$ vagrant ssh server`
### Устанавливаем необходимое ПО
`[vagrant@hw06-server ~]$ sudo bash`
`[root@hw06-server ~]$ yum install wget rpm-build rpmdevtools openssl-devel zlib-devel pcre-devel gcc make perl-devel perl-ExtUtils-Embed GeoIP-devel libxslt-devel gd-devel -y`
### Создаем пользователя для сборки
`[root@hw06-server ~]$ useradd builder`
`[root@hw06-server ~]$ su builder`
### Создаем структуру директорий для сборки
`[builder@hw06-server ~]$ rpmdev-setuptree`
`[builder@hw06-server ~]$ cd rpmbuild/`
### Скачиваем исходник nginx и ставим его
`[builder@hw06-server rpmbuild]$ wget http://nginx.org/packages/mainline/centos/7/SRPMS/nginx-1.11.0-1.el7.ngx.src.rpm`
`[builder@hw06-server rpmbuild]$ rpm -Uvh nginx-1.11.0-1.el7.ngx.src.rpm`
### Правим конфиг
`[builder@hw06-server rpmbuild]$ vi SOURCES/nginx.conf`

```
events {
    worker_connections  2048;
}
```
### Запускаем сборку
`[builder@hw06-server rpmbuild]$ rpmbuild -bb SPECS/nginx.spec`
### Копируем готовый файл в расшаренную директорию
`[builder@hw06-server rpmbuild]$ cp rpmbuild/RPMS/x86_64/nginx-1.11.0-1.el7.centos.ngx.x86_64.rpm /srv/nfs/upload/`
### Заходим на client
`bo@vivobo:~/otus/otus-hw/hw06$ vagrant ssh client`
### Переходим в папку с пакетом
`[vagrant@hw06-client ~]$ cd /mnt/upload/`
`[vagrant@hw06-client upload]$ ll`
```
total 644
-rw-rw-r--. 1 1001 1001 657608 Sep 13 12:34 nginx-1.11.0-1.el7.centos.ngx.x86_64.rpm
```
### Устанавливаем
`[vagrant@hw06-client upload]$ sudo rpm -Uvh nginx-1.11.0-1.el7.centos.ngx.x86_64.rpm`
```
Preparing...                          ################################# [100%]
Updating / installing...
  1:nginx-1:1.11.0-1.el7.centos.ngx  ################################# [100%]
----------------------------------------------------------------------

Thanks for using nginx!

Please find the official documentation for nginx here:
* http://nginx.org/en/docs/

Commercial subscriptions for nginx are available on:
* http://nginx.com/products/

----------------------------------------------------------------------
```
### Проверяем измененный параметр
`[vagrant@hw06-client upload]$ cat /etc/nginx/nginx.conf | grep worker_connections`
`  worker_connections  2048;`
## Создать свой репозиторий и разместить там свой RPM
### Установим утилиту createrepo
`[root@hw06-server ~]$ yum install createrepo`
### Создаем репозиторий в директории, где лежит rpm файл
```
[root@hw06-server ~]# cd /home/builder/rpmbuild/RPMS/x86_64/
[root@hw06-server x86_64]# createrepo .
Spawning worker 0 with 1 pkg
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```
### Видим созданный каталог repodata. Создание репозитория завершено
```
[root@hw06-server x86_64]# ll
-rw-rw-r--. 1 builder builder  657608 Sep 13 12:33 nginx-1.11.0-1.el7.centos.ngx.x86_64.rpm
drwxr-xr-x. 2 root    root       4096 Sep 13 12:57 repodata
```
