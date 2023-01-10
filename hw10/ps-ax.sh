#!/bin/bash

pid_func()
{
    awk '{print $1}' /proc/$i/stat
}

tty_func()
{
    if [[ $(awk '{print $7}' /proc/$i/stat) = 0 ]]
        then
            echo "?"
        else
            ls -l /proc/$i/fd | grep -E 'tty|pts' | cut -d\/ -f3,4 | uniq | head -1
    fi
}

stat_func()
{
    grep State /proc/$i/status | awk '{print $2}'
}

time_func()
{
    sec=$(( $(awk '{print $14}' /proc/$i/stat)+$(awk '{print $15}' /proc/$i/stat) / 100 ))
    date -u -d @${sec} +"%-M:%S"
}

command_func()
{
    CMD=$(tr -d '\0' </proc/$i/cmdline)
    if [ -z "$CMD" ]
        then
            echo "[$(cat /proc/$i/comm)]"
        else
            echo "$(cat /proc/$i/cmdline | tr '\000' ' ')"
    fi
}

main_func()
{
    PID=$*
    for i in $PID
    do
        if [[ -e /proc/$i/stat ]]
            then
                echo -e "$(pid_func)\t$(tty_func)\t$(stat_func)\t$(time_func)\t$(command_func)"
        fi
    done
}

PID=$(ls /proc | grep [[:digit:]] | sort -n | xargs)
echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"
main_func $PID
