#!/bin/bash
# usage ./encoder.sh <media_dir> <cwd> <album>
# params:
# media_dir: where the media files are located on disk
# cwd: absolute path current working directory (i.e. where the script is executed from not where it is located)
# album: name of the album 

# Slugify
# Transliterate everything to ASCII
# Strip out apostrophes
# Anything that's not a letter or number to a underscore
# Strip leading & trailing underscores
# Everything to lowercase
# https://duncanlock.net/blog/2021/06/15/good-simple-bash-slugify-function/ 
slugify() {
  echo "$1" \
  | iconv -t ascii//TRANSLIT \
  | tr -d "'" \
  | sed -E 's/[^a-zA-Z0-9]+/_/g' \
  | sed -E 's/^_+|_+$//g' \
  | tr "[:upper:]" "[:lower:]"
}

encode () {
    media_dir=$1
    cwd=$2
    album=$3
    filename=$4
    extension=$5

    filename_slug=$(slugify "$filename")
    album_slug=$(slugify "$album")

    #parent_dir=$(realpath ".")

    mkdir -p "$cwd/data/$album_slug/src/$filename_slug"
    mkdir -p "$cwd/data/$album_slug/dest/$filename_slug"

    echo "-- encoding file using ffmpeg..."

    # encode mp3 file in aac wrapped in mp4 container
    # note: libfdk_aac is an alternative to aac
    # -vn disable video
    # -sn disable subtitle
    ffmpeg -y -i "$media_dir/$filename.$extension" -c:a aac -b:a 128000 -ar 48000 -ac 2 -vn -sn "$cwd/data/$album_slug/src/$filename_slug/$filename_slug-128.mp4"
    ffmpeg -y -i "$media_dir/$filename.$extension" -c:a aac -b:a 192000 -ar 48000 -ac 2 -vn -sn "$cwd/data/$album_slug/src/$filename_slug/$filename_slug-192.mp4"
    ffmpeg -y -i "$media_dir/$filename.$extension" -c:a aac -b:a 256000 -ar 48000 -ac 2 -vn -sn "$cwd/data/$album_slug/src/$filename_slug/$filename_slug-256.mp4"

    echo "-- generating DASH manifest..."

    prepare DASH manifest
    ./lib/packager \
        input="$cwd/data/$album_slug/src/$filename_slug/$filename_slug-128.mp4",stream=audio,output="$cwd/data/$album_slug/dest/$filename_slug/$filename_slug-128.mp4",playlist_name="$filename_slug-128.m3u8" \
        input="$cwd/data/$album_slug/src/$filename_slug/$filename_slug-192.mp4",stream=audio,output="$cwd/data/$album_slug/dest/$filename_slug/$filename_slug-192.mp4",playlist_name="$filename_slug-192.m3u8" \
        input="$cwd/data/$album_slug/src/$filename_slug/$filename_slug-256.mp4",stream=audio,output="$cwd/data/$album_slug/dest/$filename_slug/$filename_slug-256.mp4",playlist_name="$filename_slug-256.m3u8" \
    --min_buffer_time 3 \
    --segment_duration 3 \
    --hls_master_playlist_output "$cwd/data/$album_slug/dest/$filename_slug/playlist-all.m3u8" \
    --mpd_output "$cwd/data/$album_slug/dest/$filename_slug/manifest-full.mpd"
}

# for each media file in the given folder
files=("$1"/*)
total=${#files[@]}
i=1

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        media_dir=$1
        cwd=$2
        album=$3

        filename=$(basename "$file")
        extension="${filename##*.}"

        echo "- ($i/$total) preprocessing file: $filename"

        if [ "$extension" = mp3 ] || [ "$extension" = flac ] || [ "$extension" = m4a ]; then
            filename="${filename%.*}"
            encode "$media_dir" "$cwd" "$album" "$filename" "$extension" 
        fi
    fi

    i=$((i+1))
done
