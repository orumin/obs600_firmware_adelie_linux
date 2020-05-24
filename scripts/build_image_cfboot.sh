#!/bin/bash

IMAGE_ROOT=$1
BUSYBOX_BIN=$2
INIT=$3

if [ ! -d $IMAGE_ROOT ] || [ ! -f $BUSYBOX_BIN ] || [ ! -f $INIT ]; then
    echo ""
    echo "$0: invalid argument"
    echo ""
    exit 1;
fi

install -m 755 -o root -g root -d ${IMAGE_ROOT}/{bin,dev,etc,home,lib,mnt,proc,root,sbin,sys,tmp,usr,var}

install -m 755 -o root -g root -d ${IMAGE_ROOT}/etc/{defaults,hotplug,hotplug.d,profile.d,security}
install -m 755 -o root -g root -d ${IMAGE_ROOT}/etc/hotplug/usb
install -m 755 -o root -g root -d ${IMAGE_ROOT}/etc/hotplug.d/default

install -m 755 -o root -g root -d ${IMAGE_ROOT}/lib/{modules,security}

install -m 755 -o root -g root -d ${IMAGE_ROOT}/usr/{bin,lib,libexec,local,pkg,sbin,share}
install -m 755 -o root -g root -d ${IMAGE_ROOT}/usr/lib/locale
install -m 755 -o root -g root -d ${IMAGE_ROOT}/usr/share/openssl
install -m 755 -o root -g root -d ${IMAGE_ROOT}/usr/share/zoneinfo
install -m 755 -o root -g root -d ${IMAGE_ROOT}/usr/share/zoneinfo/Asia

install -m 755 -o root -g root -d ${IMAGE_ROOT}/var/{cron,db,lock,log,run,spool}
install -m 755 -o root -g root -d ${IMAGE_ROOT}/var/cron/tabs

install -m 755 -o root -g root ${BUSYBOX_BIN} ${IMAGE_ROOT}/usr/bin/

install -m 755 -o root -g root ${INIT} ${IMAGE_ROOT}/

cd ${IMAGE_ROOT}/usr/bin && \
    ln -s /usr/bin/busybox awk && \
    ln -s /usr/bin/busybox chroot

cd ${IMAGE_ROOT}/sbin && \
    ln -s /usr/bin/busybox blockdev && \
    ln -s /usr/bin/busybox findfs && \
    ln -s /usr/bin/busybox halt && \
    ln -s /usr/bin/busybox pivot_root && \
    ln -s /usr/bin/busybox poweroff && \
    ln -s /usr/bin/busybox reboot && \
    ln -s /usr/bin/busybox switch_root

cd ${IMAGE_ROOT}/bin && \
    ln -s /usr/bin/busybox ash && \
    ln -s /usr/bin/busybox cat && \
    ln -s /usr/bin/busybox echo && \
    ln -s /usr/bin/busybox grep && \
    ln -s /usr/bin/busybox mkdir && \
    ln -s /usr/bin/busybox mount && \
    ln -s /usr/bin/busybox rm && \
    ln -s /usr/bin/busybox sh && \
    ln -s /usr/bin/busybox sleep && \
    ln -s /usr/bin/busybox umount

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

