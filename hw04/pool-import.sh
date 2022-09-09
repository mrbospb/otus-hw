#!/bin/bash

# Скачиваем файл
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O /tmp/zfs_task1.tar.gz
tar xvf /tmp/zfs_task1.tar.gz -C /tmp

# Проверка возможности импорта
zpool import -d zpoolexport/

# Импорт
zpool import -d zpoolexport/ otus

# Проверка
zpool status otus

# Собираем нужную информацию
zpool list -o name,size otus
zfs get available,recordsize,compression,checksum otus