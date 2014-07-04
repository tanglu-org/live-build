#!/bin/bash -e

chroot_release=bartholomea

if [ ! -e /usr/share/debootstrap/scripts/$chroot_release ]; then
    echo "Your version of debootstrap does not support tanglu!"
    exit 1
fi

if [ ! -e /usr/share/keyrings/tanglu-archive-keyring.gpg ]; then
    echo "tanglu-archive-keyring has to be installed to create the chroots!"
    exit 1
fi

if [[ -z $1 || ! -w /etc ]]; then
    echo "usage: sudo ./bootstrap.sh /path/to/workdir/";
    exit 2
fi

workdir=$1

[ -e $workdir ] || mkdir -p $workdir

for arch in {i386,amd64}; do
    echo "[$(date -u +%Y-%m-%d\ %H:%M:%S)] ===== BUILDING $arch CHROOT..."
    debootstrap --arch=$arch $chroot_release $workdir/tanglu-$arch
    cp ./build_arch.sh $workdir/tanglu-$arch/
    echo 'APT::Get::AutomaticRemove "true";' >> $workdir/tanglu-$arch/etc/apt/apt.conf
done

cp ./build_images.sh $workdir/
cp ./build_config $workdir/

echo "setup done, you can now build the images by going to the work directory"
echo "and running 'sudo ./build_images.sh'"
