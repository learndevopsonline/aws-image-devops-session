#!/bin/bash

HOST_NAME=$1
if [ -z "$1" ]; then
  echo -e "Give Hostname as Input"
  exit 1
fi

if [ $(id -u) -ne 0 ]; then
  echo "You should be root user to execute this!!"
  exit 1
fi

echo 'export PS1="[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]HOST_NAME\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "' >/etc/profile.d/ps1.sh
sed -i -e "s/HOST_NAME/${HOST_NAME}/" /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh
