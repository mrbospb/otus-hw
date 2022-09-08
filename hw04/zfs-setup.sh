#!/bin/bash

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

# Установка в AlmaLinux8
yum install -y yum-utils

dnf install -y https://zfsonlinux.org/epel/zfs-release-2-2$( rpm --eval "%{dist}" ).noarch.rpm

yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod

yum repolist --enabled | grep zfs && echo ZFS repo enabled

yum install -y zfs wget

modprobe zfs
