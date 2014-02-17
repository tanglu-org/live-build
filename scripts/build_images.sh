#!/bin/bash -e

if [ ! -w /etc ]; then
    echo "this script needs to be run as root!"
    exit 1
fi

export LANG=C LANGUAGE=C LC_ALL=C

if [[ ! -e tanglu-amd64 || ! -e tanglu-i386 ]]; then
    echo "either tanglu-amd64 or tanglu-i386 chroot missing!"
    exit 1
fi

date=$(date -u +%Y%m%d)
[ -e cdimage/$date ] || mkdir -p cdimage/$date


for arch in {amd64,i386}; do
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== STARTING IMAGE BUILD FOR $arch"
    chroot ./tanglu-$arch/ /build_arch.sh
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== DONE BUILDING IMAGES FOR $arch"
    mv tanglu-$arch/tmp/cdimage/tanglu-* cdimage/$date/
done


cd cdimage/$date

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== GENERATING CHECKSUMS"

md5sum *.iso > MD5SUM
sha256sum *.iso > SHA256SUM

echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== IMAGE BUILD FINISHED"
