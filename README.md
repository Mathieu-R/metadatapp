Command-line tool to get metadata from music files and prepare the files for streaming by creating multiple quality versions and necessary playlist using [shaka-packager](https://github.com/shaka-project/shaka-packager).


Useful tool for the streamwave app: https://github.com/Mathieu-R/streamwave    

### Installation 
```shell
python3 -m venv .env 
source .env/bin/activate
pip install -r requirements.txt 

chmod +x lib/encoder.sh
```

### Usage 
```shell
$ python3 index.py --help
Usage: index.py [OPTIONS]

Options:
  -d, --directory TEXT  Absolute path directory where the media files are
                        stored  [required]
  --help                Show this message and exit.
```

### Caveats
- Ensure the input path does not contain any spaces.
- This only works on Mac OS with Apple Silicon CPU. If you are on another configuration, download the correct prebuilt-binary from the shaka-packager repo, rename it to **packager** and place it in the lib **lib**.