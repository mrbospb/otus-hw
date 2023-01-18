#!/bin/bash

ADMIN_TEMPLATE=".*admin.*"

if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
    if [[ $(id -Gn $PAM_USER) =~ $ADMIN_TEMPLATE ]]; then
        exit 0
    else
        exit 1
    fi
fi
