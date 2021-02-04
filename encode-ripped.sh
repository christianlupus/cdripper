#!/bin/sh

if [ ! -n "$1" ]; then
	echo "Bitte die Zieladresse für die Dateien angeben."
	exit 1
fi

DESTINATION="$1"

export MP3_HQ_OPTS="-b 320 -q 2"
export MP3_LQ_OPTS="--vbr-new -B 256 -q 5"
export OGG_OPTS="-q 4"

MP3_HQ_DIR="$DESTINATION/mp3 HQ"
MP3_LQ_DIR="$DESTINATION/mp3 $MP3_LQ_OPTS"
OGG_DIR="$DESTINATION/ogg $OGG_OPTS"

export ALBUM=$(awk -F"~" '{print $2}' album.info)

export MP3_HQ_PREFIX="$MP3_HQ_DIR/$ALBUM"
export MP3_LQ_PREFIX="$MP3_LQ_DIR/$ALBUM"
export OGG_PREFIX="$OGG_DIR/$ALBUM"

echo "Bitte Jahr eingeben (oder nichts)"

read YEAR
export SET_YEAR=0

if [ -n "$YEAR" ]; then
	SET_YEAR=1
	export YEAR
fi

###
# Normalizing

echo Normalisiere die Dateien

cd tmp
normalize -b audio_*.wav
cd ..


###
# Create directories

mkdir -p "$DESTINATION" "$MP3_HQ_DIR/$ALBUM" "$MP3_LQ_DIR/$ALBUM" "$OGG_DIR/$ALBUM"

###
# Prepare encoding of the files

encode_track() {
	# Input parameters
	# $1 - track number
	# $2 - track artist
	# $3 - track name
	
	local tracknumber="$1"
	local trackartist="$2"
	local trackname="$3"
	
	local basename="$tracknumber - $trackartist - $trackname"
	
	echo "Encodiere $basename" >&2
	
	lame $MP3_HQ_OPTS -S "tmp/audio_$1.wav" "$MP3_HQ_PREFIX/$basename.mp3"
# 	sleep 1
	lame $MP3_LQ_OPTS -S "tmp/audio_$1.wav" "$MP3_LQ_PREFIX/$basename.mp3"
# 	sleep 2
	oggenc $OGG_OPTS -Q "tmp/audio_$1.wav" -o "$OGG_PREFIX/$basename.ogg"
# 	sleep 1
	
	echo "Tagging der Dateien von $basename" >&2
	
	for f in "$MP3_HQ_PREFIX/$basename.mp3" "$MP3_LQ_PREFIX/$basename.mp3" "$OGG_PREFIX/$basename.ogg"
	do
		id3v2 -a "$(echo "$trackartist" | iconv -t ISO-8859-1)" "$f"
		id3v2 -A "$(echo "$ALBUM" | iconv -t ISO-8859-1)" "$f"
		id3v2 -t "$(echo "$trackname" | iconv -t ISO-8859-1)" "$f"
		id3v2 -T "$(echo "$tracknumber" | iconv -t ISO-8859-1)" "$f"
		
		if [ $SET_YEAR -eq 1 ]; then
			id3v2 -y "$YEAR" "$f"
		fi
	done
}

prepare_encode_parallel() {
	IFS='~' read tracknumber tmp artist name <<< "$1"
	encode_track "$tracknumber" "$artist" "$name"
}

encode_parallelly() {
	parallel prepare_encode_parallel {} :::: titles.info
}

encode_serially() {
	cat titles.info | while IFS='~' read tracknumber tmp artist name
	do
		encode_track "$tracknumber" "$artist" "$name"
	done
}

export -f encode_track prepare_encode_parallel encode_parallelly

if which parallel; then
	echo 'Using parallel to run the scripts.'
	encode_parallelly
else
	echo 'Could not find parallel executable on PATH. Falling back to sequential encoding.'
	encode_serially
fi


###
# Create the M3U file

echo "Erzeuge M3U Dateien..."

rm -f "$MP3_HQ_PREFIX/$ALBUM.m3u" "$MP3_LQ_PREFIX/$ALBUM.m3u" "$OGG_PREFIX/$ALBUM.m3u"

echo "#EXTM3U" >> "$MP3_HQ_PREFIX/$ALBUM.m3u8"
echo "#EXTM3U" >> "$MP3_LQ_PREFIX/$ALBUM.m3u8"
echo "#EXTM3U" >> "$OGG_PREFIX/$ALBUM.m3u8"

echo "#EXTENC: UTF-8" >> "$MP3_HQ_PREFIX/$ALBUM.m3u8"
echo "#EXTENC: UTF-8" >> "$MP3_LQ_PREFIX/$ALBUM.m3u8"
echo "#EXTENC: UTF-8" >> "$OGG_PREFIX/$ALBUM.m3u8"

cat titles.info | while IFS='~' read tracknumber titlelen titleartist titlename
do
	
	basename="$tracknumber - $titleartist - $titlename"
	
	echo "#EXTINF:$titlelen,$tracknumber - $titlename" >> "$MP3_HQ_PREFIX/$ALBUM.m3u8"
	echo "$basename.mp3" >> "$MP3_HQ_PREFIX/$ALBUM.m3u8"
	
	echo "#EXTINF:$titlelen,$i - $titlename" >> "$MP3_LQ_PREFIX/$ALBUM.m3u8"
	echo "$basename.mp3" >> "$MP3_LQ_PREFIX/$ALBUM.m3u8"
	
	echo "#EXTINF:$titlelen,$i - $titlename" >> "$OGG_PREFIX/$ALBUM.m3u8"
	echo "$basename.ogg" >> "$OGG_PREFIX/$ALBUM.m3u8"
	
done

