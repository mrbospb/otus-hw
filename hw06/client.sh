#!/bin/bash

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

# Установка софта
yum install nfs-utils -y

# Включаем firewall
systemctl enable firewalld --now
systemctl status firewalld

# Добавляем монтирование
echo "192.168.56.11:/srv/nfs/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

systemctl daemon-reload

systemctl restart remote-fs.target