#!/bin/bash

# На свободных дисках создаем зеркало
pvcreate /dev/sdc /dev/sdd && vgcreate vg_var /dev/sdc /dev/sdd && lvcreate -L 950M -m1 -n lv_var vg_var

# Создаем на нем ФС
mkfs.ext4 /dev/vg_var/lv_var && mount /dev/vg_var/lv_var /mnt

# Перемещаем туда /var
cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/

# Бэкапим старый var
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar

# Монтируем новый var в каталог /var
umount /mnt && mount /dev/vg_var/lv_var /var

# Правим fstab для автоматического монтирования /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab

#
reboot now

# Удаляем временную VG
lvremove /dev/vg_root/lv_root && vgremove /dev/vg_root && pvremove /dev/sdb