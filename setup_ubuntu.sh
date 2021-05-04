#!/bin/bash -eu

MNTDIR='arm64'

mkdir -p ${MNTDIR}
sudo debootstrap --foreign --arch arm64 bionic ${MNTDIR} http://ports.ubuntu.com/
sudo cp ubuntu_chroot.sh ${MNTDIR}
sudo cp /usr/bin/qemu-aarch64-static ${MNTDIR}/usr/bin/
sudo cp /run/systemd/resolve/stub-resolv.conf ${MNTDIR}/etc/resolv.conf
sudo mount --bind /dev/  ${MNTDIR}/dev
sudo mount --bind /proc/ ${MNTDIR}/proc
sudo mount --bind /sys/  ${MNTDIR}/sys
sudo chroot ${MNTDIR} bash ./ubuntu_chroot.sh
