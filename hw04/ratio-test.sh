#!/bin/bash

# Создаем пул
zpool create labpool mirror sdb sdc

# Проверка
zpool status

# Создаем файловые системы с заданными уровнями компрессии
for i in gzip-1 gzip gzip-9 zle lzjb lz4; do zfs create labpool\/fs_$i  &&  zfs set compression=$i labpool\/fs_$i ;  done

# Проверка
zfs list

# Скачиваем файл для теста
wget -O /tmp/WaP.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8

# Копируем его 
for i in gzip-1 gzip gzip-9 zle lzjb lz4; do cp /tmp/WaP.txt \/labpool\/fs_$i ; done

# Вывод с сортировкой по занятому месту
zfs list -o name,compression,compressratio,used -s used