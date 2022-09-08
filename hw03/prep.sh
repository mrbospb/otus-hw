#!/bin/bash

# Установка софта
yum install -y mdadm smartmontools hdparm gdisk xfsdump # multipath busybox cryptsetup dmraid ntfs-3g

# Готовим временный том под /
pvcreate /dev/sdb && vgcreate vg_root /dev/sdb && lvcreate -n lv_root -l +100%FREE /dev/vg_root

# Создаем файловую систему и монтируем ее в /mnt
mkfs.xfs /dev/vg_root/lv_root && mount /dev/vg_root/lv_root /mnt

# Cкопируем все данные с / раздела в /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

# Проверка
ls /mnt

# Переконфигурируем grub, чтобы при старте перейти в новый /
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg

# Обновим образ initrd
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

# Замена строки в файле
sed 's/d.lvm.lv=VolGroup00\/LogVol00/d.lvm.lv=vg_root\/lv_root/' /boot/grub2/grub.cfg 

# Презагрузим
reboot