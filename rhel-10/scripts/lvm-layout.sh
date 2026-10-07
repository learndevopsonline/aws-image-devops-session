#!/bin/bash

## Copy the running RHEL root filesystem onto a second EBS disk laid out like the
## RHEL 9 (SPEL) image: GPT with BIOS + UEFI boot, /boot, and LVM RootVG volumes.
## Run as root on the build instance:  bash lvm-layout.sh <ebs-volume-id>
set -euo pipefail

VOLID=${1:?usage: lvm-layout.sh <ebs-volume-id>}
SERIAL=${VOLID/-/}
DISK=/dev/$(lsblk -dno NAME,SERIAL | awk -v s="$SERIAL" '$2==s {print $1}')
if [ "$DISK" == "/dev/" ]; then
  echo "Disk for $VOLID not found" ; exit 1
fi
P=${DISK}p
T=/mnt/target
echo "Target disk: $DISK"

dnf install -y lvm2 rsync dosfstools xfsprogs grub2-pc grub2-pc-modules grub2-efi-x64 shim-x64

## Partitions (same as RHEL 9 image, /boot raised to 1G for RHEL 10 kernels)
wipefs -a $DISK
parted -s $DISK mklabel gpt \
  mkpart primary 1MiB 2MiB set 1 bios_grub on \
  mkpart primary fat16 2MiB 124MiB set 2 esp on \
  mkpart primary xfs 124MiB 1148MiB \
  mkpart primary 1148MiB 100% set 4 lvm on
udevadm settle

mkfs.vfat -F 16 -n UEFI_DISK ${P}2
mkfs.xfs -f -L boot_disk ${P}3

## LVM volumes
pvcreate -ff -y ${P}4
vgcreate RootVG ${P}4
lvcreate -y -L 6G -n rootVol   RootVG
lvcreate -y -L 2G -n swapVol   RootVG
lvcreate -y -L 1G -n homeVol   RootVG
lvcreate -y -L 2G -n varVol    RootVG
lvcreate -y -L 2G -n varTmpVol RootVG
lvcreate -y -L 2G -n logVol    RootVG
lvcreate -y -l 100%FREE -n auditVol RootVG
for lv in rootVol homeVol varVol varTmpVol logVol auditVol; do
  mkfs.xfs -f /dev/mapper/RootVG-$lv
done
mkswap /dev/mapper/RootVG-swapVol

## Mount target tree
mkdir -p $T
mount /dev/mapper/RootVG-rootVol $T
mkdir -p $T/boot $T/home $T/var
mount ${P}3 $T/boot
mkdir -p $T/boot/efi
mount ${P}2 $T/boot/efi
mount /dev/mapper/RootVG-homeVol $T/home
mount /dev/mapper/RootVG-varVol $T/var
mkdir -p $T/var/tmp $T/var/log
mount /dev/mapper/RootVG-varTmpVol $T/var/tmp
mount /dev/mapper/RootVG-logVol $T/var/log
mkdir -p $T/var/log/audit
mount /dev/mapper/RootVG-auditVol $T/var/log/audit

## Copy the running system
rsync -aAXHx --numeric-ids / $T/
rsync -aAXHx --numeric-ids /boot/ $T/boot/
rsync -rt /boot/efi/ $T/boot/efi/
chmod 1777 $T/var/tmp

cat >$T/etc/fstab <<EOF
/dev/mapper/RootVG-rootVol   /              xfs   defaults,rw  0 0
/dev/mapper/RootVG-homeVol   /home          xfs   defaults,rw  0 0
/dev/mapper/RootVG-varVol    /var           xfs   defaults,rw  0 0
/dev/mapper/RootVG-logVol    /var/log       xfs   defaults,rw  0 0
/dev/mapper/RootVG-auditVol  /var/log/audit xfs   defaults,rw  0 0
/dev/mapper/RootVG-varTmpVol /var/tmp       xfs   defaults,rw  0 0
/dev/mapper/RootVG-swapVol   none           swap  defaults     0 0
LABEL=boot_disk              /boot          xfs   defaults,rw  0 0
LABEL=UEFI_DISK              /boot/efi      vfat  defaults,rw,umask=0077,shortname=winnt 0 0
EOF

## LVM devices file pins disk IDs of the build host; scan all disks instead
rm -f $T/etc/lvm/devices/system.devices
sed -i -e 's/^\s*#\?\s*use_devicesfile = .*/\tuse_devicesfile = 0/' $T/etc/lvm/lvm.conf
grep -q '^\s*use_devicesfile = 0' $T/etc/lvm/lvm.conf

## Bootloader + initramfs inside the new tree
for d in dev proc sys run; do mount --bind /$d $T/$d; done

CMDLINE="root=/dev/mapper/RootVG-rootVol rd.lvm.lv=RootVG/rootVol rd.lvm.lv=RootVG/swapVol"
chroot $T grubby --update-kernel=ALL --remove-args="root resume" --args="$CMDLINE"
[ -f $T/etc/kernel/cmdline ] && chroot $T sh -c "sed -i -e 's/root=[^ ]*//' /etc/kernel/cmdline && sed -i -e 's|^|$CMDLINE |' /etc/kernel/cmdline"
sed -i -e '/^GRUB_CMDLINE_LINUX=/ s/root=[^ "]*//' -e "/^GRUB_CMDLINE_LINUX=/ s|=\"|=\"$CMDLINE |" $T/etc/default/grub

for kver in $(ls $T/lib/modules); do
  chroot $T dracut -f --no-hostonly --add lvm /boot/initramfs-$kver.img $kver
done

chroot $T grub2-install --target=i386-pc $DISK
BOOT_UUID=$(blkid -s UUID -o value ${P}3)
cat >$T/boot/efi/EFI/redhat/grub.cfg <<EOF
search --no-floppy --fs-uuid --set=dev $BOOT_UUID
set prefix=(\$dev)/grub2

export \$prefix
configfile \$prefix/grub.cfg
EOF
chroot $T grub2-mkconfig -o /boot/grub2/grub.cfg

## Relabel SELinux contexts on first boot from the new disk
touch $T/.autorelabel

echo "--- kernel entries"
chroot $T grubby --info=ALL | grep -E '^(kernel|args)'
lsblk $DISK

## Unmount
for d in run sys proc dev; do umount $T/$d; done
umount $T/var/log/audit $T/var/log $T/var/tmp $T/var $T/home $T/boot/efi $T/boot $T
vgchange -an RootVG
sync
echo "LVM layout ready on $DISK"
