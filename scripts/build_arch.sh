#!/bin/bash

_lbdir=/tmp/live-build

wipe_cache()
{
    cd $_lbdir

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== CACHE CLEANUP"
    for dir in $(ls cache/ | grep -P '^(?!packages*)(.*)$'); do
        rm -rf cache/$dir
    done
}

expire_cache_prebuild()
{
    cd $_lbdir
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== EXPIRE PACKAGE CACHE PASS 1"
    apt-get update && {
        # wipe undownloadable packages
        cp -f cache/packages.binary/* /var/cache/apt/archives/
        rm -rf cache/packages.binary/*
        rm -rf cache/packages.chroot/*
        apt-get autoclean
        cp -f /var/cache/apt/archives/* cache/packages.binary/

        # restore hard links
        for file in cache/packages.binary/*; do
                ln $file cache/packages.chroot/
        done
    }
}

expire_cache_postbuild()
{
    cd $_lbdir
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== EXPIRE PACKAGE CACHE PASS 2"
    find cache/ -atime +1 -exec rm -vf -- '{}' \;
}

prebuild()
{
    export LANG=C LANGUAGE=C LC_ALL=C

    mount -t proc proc /proc || true
    mount -t devpts devpts /dev/pts || true

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== UPDATING CHROOT"

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get check
    apt-get -y --force-yes dist-upgrade
    apt-get -y autoremove

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== UPDATING IMAGE CONFIG"

    [ -e /usr/bin/git ] || apt-get -y --force-yes install git

    [ -e /tmp/cdimage/ ] || mkdir -p /tmp/cdimage

    if [ ! -e $_lbdir ]; then
            cd /tmp
            git clone https://gitlab.com/tanglu/live-build.git
    fi
    cd $_lbdir
    git fetch
    git reset --hard origin/master

    sh install-prerequisites.sh

    lb clean
}

postbuild()
{
    cd $_lbdir
    lb clean
    umount /proc || true
    umount /dev/pts || true
}

runbuild()
{
    cd $_lbdir

    lb clean

    export FLAVOR=$2

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== STARTING IMAGE BUILD - FLAVOR: $FLAVOR "

    lb config
    lb build

    mv tanglu-* /tmp/cdimage/

}

bootstrap()
{
    cd $_lbdir

    # we only do the bootstrap, so the configuration doesn't matter
    lb config

    lb debootstrap
}

if [ ! -w /etc ]; then
    echo "this script needs to be run as root!"
    exit 1
fi

if [ "x$(type -t $1)" = 'xfunction' ]; then
    $1
else
    echo "unkown command: $1"
fi
