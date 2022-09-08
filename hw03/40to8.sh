#!/bin/bash

# Удаляем старый LV 40G и создаем новый на 8G
lvremove /dev/VolGroup00/LogVol00 && lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00

# Создаем файловую систему и монтируем ее в /mnt
mkfs.xfs /dev/VolGroup00/LogVol00 && mount /dev/VolGroup00/LogVol00 /mnt

# Cкопируем все данные с / раздела в /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt

# Проверка
ls /mnt

# Переконфигурируем grub
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

