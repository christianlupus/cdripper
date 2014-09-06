#!/bin/sh

if [ ! -n "$1" ]; then
	echo "Bitte die Zieladresse für die Dateien angeben."
	exit 1
fi

DESTINATION="$1"

NUM_JOBS=$(ls -d /sys/devices/system/cpu/cpu[[:digit:]]* | wc -w)

MP3_HQ_OPTS="-b 320 -q 2"
MP3_LQ_OPTS="--vbr-new -B 256 -q 5"
OGG_OPTS="-q 4"

MP3_HQ_DIR="$DESTINATION/mp3 HQ"
MP3_LQ_DIR="$DESTINATION/mp3 $MP3_LQ_OPTS"
OGG_DIR="$DESTINATION/ogg $OGG_OPTS"

ALBUM=$(awk -F"~" '{print $2}' album.info)

MP3_HQ_PREFIX="$MP3_HQ_DIR/$ALBUM"
MP3_LQ_PREFIX="$MP3_LQ_DIR/$ALBUM"
OGG_PREFIX="$OGG_DIR/$ALBUM"

echo "Bitte Jahr eingeben (oder nichts)"

read YEAR
SET_YEAR=0

if [ -n "$YEAR" ]; then
	SET_YEAR=1
fi

###
# Normalizing

echo Normalisiere die Dateien

cd tmp
normalize-audio -b audio_*.wav
cd ..


###
# Create directories

mkdir -p "$DESTINATION" "$MP3_HQ_DIR/$ALBUM" "$MP3_LQ_DIR/$ALBUM" "$OGG_DIR/$ALBUM"

###
# Prepare encoding of the files

titlenumbers=$(awk -F"~" '{print $1}' titles.info)

rm -f tmp/mp3HQ.list tmp/mp3LQ.list tmp/ogg.list tmp/enc.list

for i in $titlenumbers
do
	
	titleartist=$(grep -E "^$i" titles.info | awk -F "~" '{print $3}')
	titlename=$(grep -E "^$i" titles.info | awk -F "~" '{print $4}')
	
	echo "tmp/audio_$i.wav" >> tmp/mp3HQ.list
	echo "tmp/audio_$i.wav" >> tmp/mp3LQ.list
	echo "tmp/audio_$i.wav" >> tmp/ogg.list
	
	echo "\"$MP3_HQ_PREFIX/$i - $titleartist - $titlename.mp3\"" >> tmp/mp3HQ.list
	echo "\"$MP3_LQ_PREFIX/$i - $titleartist - $titlename.mp3\"" >> tmp/mp3LQ.list
	echo "-o \"$OGG_PREFIX/$i - $titleartist - $titlename.ogg\"" >> tmp/ogg.list
	
done


###
# Do the actual encodings


echo Encoding HQ MP3s...
cat tmp/mp3HQ.list | xargs -n 2 -P $NUM_JOBS lame $MP3_HQ_OPTS -S

echo Encoding LQ MP3s...
cat tmp/mp3LQ.list | xargs -n 2 -P $NUM_JOBS lame $MP3_LQ_OPTS -S

echo Encoding OGGs...
cat tmp/ogg.list | xargs -n 3 -P $NUM_JOBS oggenc $OGG_OPTS -Q


###
# Tag the files

echo "Tagging der Dateien..."

for i in $titlenumbers
do
	
	titleartist=$(grep -E "^$i" titles.info | awk -F "~" '{print $3}')
	titlename=$(grep -E "^$i" titles.info | awk -F "~" '{print $4}')
	
	for f in "$MP3_HQ_PREFIX/$i - $titleartist - $titlename.mp3" "$MP3_LQ_PREFIX/$i - $titleartist - $titlename.mp3" "$OGG_PREFIX/$i - $titleartist - $titlename.ogg"
	do
		
		id3v2 -a "$titleartist" "$f"
		id3v2 -A "$ALBUM" "$f"
		id3v2 -t "$titlename" "$f"
		id3v2 -T $i "$f"
		
		if [ $SET_YEAR -eq 1 ]; then
			id3v2 -y "$YEAR" "$f"
		fi
		
	done
	
	
done


###
# Create the M3U file

echo "Erzeuge M3U Dateien..."

rm -f "$MP3_HQ_PREFIX/$ALBUM.m3u" "$MP3_LQ_PREFIX/$ALBUM.m3u" "$OGG_PREFIX/$ALBUM.m3u"

echo "#EXTM3U" >> "$MP3_HQ_PREFIX/$ALBUM.m3u"
echo "#EXTM3U" >> "$MP3_LQ_PREFIX/$ALBUM.m3u"
echo "#EXTM3U" >> "$OGG_PREFIX/$ALBUM.m3u"

for i in $titlenumbers
do
	
	titlelen=$(grep -E "^$i" titles.info | awk -F "~" '{print $2}')
	titleartist=$(grep -E "^$i" titles.info | awk -F "~" '{print $3}')
	titlename=$(grep -E "^$i" titles.info | awk -F "~" '{print $4}')
	
	echo "#EXTINF:$titlelen,$i - $titlename" >> "$MP3_HQ_PREFIX/$ALBUM.m3u"
	echo "$i - $titleartist - $titlename.mp3" >> "$MP3_HQ_PREFIX/$ALBUM.m3u"
	
	echo "#EXTINF:$titlelen,$i - $titlename" >> "$MP3_LQ_PREFIX/$ALBUM.m3u"
	echo "$i - $titleartist - $titlename.mp3" >> "$MP3_LQ_PREFIX/$ALBUM.m3u"
	
	echo "#EXTINF:$titlelen,$i - $titlename" >> "$OGG_PREFIX/$ALBUM.m3u"
	echo "$i - $titleartist - $titlename.ogg" >> "$OGG_PREFIX/$ALBUM.m3u"
	
done

