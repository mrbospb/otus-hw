#!/bin/bash

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

# Установка софта
yum install nfs-utils -y

# Включаем и настраиваем firewall
systemctl enable firewalld --now
    systemctl status firewalld
    firewall-cmd --add-service="nfs3" \
    --add-service="rpc-bind" \
    --add-service="mountd" \
    --permanent
    firewall-cmd --reload

# Добавляем NFS 
systemctl enable nfs --now

# Создаем директории
mkdir -p /srv/nfs/upload
chmod 0777 /srv/nfs/upload

# Прописываем экспортируемые fs
cat << EOF > /etc/exports
/srv/nfs 192.168.56.22/32(rw,sync,root_squash)
EOF

exportfs -r