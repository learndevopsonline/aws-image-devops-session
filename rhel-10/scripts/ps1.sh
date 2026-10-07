#!/bin/bash

GIT_URL=$(git config --get remote.origin.url)
[ -z "${GIT_URL}" ] && GIT_URL=null
curl -f -s http://169.254.169.254/latest/meta-data/public-ipv4 &>/dev/null
if [ $? -eq 0 ]; then
  PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
else
  PUBLIC_IP=null
fi
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
export PS1="
\e[1;32m${PUBLIC_IP} | ${PRIVATE_IP} | ${INSTANCE_TYPE} | \$(git config --get remote.origin.url || echo null)
[ \[\e[1;31m\]\u\[\e[m\]@\[\e[1;33m\]\h\[\e[m\] \[\e[1;36m\]\w\[\e[m\] ]\\$ "
