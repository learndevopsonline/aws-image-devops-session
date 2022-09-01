#!/bin/bash

if [ $(id -u) -ne 0 ]; then
  echo "This script is expected to run as root User"
  exit 1
fi

UPTIME=$(tuptime -sc | grep 'Current uptime' | awk -F\" '{print $8}')
CURRENT_TIME=$(date +%s)
DIFF=$((($CURRENT_TIME - $UPTIME)/60))
if [ $DIFF -gt 150 ]; then
  LOWEST_SESSION_TIME=$(who -s | awk '{ print $2 }' | (cd /dev && xargs stat -c '%X') | sort | head -1)
  DIFF=$((($CURRENT_TIME-$LOWEST_SESSION_TIME)/60))
  if [ $DIFF -gt 150 ]; then
    logger -t "IDLE SCRIPT" -i "Server is idle - Shutting down"
    init 0
fi
