#!/bin/bash

# Скачиваем файл
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O /tmp/otus_task2.file

# Создаем пул
zpool create snappool /dev/sde

# Проверка
zpool list

# Разворачиваем снэпшот
zfs receive snappool/tmp < /tmp/otus_task2.file
zfs list -t snapshot
zfs rollback snappool/tmp@task2

# Ищем секретный файл
find /snappool/tmp -iname "secret_message"
