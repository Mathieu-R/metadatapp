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
    album_dir=$2
    filename=$3
    extension=$4

    filename_slug=$(slugify "$filename")

    input_folder="${album_dir}/src/${filename_slug}"
    output_folder="${album_dir}/${filename_slug}"

    # temp input folder
    mkdir -p "${input_folder}"
    # output folder
    mkdir -p "${output_folder}"

    echo "-- encoding file using ffmpeg..."

    # encode mp3 file in aac wrapped in mp4 container
    # note: libfdk_aac is an alternative to aac
    # -vn disable video
    # -sn disable subtitle
    ffmpeg -y -i "${media_dir}/$filename.$extension" -c:a aac -b:a 128000 -ar 48000 -ac 2 -vn -sn "${input_folder}/${filename_slug}-128.mp4"
    ffmpeg -y -i "${media_dir}/$filename.$extension" -c:a aac -b:a 192000 -ar 48000 -ac 2 -vn -sn "${input_folder}/${filename_slug}-192.mp4"
    ffmpeg -y -i "${media_dir}/$filename.$extension" -c:a aac -b:a 256000 -ar 48000 -ac 2 -vn -sn "${input_folder}/${filename_slug}-256.mp4"

    echo "-- generating DASH manifest..."

    # prepare DASH manifest
    ./lib/packager \
        input="${input_folder}/${filename_slug}-128.mp4",stream=audio,output="${output_folder}/$filename_slug-128.mp4",playlist_name="${filename_slug}-128.m3u8" \
        input="${input_folder}/${filename_slug}-192.mp4",stream=audio,output="${output_folder}/$filename_slug-192.mp4",playlist_name="${filename_slug}-192.m3u8" \
        input="${input_folder}/${filename_slug}-256.mp4",stream=audio,output="${output_folder}/$filename_slug-256.mp4",playlist_name="${filename_slug}-256.m3u8" \
    --min_buffer_time 3 \
    --segment_duration 3 \
    --hls_master_playlist_output "${output_folder}/playlist-all.m3u8" \
    --mpd_output "${output_folder}/manifest-full.mpd"
}

# for each media file in the given folder
files=("$1"/*)
total=${#files[@]}
i=1


media_dir=$1
cwd=$2
album_artist=$3
album=$4

album_artist_slug=$(slugify "$album_artist")
album_slug=$(slugify "$album")

album_dir="${cwd}/data/${album_artist_slug}/${album_slug}"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then

        filename=$(basename "$file")
        extension="${filename##*.}"

        echo "- ($i/$total) preprocessing file: $filename"

        if [ "$extension" = mp3 ] || [ "$extension" = flac ] || [ "$extension" = m4a ]; then
            filename="${filename%.*}"
            encode "${media_dir}" "${album_dir}" "$filename" "$extension" 
        fi
    fi

    i=$((i+1))
done

echo "-- cleaning temp files..."
    rm -rf "${album_dir}/src"
