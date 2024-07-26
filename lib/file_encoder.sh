#!/bin/bash
# usage ./encoder.sh <media_path> <media_slug> <album>
# params:
# media_path: absolute path of the media file on disk (with extension)
# media_slug: slugified version of the media file name
# album_folder_path: absolute path of the album directory
encode () {
    media_path=$1
    media_slug=$2
    album_folder_path=$3

    echo "${media_path} ${media_slug} ${album_folder_path}"

    temp_folder_path="${album_folder_path}/src/${media_slug}"
    encoded_media_folder_path="${album_folder_path}/${media_slug}"

    # temp input folder
    mkdir -p "${temp_folder_path}"
    # output folder
    mkdir -p "${encoded_media_folder_path}"

    echo "-- encoding file using ffmpeg..."

    # encode mp3 file in aac wrapped in mp4 container
    # note: libfdk_aac is an alternative to aac
    # -vn disable video
    # -sn disable subtitle
    ffmpeg -y -i "${media_path}" -c:a aac -b:a 128000 -ar 48000 -ac 2 -vn -sn "${temp_folder_path}/${media_slug}-128.mp4"
    ffmpeg -y -i "${media_path}" -c:a aac -b:a 192000 -ar 48000 -ac 2 -vn -sn "${temp_folder_path}/${media_slug}-192.mp4"
    ffmpeg -y -i "${media_path}" -c:a aac -b:a 256000 -ar 48000 -ac 2 -vn -sn "${temp_folder_path}/${media_slug}-256.mp4"

    echo "-- generating DASH manifest..."

    # prepare DASH manifest
    ./lib/packager \
        input="${temp_folder_path}/${media_slug}-128.mp4",stream=audio,output="${encoded_media_folder_path}/${media_slug}-128.mp4",playlist_name="${media_slug}-128.m3u8" \
        input="${temp_folder_path}/${media_slug}-192.mp4",stream=audio,output="${encoded_media_folder_path}/${media_slug}-192.mp4",playlist_name="${media_slug}-192.m3u8" \
        input="${temp_folder_path}/${media_slug}-256.mp4",stream=audio,output="${encoded_media_folder_path}/${media_slug}-256.mp4",playlist_name="${media_slug}-256.m3u8" \
    --min_buffer_time 3 \
    --segment_duration 3 \
    --hls_master_playlist_output "${encoded_media_folder_path}/playlist-all.m3u8" \
    --mpd_output "${encoded_media_folder_path}/manifest-full.mpd"
}

encode "$1" "$2" "$3"