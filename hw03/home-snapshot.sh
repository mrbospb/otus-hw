#!/bin/bash

# Выделим том под /home и примонтируем его
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/

# Правим fstab для автоматического монтирования /home
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

# Генерируем файлы
touch /home/file{1..20}

# Делаем снэпшот
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home

# Проверка
ls -al /home

# Удаляем файлы
rm -f /home/file{11..20}

# Проверка
ls -al /home

# Восстанавливаем снэпшот
umount /home
lvconvert --merge /dev/VolGroup00/home_snap
mount /home

# Проверка
ls -al /home
