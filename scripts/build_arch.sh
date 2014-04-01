#!/bin/bash -e

wipe_cache()
{
    for dir in $(ls cache/ | grep -P '^(?!packages*)(.*)$'); do
        rm -rf cache/$dir
    done
}

if [ ! -w /etc ]; then
    echo "this script needs to be run as root!"
    exit 1
fi

export LANG=C LANGUAGE=C LC_ALL=C

mount -t proc proc /proc || true
mount -t devpts devpts /dev/pts || true

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== UPDATING CHROOT"

apt-get update
apt-get check
apt-get -y --force-yes dist-upgrade

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== UPDATING IMAGE CONFIG"

[ -e /usr/bin/git ] || apt-get -y --force-yes install git

[ -e /tmp/cdimage/ ] || mkdir -p /tmp/cdimage

if [ ! -e /tmp/live-build/ ]; then
	cd /tmp
	git clone git://gitorious.org/tanglu/live-build.git
fi
cd /tmp/live-build
git fetch
git reset --hard origin/master

sh install-prerequisites.sh

#export snapshot_build=yes

# remove the live-build cache if it's there but keep the packages
wipe_cache

for flavor in {kde,gnome}; do

	lb clean

	export FLAVOR=$flavor

        echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== STARTING IMAGE BUILD - FLAVOR: $FLAVOR "

	lb config
	lb build

	mv tanglu-* /tmp/cdimage/

done

lb clean

# clean up the cache as we won't be reusing it next time
wipe_cache

umount /proc || true
umount /dev/pts || true
