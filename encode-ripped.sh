#!/bin/bash -e

YEAR=
YEAR_SET=
NORMALIZE=1
DESTINATION=

while [ $# -gt 0 ]
do
	case "$1" in
		--year)
			YEAR="$2"
			YEAR_SET=1
			shift
			;;
		--no-year)
			YEAR=
			YEAR_SET=1
			;;
		--no-normalize)
			NORMALIZE=
			;;
		--out)
			DESTINATION="$2"
			shift
			;;
		*)
			echo "Unexpected cli parameter $1. Exiting."
			exit 1
	esac
	shift
done

if [ -z "$DESTINATION" ]
then
	echo "The mandatory output path was not given using --out CLI parameter. Please adjust."
	exit 1
fi

if [ ! -d "$DESTINATION" -o ! -w "$DESTINATION" ]
then
	echo "The destination provided is no valid and writable folder."
	exit 1
fi

if [ -z "$YEAR_SET" ]
then
	echo "Please provide the year of the publication. (You can avoid this question by providing the --year or --no-year CLI parameter."
	echo "The year can also be empty."
	read YEAR
fi

export SET_YEAR=0

if [ -n "$YEAR" ]; then
	SET_YEAR=1
	export YEAR
fi

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

if grep '/' titles.info album.info; then
	echo 'There is a forward slash in the info files. This is currently not supported.'
	exit 1
fi

###
# Normalizing

if [ -n "$NORMALIZE" ]
then
	echo "Normalizing the audio tracks"

	cd tmp
	normalize -b audio_*.wav
	cd ..
fi

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
	
	echo "Encoding $basename" >&2
	
	lame $MP3_HQ_OPTS -S "tmp/audio_$1.wav" "$MP3_HQ_PREFIX/$basename.mp3"
# 	sleep 1
	lame $MP3_LQ_OPTS -S "tmp/audio_$1.wav" "$MP3_LQ_PREFIX/$basename.mp3"
# 	sleep 2
	oggenc $OGG_OPTS -Q "tmp/audio_$1.wav" -o "$OGG_PREFIX/$basename.ogg"
# 	sleep 1
	
	echo "Tagging files from $basename" >&2
	
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

filtered_titles() {
	cat titles.info | sed 's@[[:space:]]*$@@' | grep -v '^#' | grep -v '^$'
}

prepare_encode_parallel() {
	IFS='~' read tracknumber tmp artist name <<< "$1"
	encode_track "$tracknumber" "$artist" "$name"
}

encode_parallelly() {
	parallel prepare_encode_parallel {} :::: <( filtered_titles )
}

encode_serially() {
	filtered_titles | while IFS='~' read tracknumber tmp artist name
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

echo "Creating M3U8 files."

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

echo "Encoding is done"
