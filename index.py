import os
import re
import shutil
import subprocess
from io import BytesIO

import click
import pandas as pd
from mutagen.flac import FLAC
from mutagen.m4a import M4A
from mutagen.mp3 import MP3
from PIL import Image
from slugify import slugify


def remove_parentheses(text):
    text = re.sub(r'\([^()]*\)', '', text)
    return re.sub(r'\s+', ' ', text).strip()

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


    album_artist_slug = slugify(metadata["albumartist"][0], separator="_")
    album_slug = slugify(remove_parentheses(metadata["album"][0]), separator="_")
    filename_slug = slugify(filename, separator="_")

    output_folder = f"{os.getcwd()}/data/{album_artist_slug}/{album_slug}"
    if not os.path.exists(output_folder):
        os.makedirs(output_folder, exist_ok=True)

    cover_art = metadata.pictures[0]

    img = Image.open(BytesIO(cover_art.data))
    img_256 = img.resize((512, 512))
    img_256.save(f"{output_folder}/album_cover_512.jpg", "JPEG")

    metadata_dict = {
        "album": metadata["album"][0],
        "artist": metadata["artist"][0],
        "album_artist": metadata["albumartist"][0],
        "title": metadata["title"][0],
        "year": metadata["date"][0].split("-")[0],
        "genre": metadata["genre"][0] if "genre" in metadata else "Unknown",
        "track_number": metadata["tracknumber"][0],
        "duration": metadata.info.length,
        "cover_url": f"{album_artist_slug}/{album_slug}/album_cover_512.jpg",
        "manifest_url": f"{album_artist_slug}/{album_slug}/{filename_slug}/manifest-full.mpd",
        "playlist_url": f"{album_artist_slug}/{album_slug}/{filename_slug}/playlist-all.m3u8",
        "audio128_url": f"{album_artist_slug}/{album_slug}/{filename_slug}/{filename_slug}-128.mp4",
        "audio192_url": f"{album_artist_slug}/{album_slug}/{filename_slug}/{filename_slug}-192.mp4",
        "audio256_url": f"{album_artist_slug}/{album_slug}/{filename_slug}/{filename_slug}-256.mp4",
    }

    return {
        "metadata": metadata_dict,
        "filename_slug": filename_slug,
        "output_folder": output_folder,
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
    metadatas = []

    for file in files:
        filename, extension = os.path.splitext(file)
        if extension not in (".mp3", ".flac", ".m4a"):
            continue

        media_path = os.path.join(media_directory, file)
        result = extract_metadata(media_path, filename, extension)

        media_slug = result["filename_slug"]
        output_folder = result["output_folder"]

        # spawn a shell process to encode files and create playlists
        lib_folder = os.path.join(os.path.dirname(__file__), "lib")

        args = [
            media_path,
            media_slug,
            output_folder
        ]
        subprocess.run([os.path.join(lib_folder, "file_encoder.sh")] + args)

        # add file metadata
        metadatas.append(result["metadata"])

    # write album metadata to a csv file
    metadatas_df = pd.DataFrame(metadatas)
    metadatas_df = metadatas_df.sort_values(by=["track_number"])

    metadatas_df.to_csv(
        f"{output_folder}/metadata.csv", sep=";", decimal=".", index=False
    )

    # remove ffmpgeg temp folder
    shutil.rmtree(f"{output_folder}/src")


if __name__ == "__main__":
    main()