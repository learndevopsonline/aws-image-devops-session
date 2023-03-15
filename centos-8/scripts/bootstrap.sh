#!/bin/bash

curl -s -L https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-8/scripts/boot-env.sh -o /etc/profile.d/boot-env.sh
chmod +x /etc/profile.d/boot-env.sh
