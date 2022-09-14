# Description
Vagrantfile from hw03.
# How-to
Use `vagrant up` to start VM
# Log
## Попасть в систему без пароля несколькими способами
### 1. Загрузка системы в аварийном режиме
Перезагружаем машину и при появлении меню загрузки системы нажимаем клавишу е.
В конце строки, начинающейся с linux16, удаляем с конца все параметры по умолчанию до `ro` дописываем `rd.break` и нажимаем СTRL+x.
После загрузки системы в аварийном режиме выполняем команду перемонтирования корневого каталога `mount -o remount,rw /sysroot`, затем `chroot /sysroot`.
Теперь мы можем поменять пароль командой `passwd root`.
Создаём скрытый файл переиндексации при загрузке системы `touch /.autorelabel`, чтобы SElinux не ругался.
Перемонтируем корневой каталог в read-only `mount -o remount,ro /sysroot`.
### 2. Смена процесса
Так же попадаем в меню Grub, но в конце строки, начинающейся с linux16, дописываем `init=/bin/sh` и нажимаем СTRL+x. Тем самым мы грузимся сразу в рутовую консоль. Перемонтируем файловую систему в read-write. Далее порядок смены пароля тот же.
## Установить систему с LVM, после чего переименовать VG
Проверяем, какие volume group есть
```
[root@lvm vagrant]# vgscan
  Reading volume groups from cache.
  Found volume group "VolGroup00" using metadata type lvm2
```
Переименовываем имеющуюся
```
[root@lvm vagrant]# vgrename VolGroup00 VolGroup01
  Volume group "VolGroup00" successfully renamed to "VolGroup01"
[root@lvm vagrant]# vgscan
  Reading volume groups from cache.
  Found volume group "VolGroup01" using metadata type lvm2
```
Также переименовываем в файлах
```
[root@lvm vagrant]# sed -i -e "s/VolGroup00/VolGroup01/g" /etc/fstab
[root@lvm vagrant]# sed -i -e "s/VolGroup00/VolGroup01/g" /etc/default/grub
[root@lvm vagrant]# sed -i -e "s/VolGroup00/VolGroup01/g" /boot/grub2/grub.cfg
```
Пересоздаем initrd image
```
[root@lvm vagrant]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
Executing: /sbin/dracut -f -v /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64
...
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```
Перезагружаемся и проверяем
```
[root@lvm vagrant]# reboot now
[root@lvm vagrant]# vgscan
  Reading volume groups from cache.
  Found volume group "VolGroup01" using metadata type lvm2
```
## Добавить модуль в initrd
Чтобы добавить свой модуль создаем директорию
```
[root@lvm vagrant]# mkdir /usr/lib/dracut/modules.d/01otus-boot
```
Создаем скрипт `module-setup.sh`
```
[root@lvm vagrant]# vi /usr/lib/dracut/modules.d/01otus-boot/module-setup.sh
```
```
#!/bin/bash

check() { # Функция, которая указывает что модуль должен быть включен по умолчанию
    return 0
}

depends() { # Выводит все зависимости от которых зависит наш модуль
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh" # Запускает скрипт
}

```
Создаем скрипт `penguin.sh`
```
[root@lvm vagrant]# vi /usr/lib/dracut/modules.d/01otus-boot/penguin.sh
```
```
#!/bin/bash

cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```
Делаем их исполняемыми
```
[root@lvm vagrant]# chmod +x /usr/lib/dracut/modules.d/01otus-boot/module-setup.sh
[root@lvm vagrant]# chmod +x /usr/lib/dracut/modules.d/01otus-boot/penguin.sh
```
Пересобираем образ initrd
```
[root@lvm vagrant]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
Executing: /sbin/dracut -f -v /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64
...
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```
Проверка
```
[root@lvm vagrant]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep otus
otus-boot
```
При перезагрузке видим пингвина.