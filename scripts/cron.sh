#!/bin/sh

## CONFIGURATION
workdir=
targetdir=
buildlogdir=

## CONFIGURE THE PATHS ABOVE BEFORE RUNNING AND REMOVE THE FOLLOWING LINES
echo "SCRIPT NOT CONFIGURED!!!"
exit 1
## END REMOVE

set -e

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

cd $workdir

./build_images.sh

date=$(date -u +%Y%m%d)
version=$date;

if [ -e $targetdir/$date ]; then
    suffix=1

    while [ -e $targetdir/${date}.$suffix ]; do
        suffix=$((suffix + 1));
    done

    version=${date}.$suffix
fi

cd $workdir
mkdir -p $buildlogdir/daily-live-$version
gzip -9 buildlog.*.txt
mv buildlog.*.txt.gz $buildlogdir/daily-live-$version/
# chown cdimage:cdimage cdimage/$version
mv cdimage/$version $targetdir
cd $targetdir
rm -f current
ln -sf $version current

# only keep the last 10 images
if [ `ls | wc -l` -gt 11 ]; then
    rm -rf `ls | head -n 1`
fi

set +e
