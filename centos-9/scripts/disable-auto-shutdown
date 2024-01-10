#!/bin/bash

if [ $(id -u) -ne 0 ]; then
   echo -e "\e[33m You should run this as root user\e[0m"
   exit 1
fi

sed -i -e '/idle/ d' /var/spool/cron/root