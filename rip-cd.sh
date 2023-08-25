#!/bin/bash -e

DEVICE="/dev/cdrom"
CDDB="-L 0 --cddbp-server=gnudb.gnudb.org"

while [ $# -gt 0 ]
do
    case "$1" in
        --no-cddb)
            CDDB=""
            ;;
        /dev/*)
            DEVICE=$1
            ;;
        *)
            echo "Option $1 is not detected. Aborting."
            exit 1
            ;;
    esac
    shift
done

echo "Using device $DEVICE for ripping."

if [ -e tmp ]
then
    echo 'The folder tmp seems to be existing. To avoid data loss, this script terminates here.'
    exit 1
fi

mkdir -p tmp
cd tmp

rm -rf *
cdda2wav $CDDB -B -D "$DEVICE"

rm -rf titles.info album.info

cd ..

eject "$DEVICE"

echo "Please call prepare-rip.sh now to extarct the track information from the rip."
