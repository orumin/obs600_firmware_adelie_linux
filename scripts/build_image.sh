#!/bin/bash

IMAGE_ROOT=$1
DISTS=$2
TARBALL_PATH=$3

if [ ! -d $IMAGE_ROOT ] || [ ! -d $DISTS ] || [ ! -e $TARBALL_PATH ]; then
    echo ""
    echo "$0: invalid argument"
    echo ""
    exit 1;
fi

tar --numeric-owner -xpvJf ${TARBALL_PATH} -C ${IMAGE_ROOT}

install -m 644 -o root -g root ${DISTS}/etc/apk/world ${IMAGE_ROOT}/etc/apk
install -m 644 -o root -g root ${DISTS}/etc/conf.d/{gettys,hostname,net} ${IMAGE_ROOT}/etc/conf.d
install -m 644 -o root -g root ${DISTS}/etc/default/openblocks ${IMAGE_ROOT}/etc/default
install -m 644 -o root -g root ${DISTS}/etc/{fstab,hostname,hosts} ${IMAGE_ROOT}/etc
install -m 640 -o root -g root ${DISTS}/etc/shadow ${IMAGE_ROOT}/etc
install -m 755 -o root -g root ${DISTS}/etc/init.d/{openblocks-setup,pshd,runled,umountfs} ${IMAGE_ROOT}/etc/init.d
install -m 755 -o root -g root ${DISTS}/etc/ssh/sshd_config ${IMAGE_ROOT}/etc/ssh
install -m 755 -o root -g root ${DISTS}/etc/s6-linux-init/current/run-image/service/s6-linux-init-early-getty/run \
    ${IMAGE_ROOT}/etc/s6-linux-init/current/run-image/service/s6-linux-init-early-getty/

install -m 644 -o root -g root ${DISTS}/lib/apk/db/installed ${IMAGE_ROOT}/lib/apk/db

install -m 755 -o root -g root ${DISTS}/usr/sbin/flashcfg ${IMAGE_ROOT}/usr/sbin

cd ${IMAGE_ROOT}/dev && \
    mknod -m 640 mem c 1 1 && \
    mknod -m 640 kmem c 1 2 && \
    mknod -m 640 port c 1 4 && \
    mknod -m 622 console c 5 1 && \
    mknod -m 666 zero c 1 5 && \
    mknod -m 666 full c 1 7 && \
    mknod -m 666 ptmx c 5 2 && \
    mknod -m 666 tty c 5 0 && \
    mknod -m 666 tty0 c 4 0 && \
    mknod -m 444 random c 1 8 && \
    chown root:tty {console,ptmx,tty} && \
    ln -s /proc/kcore core && \
    ln -s /proc/self/fd && \
    ln -s /proc/self/fd/0 stdin && \
    ln -s /proc/self/fd/1 stdout && \
    ln -s /proc/self/fd/2 stderr && \
    mkdir pts && \
    mkdir shm
cd ${IMAGE_ROOT}/dev && \
    for i in `seq 0 16`; do \
        mknod -m 660 "ram$i" b 1 $i; \
    done && \
    for i in `seq 0 7`; do \
        mknod -m 660 "loop$i" b 7 $i; \
    done && \
    ln -s ram1 ram
cd ${IMAGE_ROOT}/dev && \
    mkfifo -m 640 xconsole

cd ${IMAGE_ROOT}/etc/init.d && \
	ln -s /etc/init.d/net.lo net.eth0 && \
	ln -s /etc/init.d/net.lo net.eth1

cd ${IMAGE_ROOT}/etc/runlevels/default && \
	ln -s /etc/init.d/net.eth0 && \
	ln -s /etc/init.d/net.eth1 && \
	ln -s /etc/init.d/sshd

rm -rf ${IMAGE_ROOT}/boot/*
rm -rf ${IMAGE_ROOT}/lib/modules/5.4.5
rm -rf ${IMAGE_ROOT}/usr/share/kernel

rm -rf ${IMAGE_ROOT}/sbin/{newfs_hfs,fsck_hfs,fsck.hfsplus,fsck_hfs,mkfs.hfsplus,mkfs.hfs}

rm -rf ${IMAGE_ROOT}/etc/bash_completion.d/grub
rm -rf ${IMAGE_ROOT}/etc/grub.d
rm -rf ${IMAGE_ROOT}/etc/grub-quirks.d
rm -rf ${IMAGE_ROOT}/usr/sbin/update-grub
rm -rf ${IMAGE_ROOT}/usr/sbin/grub-*
rm -rf ${IMAGE_ROOT}/usr/bin/grub-*
rm -rf ${IMAGE_ROOT}/usr/share/grub
rm -rf ${IMAGE_ROOT}/usr/lib/grub
rm -rf ${IMAGE_ROOT}/etc/default/grub

rm -rf ${IMAGE_ROOT}/sbin/{p,}mac-fdisk
