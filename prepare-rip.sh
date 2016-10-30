#!/bin/bash

function read_info {
	TRACKFILE="$1"
	QUERY="$2"
	
	iconv -f iso-8859-1 "$TRACKFILE" | grep "^$QUERY=" | sed -E "s@^$QUERY\=\s*['\"]?(.*)['\"]?\$@\1@" | sed -E "s@['\"]\$@@"
}


cd tmp

rm -rf titles.info album.info

for f in audio_*.inf
do
	
	Tracknumber="$(read_info "$f" Tracknumber)"
	Length="$(read_info "$f" Tracklength)"
	Performer="$(read_info "$f" Performer)"
	Title="$(read_info "$f" Tracktitle)"
	
	if [ ${#Tracknumber} -le 1 ]; then
		Tracknumber="0$Tracknumber"
	fi
	
	Sectors=$(echo $Length | awk -F ", " "{print \$1}")
	Sekunden=$(( $Sectors / 75 ))
	
	echo "$Tracknumber~$Sekunden~$Performer~$Title" >> titles.info
	
# 	echo $Tracknumber
# 	echo $Performer
	
done

Albumperformer="$(read_info audio_01.inf Albumperformer)"
Albumtitle="$(read_info audio_01.inf Albumtitle)"

echo "$Albumperformer~$Albumtitle" >> album.info

cp titles.info album.info ..

cd ..

echo "Bitte die Dateien titles.info und album.info korrigieren. Danach encode-ripped.sh aufrufen, um mit dem Kodieren zu beginen."
