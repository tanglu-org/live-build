#!/bin/bash

. ./build_config

if [ ! -w /etc ]; then
    echo "this script needs to be run as root!"
    exit 1
fi

export LANG=C LANGUAGE=C LC_ALL=C

for arch in $architectures; do
    if [[ ! -e tanglu-$arch ]]; then
        echo "no tanglu-$arch chroot found! Aborting"
        exit 1
    fi
done

date=$(date -u +%Y%m%d)
[ -e cdimage/$date ] || mkdir -p cdimage/$date

for arch in $architectures; do
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== STARTING IMAGE BUILD FOR $arch" | tee -a buildlog.management.txt

    chroot ./tanglu-$arch/ /build_arch.sh prebuild | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh wipe_cache | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh expire_cache_prebuild | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh bootstrap | tee -a buildlog.${arch}.bootstrap.txt
    for flavor in $flavors; do
        chroot ./tanglu-$arch/ /build_arch.sh runbuild $flavor | tee -a buildlog.${arch}.${flavor}.txt
    done

    chroot ./tanglu-$arch/ /build_arch.sh wipe_cache | tee -a buildlog.${arch}.finish.txt
    chroot ./tanglu-$arch/ /build_arch.sh expire_cache_postbuild | tee -a buildlog.${arch}.finish.txt
    chroot ./tanglu-$arch/ /build_arch.sh postbuild | tee -a buildlog.${arch}.finish.txt

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== DONE BUILDING IMAGES FOR $arch" | tee -a buildlog.management.txt
    mv -v tanglu-$arch/tmp/cdimage/tanglu-* cdimage/$date/ | tee -a buildlog.management.txt
done


cd cdimage/$date

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== GENERATING CHECKSUMS" | tee -a buildlog.management.txt

md5sum *.iso | tee MD5SUM | tee -a buildlog.management.txt
sha256sum *.iso | tee SHA256SUM | tee -a buildlog.management.txt

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== IMAGE BUILD FINISHED" | tee -a buildlog.management.txt
