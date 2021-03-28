#!/bin/bash

if [ $(id -u) -ne 0 ]; then
   echo -e "\e[33m You should run this as root user\e[0m"
   exit 1
fi

sed -i -e '/idle/ d' /var/spool/cron/root &>/dev/null
echo "*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out" >>/var/spool/cron/root