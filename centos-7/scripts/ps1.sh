#!/bin/bash

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "${PUBLIC_IP}" ]; then
  PUBLIC_IP=null
fi
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
export PS1="
\e[1;32m${PUBLIC_IP} | ${PRIVATE_IP} | ${INSTANCE_TYPE}
[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]\h\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "