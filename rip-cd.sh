#!/bin/bash

if [ $# -eq 0 ]; then
DEVICE="/dev/cdrom"
else
DEVICE="$1"
fi

mkdir -p tmp
cd tmp

rm -rf *
cdda2wav -L 0 -B -D "$DEVICE"

#cp audio.cddb ..

#normalize-audio -b audio_*.wav

rm -rf titles.info album.info

cd ..

eject "$DEVICE"

echo "Bitte nun prepare-rip.sh aufrufen, um die Track-Informationen zu extrahieren."
