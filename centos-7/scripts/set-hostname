#!/bin/bash

if [ $1 == "-skip-apply" ]; then
  HOST_NAME=$2
else
  HOST_NAME=$1
fi
if [ -z "$1" ]; then
  echo -e "Give Hostname as Input"
  exit 1
fi

if [ $(id -u) -ne 0 ]; then
  echo "You should be root user to execute this!!"
  exit 1
fi

sed -i -e '/^export/,$ d' /etc/profile.d/ps1.sh
echo 'export PS1="
\e[1;32m${PUBLIC_IP} | ${PRIVATE_IP} | ${INSTANCE_TYPE} | \$(git config --get remote.origin.url || echo null)
[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]HOST_NAME\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "'>>/etc/profile.d/ps1.sh
#echo 'export PS1="
#\e[1;32m${PUBLIC_IP} | ${PRIVATE_IP} | ${INSTANCE_TYPE}
#[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]HOST_NAME\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "' >>/etc/profile.d/ps1.sh
#echo 'export PS1="[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]HOST_NAME\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "' >/etc/profile.d/ps1.sh
sed -i -e "s/HOST_NAME/${HOST_NAME}/" /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh
if [ $1 == "-skip-apply" ]; then
  exit
fi
echo ${SUDO_COMMAND} | grep python &>/dev/null
if [ $? -ne 0 ]; then
  if [ -z "${SUDO_USER}" ]; then
    su -
  else
    su - ${SUDO_USER}
  fi
fi
