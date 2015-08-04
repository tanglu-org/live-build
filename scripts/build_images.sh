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

    chroot ./tanglu-$arch/ /build_arch.sh prebuild 2>&1 | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh wipe_cache 2>&1 | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh expire_cache_prebuild 2>&1 | tee -a buildlog.${arch}.prepare.txt
    chroot ./tanglu-$arch/ /build_arch.sh bootstrap 2>&1 | tee -a buildlog.${arch}.bootstrap.txt
    for flavor in $flavors; do
        chroot ./tanglu-$arch/ /build_arch.sh runbuild $flavor 2>&1 | tee -a buildlog.${arch}.${flavor}.txt
    done

    chroot ./tanglu-$arch/ /build_arch.sh wipe_cache 2>&1 | tee -a buildlog.${arch}.finish.txt
    chroot ./tanglu-$arch/ /build_arch.sh expire_cache_postbuild 2>&1 | tee -a buildlog.${arch}.finish.txt
    chroot ./tanglu-$arch/ /build_arch.sh postbuild 2>&1 | tee -a buildlog.${arch}.finish.txt

    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== DONE BUILDING IMAGES FOR $arch" 2>&1 | tee -a buildlog.management.txt
    mv -v tanglu-$arch/tmp/cdimage/tanglu-* cdimage/$date/ 2>&1 | tee -a buildlog.management.txt
done


cd cdimage/$date

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== GENERATING CHECKSUMS" | tee -a buildlog.management.txt

md5sum *.iso | tee MD5SUM 2>&1 | tee -a buildlog.management.txt
sha256sum *.iso | tee SHA256SUM 2>&1 | tee -a buildlog.management.txt

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== IMAGE BUILD FINISHED" | tee -a buildlog.management.txt
