#!/bin/bash

## Remove the /var/log/audit LVM volume (SPEL layout) and give its space to /home.
## /var/log/audit becomes a plain directory on the /var/log volume.
set -euo pipefail

if ! lvs RootVG/auditVol &>/dev/null; then
  echo "No RootVG/auditVol, nothing to do"
  exit 0
fi

service auditd stop

mkdir -p /root/audit-copy
cp -a /var/log/audit/. /root/audit-copy/
umount /var/log/audit
sed -i -e '/RootVG-auditVol/ d' /etc/fstab
systemctl daemon-reload
cp -a /root/audit-copy/. /var/log/audit/
rm -rf /root/audit-copy
chmod 700 /var/log/audit

lvremove -y RootVG/auditVol
lvextend -l +100%FREE RootVG/homeVol
xfs_growfs /home

service auditd start
lsblk -o NAME,SIZE,MOUNTPOINT
