import os
import subprocess

import click
import pandas as pd
from mutagen.flac import FLAC
from mutagen.m4a import M4A
from mutagen.mp3 import MP3
from PIL import Image
from slugify import slugify


def extract_metadata(fullpath, filename, extension):
    if extension == ".mp3":
        metadata = MP3(fullpath)
    elif extension == ".flac":
        metadata = FLAC(fullpath)
    elif extension == ".m4a":
        metadata = M4A(fullpath)
    else:
        raise ValueError(
            "Extension not supported. Currently we only support .mp3, .flac and .m4a"
        )

    album_slug = slugify(metadata["album"][0], separator="_")
    filename_slug = slugify(filename, separator="_")

    output_folder = f"{os.getcwd()}/data/{album_slug}"
    if not os.path.exists(output_folder):
        os.makedirs(output_folder, exist_ok=True)

    cover_art = metadata.pictures[0]
    output_cover_art = f"{output_folder}/{album_slug}.jpg"

    with open(f"{output_cover_art}", "wb") as f:
        f.write(cover_art.data)

    img = Image.open(f"{output_cover_art}")
    img = img.resize((500, 500))
    img.save(output_cover_art, "JPEG")

    return {
        "album": metadata["album"][0],
        "artist": metadata["artist"][0],
        "album_artist": metadata["albumartist"][0],
        "title": metadata["title"][0],
        "year": metadata["date"][0].split("-")[0],
        "genre": metadata["genre"][0] if "genre" in metadata else "Unknown",
        "track_number": metadata["tracknumber"][0],
        "duration": metadata.info.length,
        "cover_url": f"{album_slug}/{album_slug}.jpg",
        "manifest_url": f"{album_slug}/{filename_slug}/manifest-full.mpd",
        "playlist_url": f"{album_slug}/{filename_slug}/playlist-all.m3u8",
        "audio128_url": f"{album_slug}/{filename_slug}/{filename_slug}-128.mp4",
        "audio192_url": f"{album_slug}/{filename_slug}/{filename_slug}-192.mp4",
        "audio256_url": f"{album_slug}/{filename_slug}/{filename_slug}-256.mp4",
    }


@click.command()
@click.option(
    "--media_directory",
    "-d",
    type=click.STRING,
    required=True,
    help="Absolute path directory where the media files are stored",
)
def main(media_directory):
    files = os.listdir(media_directory)
    # get the current directory where the script is executed
    cwd = os.getcwd()
    metadatas = []

    for file in files:
        filename, extension = os.path.splitext(file)
        if extension not in (".mp3", ".flac", ".m4a"):
            continue

        fullpath = os.path.join(media_directory, file)
        metadata = extract_metadata(fullpath, filename, extension)
        metadatas.append(metadata)

    album = metadatas[0]["album"]
    album_slug = slugify(album, separator="_")
    output_folder = f"{cwd}/data/{album_slug}"

    # spawn a shell process to encode files and create playlists
    lib_folder = os.path.join(os.path.dirname(__file__), "lib")
    # print(f"DEBUG: lib_folder: {lib_folder}")
    args = [media_directory, cwd, album]
    process = subprocess.run([os.path.join(lib_folder, "encoder.sh")] + args)

    # write metadatas to a csv file
    metadatas_df = pd.DataFrame(metadatas)
    metadatas_df = metadatas_df.sort_values(by=["track_number"])

    metadatas_df.to_csv(
        f"{output_folder}/metadatas.csv", sep=";", decimal=".", index=False
    )


if __name__ == "__main__":
    main()
