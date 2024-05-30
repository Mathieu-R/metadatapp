import os
import subprocess

import click
import pandas as pd
from mutagen.flac import FLAC
from mutagen.m4a import M4A
from mutagen.mp3 import MP3
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
    return {
        "artist": metadata["albumartist"][0],
        "album": metadata["album"][0],
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
    "--directory",
    "-d",
    type=click.STRING,
    required=True,
    help="Absolute path directory where the media files are stored",
)
def main(directory):
    files = os.listdir(directory)
    metadatas = []

    for file in files:
        filename, extension = os.path.splitext(file)
        if extension not in (".mp3", ".flac", ".m4a"):
            continue

        fullpath = os.path.join(directory, file)
        metadata = extract_metadata(fullpath, filename, extension)
        metadatas.append(metadata)

    album = metadatas[0]["album"]
    album_slug = slugify(album, separator="_")

    # spawn a shell process to encode files and create playlists
    args = [directory, album]
    process = subprocess.Popen(
        [os.path.join(os.getcwd(), "lib/encoder.sh")] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    while True:
        output = process.stdout.readline()
        if process.poll() is not None:
            break
        if output:
            print(output.strip())

    rc = process.poll()

    output, error = process.communicate(timeout=500)
    return_code = process.returncode

    if return_code == 0:
        print("Encoder script executed successfully")
        print("Output:")
        print(output.decode())
    else:
        print("Encoder script failed with error code:", return_code)
        print("Error output:")
        print(error.decode())

    # write metadatas to a csv file
    metadatas_df = pd.DataFrame(metadatas)

    output_folder = f"data/{slugify(directory.split('/')[-1])}/{album_slug}"
    if not os.path.exists(output_folder):
        os.makedirs(output_folder, exist_ok=True)

    metadatas_df.to_csv(
        f"{output_folder}/metadatas.csv", sep=";", decimal=".", index=False
    )


if __name__ == "__main__":
    main()
