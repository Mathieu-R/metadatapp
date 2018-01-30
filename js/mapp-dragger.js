const {ipcRenderer} = require('electron');
const fs = require('fs');
const promisify = require('util-promisify');
const mm = require('musicmetadata');
const slugify = require('slugify');
const {ApolloClient} = require('apollo-client');

class Dragger extends HTMLElement {
  static get observedAttributes() {
    return [];
  }

  constructor() {
    super();
    this.getMetadataButton = this.querySelector('.get-metadata');
    this.musics = [];
    this.CDN = 'https://streamwave-music-streaming.s3.amazonaws.com';
    this.onDrop = this.onDrop.bind(this);
    this.getMetadata = this.getMetadata.bind(this);
  }

  connectedCallback() {
    this.addEventListeners();
  }

  onDrop (evt) {
    evt.preventDefault();
    const musics = Array.from(evt.dataTransfer.files);
    this.musics.push(...musics);
  }

  getMetadata (evt) {
    const metadataArrayPromise = this.musics.reduce(async (current, music) => {
      try {
        const readableStream = fs.createReadStream(music.path);
        const metadata = await promisify(mm)(readableStream, {duration: true});
        // in case of single
        metadata.album = metadata.album || metadata.title;
        //await promisify(fs.writeFile)(__dirname + `/artworks/${slugify(metadata.album)}.jpg`, metadata.picture[0].data);
        const c = await current;
        c.push(this.simpleMetadataObject(metadata, music.name.replace(/\..*$/, '')));
        readableStream.close();
        return c;
      } catch (err) {
        console.error(err);
      }
    }, []);

    metadataArrayPromise.then(metadataArray => {
      return promisify(fs.writeFile)(__dirname + '/metadata.json', JSON.stringify(metadataArray, null, 2));
    }).catch(err => console.error(err));
  }

  simpleMetadataObject (metadata, filename) {
    const albumSlug = slugify(metadata.album, {lower: true});
    console.log(albumSlug);
    return {
      artist: metadata.artist[0],
      album: metadata.album,
      title: metadata.title,
      year: metadata.year,
      trackNumber: metadata.track.no,
      genre: metadata.genre[0],
      duration: metadata.duration,
      coverURL: `${albumSlug}/${albumSlug}.jpg`,
      manifestURL: `${albumSlug}/${filename}/manifest-full.mpd`,
      playlistHLSURL: `${albumSlug}/${filename}/playlist-all.m3u8`,
      audio128URL: `${albumSlug}/${filename}/${filename}-128.mp4`,
      audio192URL: `${albumSlug}/${filename}/${filename}-192.mp4`,
      audio256URL: `${albumSlug}/${filename}/${filename}-256.mp4`
    }
  }

  addEventListeners () {
    this.addEventListener('dragover', evt => evt.preventDefault());
    this.addEventListener('drop', this.onDrop);
    this.getMetadataButton.addEventListener('click', this.getMetadata);
  }

  disconnectedCallback() {
    this.removeEventListener('dragover', this.onDrop);
    this.getMetadataButton.removeEventListener('click', this.getMetadata);
  }

  attributesChangedCallback(name, oldValue, newValue) {

  }
}

customElements.define('mapp-dragger', Dragger);
