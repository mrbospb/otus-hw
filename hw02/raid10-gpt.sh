#!/bin/bash

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

yum install -y mdadm gdisk

#mdadm --zero-superblock --force /dev/sd[b-i]
mdadm --create --verbose /dev/md/raid10 --level=10 --raid-devices=8 /dev/sd[b-i]

sgdisk -n 1:0:1G /dev/md/raid10

mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf && mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

for i in {1..5} ; do
	sgdisk -n ${i}:0:+100M /dev/sdc ;
done
lsblk

mkdir /mnt/raid10
mkfs /dev/md/raid10p*
sleep 10
mount /dev/md/raid10p1 /mnt/raid10
df -h

echo "/dev/md/raid10p1 /mnt/raid10 ext4 defaults 0 0" >> /etc/fstab