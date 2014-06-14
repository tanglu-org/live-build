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

./build_images.sh > buildlog 2>&1

date=$(date -u +%Y%m%d)

gzip -9 buildlog
mv buildlog.gz $buildlogdir/daily-live.${date}.txt.gz
# chown cdimage:cdimage cdimage/$date
mv cdimage/$date $targetdir
cd $targetdir
rm -f current
ln -sf $date current

# only keep the last 3 images
if [ `ls | wc -l` -gt 4 ]; then
    rm -rf `ls | head -n 1`
fi

set +e
