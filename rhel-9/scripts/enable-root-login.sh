#!/bin/bash

## Allow root/ec2-user SSH login with password on an already built image
## (sshd_config is locked with chattr +i by ami-setup.sh)
set -euo pipefail

FILES="/etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf"
chattr -i $FILES
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^#\?PermitRootLogin/ c PermitRootLogin yes' $FILES
chattr +i $FILES
sshd -t
systemctl restart sshd
sshd -T | grep -iE '^(permitrootlogin|passwordauthentication)'
