#!/bin/bash
# usage ./encoder.sh <input_dir> <album>
# params:
# input_dir: where the media files are located on disk
# album: name of the album 

# slugify with "_" instead of "-"
slugify() {
    echo "$1" | iconv -c -t ascii//TRANSLIT | sed -E 's/[~^]+//g' | sed -E 's/[^a-zA-Z0-9]+/_/g' | sed -E 's/^-+|-+$//g' | tr A-Z a-z
}

encode () {
    filename=$1
    extension=$2
    album=$3
    input_dir=$4

    filename_slug=$(slugify "$filename")
    album_slug=$(slugify "$album")

    parent_dir=$(realpath ".")

    echo "-- creating folders..."

    mkdir -p "$parent_dir/data/$album_slug/src/$filename_slug"
    mkdir -p "$parent_dir/data/$album_slug/dest/$filename_slug"

    echo "-- encoding file using ffmpeg..."

    # encode mp3 file in aac wrapped in mp4 container
    # note: libfdk_aac is an alternative to aac
    # -vn disable video
    # -sn disable subtitle
    ffmpeg -y -i "$input_dir/$filename.$extension" -c:a aac -b:a 128000 -ar 48000 -ac 2 -vn -sn "$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-128.mp4"
    ffmpeg -y -i "$input_dir/$filename.$extension" -c:a aac -b:a 192000 -ar 48000 -ac 2 -vn -sn "$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-192.mp4"
    ffmpeg -y -i "$input_dir/$filename.$extension" -c:a aac -b:a 256000 -ar 48000 -ac 2 -vn -sn "$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-256.mp4"

    echo "-- generating DASH manifest..."

    prepare DASH manifest
    ./lib/packager \
        input="$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-128.mp4",stream=audio,output="$parent_dir/data/$album_slug/dest/$filename_slug/$filename_slug-128.mp4",playlist_name="$filename_slug-128.m3u8" \
        input="$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-192.mp4",stream=audio,output="$parent_dir/data/$album_slug/dest/$filename_slug/$filename_slug-192.mp4",playlist_name="$filename_slug-192.m3u8" \
        input="$parent_dir/data/$album_slug/src/$filename_slug/$filename_slug-256.mp4",stream=audio,output="$parent_dir/data/$album_slug/dest/$filename_slug/$filename_slug-256.mp4",playlist_name="$filename_slug-256.m3u8" \
    --min_buffer_time 3 \
    --segment_duration 3 \
    --hls_master_playlist_output "$parent_dir/data/$album_slug/dest/$filename_slug/playlist-all.m3u8" \
    --mpd_output "$parent_dir/data/$album_slug/dest/$filename_slug/manifest-full.mpd"
}

# for each media file in the given folder
files=("$1"/*)
total=${#files[@]}
i=1

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        input_dir=$1
        album=$2

        filename=$(basename "$file")
        extension="${filename##*.}"

        echo "- ($i/$total) preprocessing file: $filename"

        if [ "$extension" = mp3 ] || [ "$extension" = flac ] || [ "$extension" = m4a ]; then
            filename="${filename%.*}"
            encode "$filename" "$extension" "$album" "$input_dir"
        fi
    fi

    i=$((i+1))
done
